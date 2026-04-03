import bcrypt from "bcrypt";
import admin from "../../infrastructure/firebase/firebase.js";
import db from "../../infrastructure/database/dbScript/db.js";
import { generateToken } from "../../config/jwt.js";

/**
 * Maneja POST /api/auth/register
 * Registra un nuevo usuario local con contraseña hasheada.
 * @param {import('express').Request} req - Body: { username, correo, password }
 * @param {import('express').Response} res - Retorna { user: { id, username, correo, rol } }
 */
export const registerLocal = async (req, res) => {

  try {

    const { username, correo, password } = req.body;

    if (!username || !correo || !password)
      return res.status(400).json({ message: "Todos los campos son obligatorios" });

    const { data: existing } = await db
      .from("usuarios")
      .select("id")
      .eq("correo", correo)
      .single();

    if (existing)
      return res.status(409).json({ message: "El correo ya está registrado" });

    const password_hash = await bcrypt.hash(password, 12);

    const { data: newUser, error } = await db
      .from("usuarios")
      .insert({
        username,
        correo,
        password_hash,
        rol: "usuario",
        auth_provider: "local",
        estado: "activo"
      })
      .select()
      .single();

    if (error) throw error;

    res.status(201).json({
      user: {
        id: newUser.id,
        username: newUser.username,
        correo: newUser.correo,
        rol: newUser.rol
      },
      token: generateToken({ id: newUser.id, rol: newUser.rol })
    });

  } catch (error) {
    res.status(500).json({ message: error.message });
  }

};

/**
 * Maneja POST /api/auth/login
 * Autentica un usuario local verificando correo, estado activo y contraseña.
 * @param {import('express').Request} req - Body: { correo, password }
 * @param {import('express').Response} res - Retorna { user: { id, username, correo, rol } }
 */
export const loginLocal = async (req, res) => {

  try {

    const { correo, password } = req.body;

    const { data, error } = await db
      .from("usuarios")
      .select("*")
      .eq("correo", correo)
      .eq("estado", "activo")
      .single();

    if (error || !data)
      return res.status(404).json({ message: "Usuario no encontrado" });

    const passwordValida = await bcrypt.compare(password, data.password_hash);

    if (!passwordValida)
      return res.status(401).json({ message: "Contraseña incorrecta" });

    res.json({
      user: {
        id: data.id,
        username: data.username,
        correo: data.correo,
        rol: data.rol
      },
      token: generateToken({ id: data.id, rol: data.rol })
    });

  } catch (error) {
    res.status(500).json({ message: error.message });
  }

};

/**
 * Maneja POST /api/auth/admin-login
 * Login exclusivo para administradores. Verifica rol antes de responder.
 * @param {import('express').Request} req - Body: { correo, password }
 * @param {import('express').Response} res
 */
export const loginAdmin = async (req, res) => {

  try {

    const { correo, password } = req.body;

    const { data, error } = await db
      .from("usuarios")
      .select("*")
      .eq("correo", correo)
      .eq("estado", "activo")
      .single();

    if (error || !data)
      return res.status(404).json({ message: "Usuario no encontrado" });

    if (data.rol !== "admin")
      return res.status(403).json({ message: "Acceso denegado" });

    const passwordValida = await bcrypt.compare(password, data.password_hash);

    if (!passwordValida)
      return res.status(401).json({ message: "Contraseña incorrecta" });

    res.json({
      user: {
        id: data.id,
        username: data.username,
        correo: data.correo,
        rol: data.rol
      },
      token: generateToken({ id: data.id, rol: data.rol })
    });

  } catch (error) {
    res.status(500).json({ message: error.message });
  }

};

/**
 * Maneja POST /api/auth/logout
 * El cliente debe eliminar el token localmente.
 * Responde con confirmación para que el frontend limpie su storage.
 * @param {import('express').Request} req
 * @param {import('express').Response} res
 */
export const logoutUser = (req, res) => {
  res.json({ message: "Sesión cerrada correctamente" });
};

/**
 * Maneja POST /api/auth/google
 * Autentica o registra un usuario mediante Google Sign-In.
 * Verifica el idToken con Firebase Admin y crea el usuario si no existe.
 * @param {import('express').Request} req - Body: { idToken }
 * @param {import('express').Response} res - Retorna { user: { id, username, correo, rol } }
 */
export const loginGoogle = async (req, res) => {

  try {

    const { idToken } = req.body;

    const decodedToken = await admin.auth().verifyIdToken(idToken);

    const { uid, email, name, picture } = decodedToken;

    let { data: user } = await db
      .from("usuarios")
      .select("*")
      .eq("google_id", uid)
      .single();

    if (!user) {

      const { data: newUser, error } = await db
        .from("usuarios")
        .insert({
          username: name,
          correo: email,
          google_id: uid,
          foto_url: picture,
          rol: "usuario",
          auth_provider: "google",
          estado: "activo"
        })
        .select()
        .single();

      if (error) throw error;
      user = newUser;

    }

    res.json({
      user: {
        id: user.id,
        username: user.username,
        correo: user.correo,
        rol: user.rol
      },
      token: generateToken({ id: user.id, rol: user.rol })
    });

  } catch (error) {
    res.status(401).json({ message: "Token inválido" });
  }

};

/**
 * Maneja PATCH /api/auth/username
 * Actualiza el apodo de un usuario (usado tras login con Google).
 * @param {import('express').Request} req - Body: { username }, req.user.id del token
 * @param {import('express').Response} res
 */
export const updateUsername = async (req, res) => {

  try {

    const { username } = req.body;
    const userId = req.user.id;

    if (!username || username.trim().length < 3)
      return res.status(400).json({ message: "El apodo debe tener al menos 3 caracteres" });

    const { data: existing } = await db
      .from("usuarios")
      .select("id")
      .eq("username", username.trim())
      .single();

    if (existing)
      return res.status(409).json({ message: "Ese apodo ya está en uso, elige otro" });

    const { data: updated, error } = await db
      .from("usuarios")
      .update({ username: username.trim() })
      .eq("id", userId)
      .select()
      .single();

    if (error) throw error;

    res.json({ user: { id: updated.id, username: updated.username, correo: updated.correo, rol: updated.rol } });

  } catch (error) {
    res.status(500).json({ message: error.message });
  }

};
