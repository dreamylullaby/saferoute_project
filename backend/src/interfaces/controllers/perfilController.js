// src/interfaces/controllers/perfilController.js

import bcrypt from "bcrypt";
import db from "../../infrastructure/database/dbScript/db.js";

/**
 * PUT /api/perfil
 * Actualiza username y/o foto_url del usuario autenticado.
 * Body: { username?, foto_url? }
 */
export const actualizarPerfil = async (req, res) => {
  try {
    const { username, foto_url } = req.body;
    const userId = req.user.id;

    if (!username && foto_url === undefined)
      return res.status(400).json({ message: "Debes enviar al menos un campo: username o foto_url" });

    const campos = {};

    if (username !== undefined) {
      if (typeof username !== 'string' || username.trim().length < 3)
        return res.status(400).json({ message: "El apodo debe tener al menos 3 caracteres" });

      // Verificar que no esté en uso por otro usuario
      const { data: existing } = await db
        .from("usuarios")
        .select("id")
        .eq("username", username.trim())
        .neq("id", userId)
        .single();

      if (existing)
        return res.status(409).json({ message: "Ese apodo ya está en uso, elige otro" });

      campos.username = username.trim();
    }

    if (foto_url !== undefined) {
      if (foto_url !== null && typeof foto_url !== 'string')
        return res.status(400).json({ message: "foto_url debe ser una URL válida o null" });
      campos.foto_url = foto_url;
    }

    const { data: updated, error } = await db
      .from("usuarios")
      .update(campos)
      .eq("id", userId)
      .select("id, username, correo, foto_url, rol")
      .single();

    if (error) throw error;

    return res.status(200).json({ success: true, data: updated });
  } catch (error) {
    return res.status(500).json({ message: error.message });
  }
};

/**
 * PUT /api/perfil/password
 * Cambia la contraseña del usuario autenticado.
 * Solo para usuarios con auth_provider = 'local'.
 * Body: { passwordActual, nuevaPassword }
 */
export const cambiarPassword = async (req, res) => {
  try {
    const { passwordActual, nuevaPassword } = req.body;
    const userId = req.user.id;

    if (!passwordActual || !nuevaPassword)
      return res.status(400).json({ message: "passwordActual y nuevaPassword son obligatorios" });

    if (nuevaPassword.length < 8)
      return res.status(400).json({ message: "La nueva contraseña debe tener al menos 8 caracteres" });

    if (passwordActual === nuevaPassword)
      return res.status(400).json({ message: "La nueva contraseña debe ser diferente a la actual" });

    const { data: usuario, error: fetchError } = await db
      .from("usuarios")
      .select("id, password_hash, auth_provider")
      .eq("id", userId)
      .single();

    if (fetchError || !usuario)
      return res.status(404).json({ message: "Usuario no encontrado" });

    if (usuario.auth_provider !== 'local')
      return res.status(400).json({ message: "Los usuarios con Google no pueden cambiar contraseña desde aquí" });

    const passwordValida = await bcrypt.compare(passwordActual, usuario.password_hash);
    if (!passwordValida)
      return res.status(401).json({ message: "La contraseña actual es incorrecta" });

    const password_hash = await bcrypt.hash(nuevaPassword, 12);

    const { error: updateError } = await db
      .from("usuarios")
      .update({ password_hash })
      .eq("id", userId);

    if (updateError) throw updateError;

    return res.status(200).json({ success: true, message: "Contraseña actualizada correctamente" });
  } catch (error) {
    return res.status(500).json({ message: error.message });
  }
};

/**
 * PUT /api/perfil/notificaciones
 * Activa/desactiva alertas y configura el radio.
 * Body: { activo, radio_metros? }
 */
export const actualizarNotificaciones = async (req, res) => {
  try {
    const { activo, radio_metros } = req.body;
    const userId = req.user.id;

    if (activo === undefined)
      return res.status(400).json({ message: "El campo 'activo' es obligatorio" });

    if (typeof activo !== 'boolean')
      return res.status(400).json({ message: "'activo' debe ser un valor booleano" });

    if (radio_metros !== undefined) {
      if (typeof radio_metros !== 'number' || !Number.isInteger(radio_metros))
        return res.status(400).json({ message: "radio_metros debe ser un número entero" });
      if (radio_metros < 100 || radio_metros > 5000)
        return res.status(400).json({ message: "radio_metros debe estar entre 100 y 5000 metros" });
    }

    const { data, error } = await db
      .from("configuracion_alertas")
      .upsert(
        {
          usuario_id:          userId,
          activo,
          radio_metros:        radio_metros ?? 500,
          fecha_actualizacion: new Date().toISOString(),
        },
        { onConflict: "usuario_id" }
      )
      .select()
      .single();

    if (error) throw error;

    return res.status(200).json({ success: true, data });
  } catch (error) {
    return res.status(500).json({ message: error.message });
  }
};
