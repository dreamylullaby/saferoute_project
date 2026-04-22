/**
 * Rutas de perfil de usuario.
 * Base: /api/perfil
 * @module perfilRoutes
 */
import express from "express";
import { getPerfil, updatePerfil, toggleNotificaciones } from "../controllers/perfilController.js";
import { authenticate } from "../middlewares/auth.js";

const router = express.Router();

/** GET /api/perfil — Datos del perfil del usuario autenticado */
router.get("/", authenticate, getPerfil);

/** PATCH /api/perfil — Actualizar username y/o foto_url */
router.patch("/", authenticate, updatePerfil);

/** PATCH /api/perfil/notificaciones — Toggle de notificaciones */
router.patch("/notificaciones", authenticate, toggleNotificaciones);

export default router;
