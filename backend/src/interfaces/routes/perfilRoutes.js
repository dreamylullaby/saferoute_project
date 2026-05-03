// src/interfaces/routes/perfilRoutes.js

/**
 * Rutas de gestión de perfil del usuario autenticado.
 * Base: /api/perfil
 */
import express from "express";
import { authenticate } from "../middlewares/auth.js";
import {
  actualizarPerfil,
  cambiarPassword,
  actualizarNotificaciones,
  eliminarCuenta,
} from "../controllers/perfilController.js";

const router = express.Router();

/** PUT /api/perfil — Actualiza username y/o foto_url */
router.put("/", authenticate, actualizarPerfil);

/** PUT /api/perfil/password — Cambia la contraseña (solo usuarios locales) */
router.put("/password", authenticate, cambiarPassword);

/** PUT /api/perfil/notificaciones — Activa/desactiva alertas y configura radio */
router.put("/notificaciones", authenticate, actualizarNotificaciones);

/** DELETE /api/perfil — Elimina la cuenta del usuario autenticado */
router.delete("/", authenticate, eliminarCuenta);

export default router;
