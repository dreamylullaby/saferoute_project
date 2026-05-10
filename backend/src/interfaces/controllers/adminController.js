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
 * DELETE /api/admin/usuarios/:id/permanente
 * Elimina permanentemente un usuario de la BD (hard delete).
 * Solo se permite si el usuario ya tiene estado 'eliminado'.
 */
export const hardDeleteUsuario = async (req, res) => {
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
      return res.status(403).json({ success: false, message: "No se puede eliminar permanentemente a un administrador" });

    if (usuario.estado !== "eliminado")
      return res.status(400).json({ success: false, message: "Solo se pueden eliminar permanentemente usuarios con estado 'eliminado'" });

    const { error } = await db
      .from("usuarios")
      .delete()
      .eq("id", id);

    if (error) throw error;

    await db.from("auditoria_usuarios").insert({
      admin_id:   adminId,
      usuario_id: id,
      accion:     "eliminar",
      detalle:    `Usuario ${usuario.username} eliminado permanentemente (hard delete)`,
    }).catch(() => {});

    return res.status(200).json({ success: true, message: "Usuario eliminado permanentemente" });
  } catch (error) {
    return res.status(500).json({ success: false, message: error.message });
  }
};

/**
 * DELETE /api/admin/reportes/:id/permanente
 * Elimina permanentemente un reporte de la BD (hard delete).
 * Solo se permite si el reporte ya tiene estado 'eliminado'.
 */
export const hardDeleteReporte = async (req, res) => {
  try {
    const { id } = req.params;
    const adminId = req.user.id;

    const { data: reporte, error: fetchError } = await db
      .from("reportes")
      .select("id, estado, tipo_hurto, barrio_ingresado")
      .eq("id", id)
      .single();

    if (fetchError || !reporte)
      return res.status(404).json({ success: false, message: "Reporte no encontrado" });

    if (reporte.estado !== "eliminado")
      return res.status(400).json({ success: false, message: "Solo se pueden eliminar permanentemente reportes con estado 'eliminado'" });

    const { error } = await db
      .from("reportes")
      .delete()
      .eq("id", id);

    if (error) throw error;

    await db.from("auditoria_reportes").insert({
      admin_id:     adminId,
      reporte_id:   id,
      accion:       "eliminar_permanente",
      estado_anterior: "eliminado",
      estado_nuevo:    null,
      detalle:      `Reporte ${reporte.tipo_hurto} en ${reporte.barrio_ingresado} eliminado permanentemente`,
    }).catch(() => {});

    return res.status(200).json({ success: true, message: "Reporte eliminado permanentemente" });
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

/**
 * PATCH /api/admin/reportes/:id/tipo
 * Edita el tipo_hurto de un reporte.
 * Requiere que el reporte tenga descripcion no vacía.
 * Body: { tipo_hurto }
 */
export const editarTipoHurtoReporte = async (req, res) => {
  try {
    const { id }        = req.params;
    const { tipo_hurto } = req.body;
    const adminId       = req.user.id;

    const tiposPermitidos = ['atraco', 'raponazo', 'cosquilleo', 'fleteo'];

    if (!tipo_hurto || !tipo_hurto.trim())
      return res.status(400).json({ success: false, message: "tipo_hurto es obligatorio" });

    if (!tiposPermitidos.includes(tipo_hurto))
      return res.status(400).json({
        success: false,
        message: `tipo_hurto inválido. Valores permitidos: ${tiposPermitidos.join(', ')}`,
      });

    // Buscar reporte
    const { data: reporte, error: fetchError } = await db
      .from("reportes")
      .select("id, tipo_hurto, descripcion")
      .eq("id", id)
      .single();

    if (fetchError || !reporte)
      return res.status(404).json({ success: false, message: "Reporte no encontrado" });

    // Validar que tenga descripción no vacía
    if (!reporte.descripcion || reporte.descripcion.trim().length === 0)
      return res.status(400).json({
        success: false,
        message: "El reporte debe tener una descripción antes de poder editar el tipo de hurto",
      });

    if (reporte.tipo_hurto === tipo_hurto)
      return res.status(400).json({
        success: false,
        message: `El reporte ya tiene el tipo '${tipo_hurto}'`,
      });

    const tipoAnterior = reporte.tipo_hurto;

    // Actualizar tipo_hurto
    const { error: updateError } = await db
      .from("reportes")
      .update({
        tipo_hurto,
        actualizado_por:     adminId,
        fecha_actualizacion: new Date().toISOString(),
      })
      .eq("id", id);

    if (updateError) throw updateError;

    // Registrar en auditoría
    await db.from("auditoria_edicion_reportes").insert({
      admin_id:           adminId,
      reporte_id:         id,
      campos_modificados: ['tipo_hurto'],
      valores_anteriores: { tipo_hurto: tipoAnterior },
    });

    return res.status(200).json({
      success: true,
      message: "Tipo de hurto actualizado correctamente",
      data: { id, tipoAnterior, tipoNuevo: tipo_hurto },
    });
  } catch (error) {
    return res.status(500).json({ success: false, message: error.message });
  }
};

/**
 * GET /api/admin/solicitudes-eliminacion
 * Lista solicitudes con filtro opcional por estado_solicitud (default: pendiente).
 * Query params: estado (pendiente | aprobada | rechazada)
 */
export const listarSolicitudesEliminacion = async (req, res) => {
  try {
    const { estado = 'pendiente' } = req.query;

    const estadosValidos = ['pendiente', 'aprobada', 'rechazada'];
    if (!estadosValidos.includes(estado))
      return res.status(400).json({ success: false, message: `estado inválido. Valores: ${estadosValidos.join(', ')}` });

    const { data, error } = await db
      .from('solicitudes_eliminacion')
      .select(`
        id, estado_solicitud, motivo, fecha_solicitud, fecha_resolucion,
        reportes(id, tipo_hurto, barrio_ingresado, estado, fecha_incidente),
        usuarios!solicitudes_eliminacion_usuario_id_fkey(id, username, correo)
      `)
      .eq('estado_solicitud', estado)
      .order('fecha_solicitud', { ascending: false });

    if (error) throw error;

    return res.status(200).json({ success: true, data });
  } catch (error) {
    return res.status(500).json({ success: false, message: error.message });
  }
};

/**
 * GET /api/admin/solicitudes-eliminacion/:id
 * Detalle completo de una solicitud.
 */
export const detalleSolicitudEliminacion = async (req, res) => {
  try {
    const { id } = req.params;

    const { data, error } = await db
      .from('solicitudes_eliminacion')
      .select(`
        *,
        reportes(id, tipo_hurto, barrio_ingresado, estado, fecha_incidente, descripcion, latitud, longitud),
        usuarios!solicitudes_eliminacion_usuario_id_fkey(id, username, correo, fecha_creacion)
      `)
      .eq('id', id)
      .single();

    if (error || !data)
      return res.status(404).json({ success: false, message: 'Solicitud no encontrada' });

    return res.status(200).json({ success: true, data });
  } catch (error) {
    return res.status(500).json({ success: false, message: error.message });
  }
};

/**
 * POST /api/admin/solicitudes-eliminacion/:id/aprobar
 * Aprueba la solicitud: cambia estado del reporte a 'eliminado'.
 */
export const aprobarSolicitud = async (req, res) => {
  try {
    const { id }    = req.params;
    const adminId   = req.user.id;

    const { data: solicitud, error: fetchError } = await db
      .from('solicitudes_eliminacion')
      .select('*, reportes(id, estado)')
      .eq('id', id)
      .single();

    if (fetchError || !solicitud)
      return res.status(404).json({ success: false, message: 'Solicitud no encontrada' });

    if (solicitud.estado_solicitud !== 'pendiente')
      return res.status(400).json({ success: false, message: `La solicitud ya fue ${solicitud.estado_solicitud}` });

    if (solicitud.reportes?.estado === 'eliminado')
      return res.status(400).json({ success: false, message: 'El reporte ya está eliminado' });

    // Eliminar el reporte
    await db.from('reportes').update({
      estado:              'eliminado',
      actualizado_por:     adminId,
      fecha_actualizacion: new Date().toISOString(),
    }).eq('id', solicitud.reporte_id);

    // Resolver la solicitud
    const { data: updated, error: updateError } = await db
      .from('solicitudes_eliminacion')
      .update({
        estado_solicitud:  'aprobada',
        admin_id:          adminId,
        fecha_resolucion:  new Date().toISOString(),
      })
      .eq('id', id)
      .select()
      .single();

    if (updateError) throw updateError;

    return res.status(200).json({ success: true, message: 'Solicitud aprobada. Reporte eliminado.', data: updated });
  } catch (error) {
    return res.status(500).json({ success: false, message: error.message });
  }
};

/**
 * POST /api/admin/solicitudes-eliminacion/:id/rechazar
 * Rechaza la solicitud sin modificar el reporte.
 */
export const rechazarSolicitud = async (req, res) => {
  try {
    const { id }  = req.params;
    const adminId = req.user.id;

    const { data: solicitud, error: fetchError } = await db
      .from('solicitudes_eliminacion')
      .select('id, estado_solicitud')
      .eq('id', id)
      .single();

    if (fetchError || !solicitud)
      return res.status(404).json({ success: false, message: 'Solicitud no encontrada' });

    if (solicitud.estado_solicitud !== 'pendiente')
      return res.status(400).json({ success: false, message: `La solicitud ya fue ${solicitud.estado_solicitud}` });

    const { data: updated, error: updateError } = await db
      .from('solicitudes_eliminacion')
      .update({
        estado_solicitud: 'rechazada',
        admin_id:         adminId,
        fecha_resolucion: new Date().toISOString(),
      })
      .eq('id', id)
      .select()
      .single();

    if (updateError) throw updateError;

    return res.status(200).json({ success: true, message: 'Solicitud rechazada.', data: updated });
  } catch (error) {
    return res.status(500).json({ success: false, message: error.message });
  }
};

/**
 * GET /api/admin/reportes/export
 * Exporta reportes filtrados en formato CSV o Excel.
 * Query params: fechaDesde, fechaHasta, zona (comuna), estado, formato (csv|excel)
 * Límite máximo: 5000 registros.
 */
export const exportarReportes = async (req, res) => {
  try {
    const {
      fechaDesde, fechaHasta,
      zona, estado,
      formato = 'excel',
    } = req.query;

    const LIMITE = 5000;

    if (!['csv', 'excel'].includes(formato))
      return res.status(400).json({ success: false, message: "formato debe ser 'csv' o 'excel'" });

    // Consultar vista de exportación con filtros
    let query = db
      .from('vw_export_reportes_admin')
      .select('*')
      .limit(LIMITE + 1); // +1 para detectar si excede el límite

    if (fechaDesde) query = query.gte('fecha_incidente', fechaDesde);
    if (fechaHasta) query = query.lte('fecha_incidente', fechaHasta);
    if (estado)     query = query.eq('estado', estado);
    if (zona)       query = query.eq('comuna', Number(zona));

    const { data, error } = await query;
    if (error) throw error;

    if (data.length > LIMITE)
      return res.status(400).json({
        success: false,
        message: `La consulta excede el límite de ${LIMITE} registros. Aplica más filtros para reducir los resultados.`,
      });

    if (data.length === 0)
      return res.status(200).json({ success: true, message: 'No hay registros para exportar con los filtros aplicados.' });

    const columnas = [
      'reporte_id', 'fecha_incidente', 'franja_horaria', 'tipo_hurto',
      'tipo_reportante', 'objeto_hurtado', 'numero_agresores', 'descripcion',
      'direccion', 'barrio_ingresado', 'barrio_normalizado', 'comuna',
      'latitud', 'longitud', 'estado', 'fecha_creacion',
    ];

    if (formato === 'csv') {
      const header = columnas.join(',');
      const rows   = data.map(r =>
        columnas.map(c => {
          const val = r[c] ?? '';
          return typeof val === 'string' && val.includes(',') ? `"${val}"` : val;
        }).join(',')
      );
      const csv = [header, ...rows].join('\n');

      res.setHeader('Content-Type', 'text/csv; charset=utf-8');
      res.setHeader('Content-Disposition', `attachment; filename="reportes_${Date.now()}.csv"`);
      return res.send('\uFEFF' + csv); // BOM para Excel en Windows
    }

    // Excel con exceljs
    const ExcelJS = (await import('exceljs')).default;
    const workbook  = new ExcelJS.Workbook();
    const worksheet = workbook.addWorksheet('Reportes SafeRoute');

    worksheet.columns = columnas.map(c => ({
      header: c.replace(/_/g, ' ').toUpperCase(),
      key:    c,
      width:  20,
    }));

    // Estilo de cabecera
    worksheet.getRow(1).eachCell(cell => {
      cell.font      = { bold: true, color: { argb: 'FFFFFFFF' } };
      cell.fill      = { type: 'pattern', pattern: 'solid', fgColor: { argb: 'FF2563EB' } };
      cell.alignment = { horizontal: 'center' };
    });

    data.forEach(r => worksheet.addRow(columnas.reduce((acc, c) => ({ ...acc, [c]: r[c] ?? '' }), {})));

    res.setHeader('Content-Type', 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet');
    res.setHeader('Content-Disposition', `attachment; filename="reportes_${Date.now()}.xlsx"`);

    await workbook.xlsx.write(res);
    return res.end();

  } catch (error) {
    return res.status(500).json({ success: false, message: error.message });
  }
};
