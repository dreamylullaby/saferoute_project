// src/interfaces/routes/perfilRoutes.js

/**
 * Rutas de gestión de perfil del usuario autenticado.
 * Base: /api/perfil
 */
import express from "express";
import { authenticate } from "../middlewares/auth.js";
import {
  getPerfil,
  actualizarPerfil,
  cambiarPassword,
  actualizarNotificaciones,
  eliminarCuenta,
} from "../controllers/perfilController.js";
import db from "../../infrastructure/database/dbScript/db.js";

const router = express.Router();

/** GET /api/perfil — Obtiene datos del perfil del usuario autenticado */
router.get("/", authenticate, getPerfil);

/** PUT /api/perfil — Actualiza username y/o foto_url */
router.put("/", authenticate, actualizarPerfil);

/** PUT /api/perfil/password — Cambia la contraseña (solo usuarios locales) */
router.put("/password", authenticate, cambiarPassword);

/** PUT /api/perfil/notificaciones — Activa/desactiva alertas y configura radio */
router.put("/notificaciones", authenticate, actualizarNotificaciones);

/** GET /api/perfil/mensajes — Lista notificaciones del usuario */
router.get("/mensajes", authenticate, async (req, res) => {
  try {
    const { data, error } = await db
      .from('notificaciones_usuario')
      .select('*')
      .eq('usuario_id', req.user.id)
      .order('fecha_creacion', { ascending: false })
      .limit(50);
    if (error) throw error;
    return res.status(200).json({ success: true, data });
  } catch (error) {
    return res.status(500).json({ success: false, message: error.message });
  }
});

/** PATCH /api/perfil/mensajes/:id/leer — Marca una notificación como leída */
router.patch("/mensajes/:id/leer", authenticate, async (req, res) => {
  try {
    const { error } = await db
      .from('notificaciones_usuario')
      .update({ leida: true })
      .eq('id', req.params.id)
      .eq('usuario_id', req.user.id);
    if (error) throw error;
    return res.status(200).json({ success: true, message: 'Notificación marcada como leída' });
  } catch (error) {
    return res.status(500).json({ success: false, message: error.message });
  }
});

/** PATCH /api/perfil/mensajes/leer-todas — Marca todas como leídas */
router.patch("/mensajes/leer-todas", authenticate, async (req, res) => {
  try {
    const { error } = await db
      .from('notificaciones_usuario')
      .update({ leida: true })
      .eq('usuario_id', req.user.id)
      .eq('leida', false);
    if (error) throw error;
    return res.status(200).json({ success: true, message: 'Todas las notificaciones marcadas como leídas' });
  } catch (error) {
    return res.status(500).json({ success: false, message: error.message });
  }
});

/** DELETE /api/perfil — Elimina la cuenta del usuario autenticado */
router.delete("/", authenticate, eliminarCuenta);

export default router;
