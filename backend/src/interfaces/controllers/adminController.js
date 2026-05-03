// src/interfaces/controllers/adminController.js

import db from "../../infrastructure/database/dbScript/db.js";

/**
 * @class AdminController (funciones sueltas)
 * Gestión de usuarios desde el panel de administración.
 * Todas las rutas requieren authenticate + requireAdmin.
 */

/**
 * GET /api/admin/usuarios
 * Lista usuarios con paginación y filtros opcionales.
 * Query params: page, limit, estado, rol, q (búsqueda por username/correo)
 */
export const listarUsuarios = async (req, res) => {
  try {
    const { page = 1, limit = 10, estado, rol, q } = req.query;
    const from = (Number(page) - 1) * Number(limit);
    const to   = from + Number(limit) - 1;

    let query = db
      .from("usuarios")
      .select("id, username, correo, rol, auth_provider, estado, fecha_creacion, foto_url", { count: "exact" })
      .order("fecha_creacion", { ascending: false })
      .range(from, to);

    if (estado) query = query.eq("estado", estado);
    if (rol)    query = query.eq("rol", rol);
    if (q)      query = query.or(`username.ilike.%${q}%,correo.ilike.%${q}%`);

    const { data, error, count } = await query;
    if (error) throw error;

    return res.status(200).json({
      success: true,
      data,
      total:      count,
      page:       Number(page),
      totalPages: Math.ceil(count / Number(limit)),
    });
  } catch (error) {
    return res.status(500).json({ success: false, message: error.message });
  }
};

/**
 * PATCH /api/admin/usuarios/:id/bloquear
 * Cambia el estado del usuario a 'bloqueado'.
 * No se puede bloquear a otro administrador.
 */
export const bloquearUsuario = async (req, res) => {
  try {
    const { id } = req.params;
    const adminId = req.user.id;

    if (id === adminId)
      return res.status(400).json({ success: false, message: "No puedes bloquearte a ti mismo" });

    const { data: usuario, error: fetchError } = await db
      .from("usuarios")
      .select("id, rol, estado, username")
      .eq("id", id)
      .single();

    if (fetchError || !usuario)
      return res.status(404).json({ success: false, message: "Usuario no encontrado" });

    if (usuario.rol === "admin")
      return res.status(403).json({ success: false, message: "No se puede bloquear a un administrador" });

    if (usuario.estado === "bloqueado")
      return res.status(400).json({ success: false, message: "El usuario ya está bloqueado" });

    const { error } = await db
      .from("usuarios")
      .update({ estado: "bloqueado" })
      .eq("id", id);

    if (error) throw error;

    // Registrar auditoría
    await db.from("auditoria_usuarios").insert({
      admin_id:   adminId,
      usuario_id: id,
      accion:     "bloquear",
      detalle:    `Usuario ${usuario.username} bloqueado`,
    });

    return res.status(200).json({ success: true, message: "Usuario bloqueado correctamente" });
  } catch (error) {
    return res.status(500).json({ success: false, message: error.message });
  }
};

/**
 * PATCH /api/admin/usuarios/:id/ocultar
 * Cambia el estado del usuario a 'oculto'.
 */
export const ocultarUsuario = async (req, res) => {
  try {
    const { id } = req.params;
    const adminId = req.user.id;

    if (id === adminId)
      return res.status(400).json({ success: false, message: "No puedes ocultarte a ti mismo" });

    const { data: usuario, error: fetchError } = await db
      .from("usuarios")
      .select("id, rol, estado, username")
      .eq("id", id)
      .single();

    if (fetchError || !usuario)
      return res.status(404).json({ success: false, message: "Usuario no encontrado" });

    if (usuario.rol === "admin")
      return res.status(403).json({ success: false, message: "No se puede ocultar a un administrador" });

    if (usuario.estado === "oculto")
      return res.status(400).json({ success: false, message: "El usuario ya está oculto" });

    const { error } = await db
      .from("usuarios")
      .update({ estado: "oculto" })
      .eq("id", id);

    if (error) throw error;

    await db.from("auditoria_usuarios").insert({
      admin_id:   adminId,
      usuario_id: id,
      accion:     "ver",
      detalle:    `Usuario ${usuario.username} ocultado`,
    });

    return res.status(200).json({ success: true, message: "Usuario ocultado correctamente" });
  } catch (error) {
    return res.status(500).json({ success: false, message: error.message });
  }
};

/**
 * PATCH /api/admin/usuarios/:id/reactivar
 * Cambia el estado del usuario a 'activo'.
 */
export const reactivarUsuario = async (req, res) => {
  try {
    const { id } = req.params;
    const adminId = req.user.id;

    const { data: usuario, error: fetchError } = await db
      .from("usuarios")
      .select("id, rol, estado, username")
      .eq("id", id)
      .single();

    if (fetchError || !usuario)
      return res.status(404).json({ success: false, message: "Usuario no encontrado" });

    if (usuario.estado === "activo")
      return res.status(400).json({ success: false, message: "El usuario ya está activo" });

    const { error } = await db
      .from("usuarios")
      .update({ estado: "activo" })
      .eq("id", id);

    if (error) throw error;

    await db.from("auditoria_usuarios").insert({
      admin_id:   adminId,
      usuario_id: id,
      accion:     "reactivar",
      detalle:    `Usuario ${usuario.username} reactivado`,
    });

    return res.status(200).json({ success: true, message: "Usuario reactivado correctamente" });
  } catch (error) {
    return res.status(500).json({ success: false, message: error.message });
  }
};

/**
 * PATCH /api/admin/usuarios/:id/eliminar
 * Cambia el estado del usuario a 'eliminado'.
 */
export const eliminarUsuario = async (req, res) => {
  try {
    const { id } = req.params;
    const adminId = req.user.id;

    if (id === adminId)
      return res.status(400).json({ success: false, message: "No puedes eliminarte a ti mismo" });

    const { data: usuario, error: fetchError } = await db
      .from("usuarios")
      .select("id, rol, estado, username")
      .eq("id", id)
      .single();

    if (fetchError || !usuario)
      return res.status(404).json({ success: false, message: "Usuario no encontrado" });

    if (usuario.rol === "admin")
      return res.status(403).json({ success: false, message: "No se puede eliminar a un administrador" });

    if (usuario.estado === "eliminado")
      return res.status(400).json({ success: false, message: "El usuario ya está eliminado" });

    const { error } = await db
      .from("usuarios")
      .update({ estado: "eliminado" })
      .eq("id", id);

    if (error) throw error;

    await db.from("auditoria_usuarios").insert({
      admin_id:   adminId,
      usuario_id: id,
      accion:     "eliminar",
      detalle:    `Usuario ${usuario.username} eliminado`,
    });

    return res.status(200).json({ success: true, message: "Usuario eliminado correctamente" });
  } catch (error) {
    return res.status(500).json({ success: false, message: error.message });
  }
};

/**
 * PATCH /api/admin/reportes/:id/estado
 * Cambia el estado de un reporte (activo, oculto, eliminado).
 * Body: { estado, motivo? }
 * Registra en auditoria_reportes con estado anterior y nuevo.
 */
export const cambiarEstadoReporte = async (req, res) => {
  try {
    const { id }     = req.params;
    const { estado, motivo } = req.body;
    const adminId    = req.user.id;

    const estadosPermitidos = ['activo', 'oculto', 'eliminado'];
    if (!estado || !estadosPermitidos.includes(estado))
      return res.status(400).json({
        success: false,
        message: `Estado inválido. Valores permitidos: ${estadosPermitidos.join(', ')}`,
      });

    // Buscar reporte
    const { data: reporte, error: fetchError } = await db
      .from("reportes")
      .select("id, estado, tipo_hurto, barrio_ingresado")
      .eq("id", id)
      .single();

    if (fetchError || !reporte)
      return res.status(404).json({ success: false, message: "Reporte no encontrado" });

    if (reporte.estado === estado)
      return res.status(400).json({
        success: false,
        message: `El reporte ya tiene el estado '${estado}'`,
      });

    const estadoAnterior = reporte.estado;

    // Actualizar estado
    const { error: updateError } = await db
      .from("reportes")
      .update({
        estado,
        actualizado_por:     adminId,
        fecha_actualizacion: new Date().toISOString(),
      })
      .eq("id", id);

    if (updateError) throw updateError;

    // Mapear acción para auditoría
    const accionMap = {
      oculto:    'ocultar',
      eliminado: 'eliminar',
      activo:    'restaurar',
    };

    await db.from("auditoria_reportes").insert({
      admin_id:   adminId,
      reporte_id: id,
      accion:     accionMap[estado],
      detalle:    motivo
        ? `Estado: ${estadoAnterior} → ${estado}. Motivo: ${motivo}`
        : `Estado: ${estadoAnterior} → ${estado}`,
    });

    return res.status(200).json({
      success: true,
      message: `Estado del reporte actualizado a '${estado}'`,
      data: { id, estadoAnterior, estadoNuevo: estado },
    });
  } catch (error) {
    return res.status(500).json({ success: false, message: error.message });
  }
};
