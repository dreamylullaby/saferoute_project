// src/interfaces/routes/adminRoutes.js

/**
 * Rutas de administración de usuarios.
 * Base: /api/admin
 * Todas requieren authenticate + requireAdmin.
 */
import express from "express";
import { authenticate, requireAdmin } from "../middlewares/auth.js";
import {
  listarUsuarios,
  bloquearUsuario,
  ocultarUsuario,
  reactivarUsuario,
  eliminarUsuario,
  hardDeleteUsuario,
  hardDeleteReporte,
  cambiarEstadoReporte,
  editarTipoHurtoReporte,
  listarSolicitudesEliminacion,
  detalleSolicitudEliminacion,
  aprobarSolicitud,
  rechazarSolicitud,
  exportarReportes,
} from "../controllers/adminController.js";

const router = express.Router();

// Aplicar autenticación y rol admin a todas las rutas
router.use(authenticate, requireAdmin);

/** GET  /api/admin/usuarios — Lista usuarios con paginación y filtros */
router.get("/usuarios",                listarUsuarios);

/** PATCH /api/admin/usuarios/:id/bloquear — Bloquea un usuario */
router.patch("/usuarios/:id/bloquear", bloquearUsuario);

/** PATCH /api/admin/usuarios/:id/ocultar — Oculta un usuario */
router.patch("/usuarios/:id/ocultar",  ocultarUsuario);

/** PATCH /api/admin/usuarios/:id/reactivar — Reactiva un usuario */
router.patch("/usuarios/:id/reactivar", reactivarUsuario);

/** PATCH /api/admin/usuarios/:id/eliminar — Elimina lógicamente un usuario */
router.patch("/usuarios/:id/eliminar", eliminarUsuario);

/** DELETE /api/admin/usuarios/:id/permanente — Hard delete de usuario */
router.delete("/usuarios/:id/permanente", hardDeleteUsuario);

/** PATCH /api/admin/reportes/:id/estado — Cambia el estado de un reporte */
router.patch("/reportes/:id/estado", cambiarEstadoReporte);

/** PATCH /api/admin/reportes/:id/tipo — Edita el tipo de hurto de un reporte */
router.patch("/reportes/:id/tipo", editarTipoHurtoReporte);

/** DELETE /api/admin/reportes/:id/permanente — Hard delete de reporte */
router.delete("/reportes/:id/permanente", hardDeleteReporte);

/** GET  /api/admin/solicitudes-eliminacion — Lista solicitudes (filtro por estado) */
router.get("/solicitudes-eliminacion",              listarSolicitudesEliminacion);

/** GET  /api/admin/solicitudes-eliminacion/:id — Detalle de una solicitud */
router.get("/solicitudes-eliminacion/:id",          detalleSolicitudEliminacion);

/** POST /api/admin/solicitudes-eliminacion/:id/aprobar — Aprueba y elimina el reporte */
router.post("/solicitudes-eliminacion/:id/aprobar", aprobarSolicitud);

/** POST /api/admin/solicitudes-eliminacion/:id/rechazar — Rechaza la solicitud */
router.post("/solicitudes-eliminacion/:id/rechazar", rechazarSolicitud);

/** GET /api/admin/reportes/export — Exporta reportes en CSV o Excel */
router.get("/reportes/export", exportarReportes);

export default router;
