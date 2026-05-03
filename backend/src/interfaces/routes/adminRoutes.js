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
  cambiarEstadoReporte,
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

/** PATCH /api/admin/reportes/:id/estado — Cambia el estado de un reporte */
router.patch("/reportes/:id/estado", cambiarEstadoReporte);

export default router;
