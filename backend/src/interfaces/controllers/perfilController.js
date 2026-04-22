/**
 * @module perfilController
 * @description Controlador HTTP para gestión de perfil de usuario.
 * Maneja consulta, actualización de datos y toggle de notificaciones.
 */

import db from "../../infrastructure/database/dbScript/db.js";

/**
 * GET /api/perfil
 * Retorna los datos del perfil del usuario autenticado.
 */
export const getPerfil = async (req, res) => {
  try {
    const userId = req.user.id;

    const { data: usuario, error } = await db
      .from("usuarios")
      .select("id, correo, username, foto_url, fecha_creacion, rol, auth_provider")
      .eq("id", userId)
      .single();

    if (error || !usuario)
      return res.status(404).json({ success: false, message: "Usuario no encontrado" });

    // Obtener estado de notificaciones
    const { data: config } = await db
      .from("configuracion_alertas")
      .select("activo, radio_metros")
      .eq("usuario_id", userId)
      .single();

    return res.json({
      success: true,
      data: {
        ...usuario,
        notificaciones_activas: config?.activo ?? true,
        radio_alertas: config?.radio_metros ?? 500,
      }
    });
  } catch (error) {
    return res.status(500).json({ success: false, message: error.message });
  }
};

/**
 * PATCH /api/perfil
 * Actualiza username y/o foto_url del usuario autenticado.
 */
export const updatePerfil = async (req, res) => {
  try {
    const userId = req.user.id;
    const { username, foto_url } = req.body;

    const updates = {};

    if (username !== undefined) {
      const trimmed = username.trim();
      if (trimmed.length < 3)
        return res.status(400).json({ success: false, message: "El apodo debe tener al menos 3 caracteres" });

      // Verificar duplicado (excluyendo al propio usuario)
      const { data: existing } = await db
        .from("usuarios")
        .select("id")
        .eq("username", trimmed)
        .neq("id", userId)
        .single();

      if (existing)
        return res.status(409).json({ success: false, message: "Ese apodo ya está en uso" });

      updates.username = trimmed;
    }

    if (foto_url !== undefined) {
      updates.foto_url = foto_url.trim() || null;
    }

    if (Object.keys(updates).length === 0)
      return res.status(400).json({ success: false, message: "No hay campos para actualizar" });

    const { data: updated, error } = await db
      .from("usuarios")
      .update(updates)
      .eq("id", userId)
      .select("id, correo, username, foto_url, rol")
      .single();

    if (error) throw error;

    return res.json({ success: true, data: updated });
  } catch (error) {
    return res.status(500).json({ success: false, message: error.message });
  }
};

/**
 * PATCH /api/perfil/notificaciones
 * Activa o desactiva las notificaciones del usuario autenticado.
 */
export const toggleNotificaciones = async (req, res) => {
  try {
    const userId = req.user.id;
    const { activo } = req.body;

    if (typeof activo !== "boolean")
      return res.status(400).json({ success: false, message: "El campo 'activo' debe ser true o false" });

    // Upsert: crear config si no existe, actualizar si existe
    const { data: existing } = await db
      .from("configuracion_alertas")
      .select("id")
      .eq("usuario_id", userId)
      .single();

    if (existing) {
      const { error } = await db
        .from("configuracion_alertas")
        .update({ activo, fecha_actualizacion: new Date().toISOString() })
        .eq("usuario_id", userId);
      if (error) throw error;
    } else {
      const { error } = await db
        .from("configuracion_alertas")
        .insert({ usuario_id: userId, activo });
      if (error) throw error;
    }

    return res.json({ success: true, data: { activo } });
  } catch (error) {
    return res.status(500).json({ success: false, message: error.message });
  }
};
