// src/interfaces/routes/alertRoutes.js

/**
 * Rutas del módulo de alertas por proximidad.
 * Base: /api/alertas
 */
import express from 'express';
import AlertController      from '../controllers/alertController.js';
import AlertRepositoryImpl  from '../../infrastructure/database/repositoriesImplementation/alertRepositoryImpl.js';
import { authenticate }     from '../middlewares/auth.js';

const router     = express.Router();
const repository = new AlertRepositoryImpl();
const controller = new AlertController(repository);

/** GET  /api/alertas/configuracion — Obtiene configuración de alertas del usuario */
router.get('/configuracion',  authenticate, (req, res) => controller.getConfig(req, res));

/** PUT  /api/alertas/configuracion — Crea o actualiza configuración de alertas */
router.put('/configuracion',  authenticate, (req, res) => controller.upsertConfig(req, res));

/** GET  /api/alertas?lat=&lng= — Reportes cercanos según ubicación actual */
router.get('/',               authenticate, (req, res) => controller.getNearby(req, res));

/** PATCH /api/alertas/:id/leida — Marca una alerta como leída */
router.patch('/:id/leida',    authenticate, (req, res) => controller.markRead(req, res));

export default router;
