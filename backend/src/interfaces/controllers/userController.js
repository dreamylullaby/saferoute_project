import bcrypt from "bcrypt";
import admin from "../../infrastructure/firebase/firebase.js";
import db from "../../infrastructure/database/dbScript/db.js";

// LOGIN LOCAL
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
      }
    });

  } catch (error) {

    res.status(500).json({ message: error.message });

  }

};

// LOGIN GOOGLE
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
      }
    });

  } catch (error) {

    res.status(401).json({ message: "Token inválido" });

  }

};
