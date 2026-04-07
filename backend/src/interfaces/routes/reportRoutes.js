// src/interfaces/routes/reportRoutes.js

import express from "express";
import ReportController    from "../controllers/reportController.js";
import ReportRepositoryImpl from "../../infrastructure/database/repositoriesImplementation/reportRepositoryImpl.js";
import { authenticate } from "../middlewares/auth.js";

const router = express.Router();

const repository = new ReportRepositoryImpl();
const controller = new ReportController(repository);

/** POST /api/reportes — Crea un nuevo reporte (requiere autenticación) */
router.post('/',              authenticate, (req, res) => controller.create(req, res));

/** GET /api/reportes/mapa — Reportes activos para el mapa (requiere autenticación) */
router.get('/mapa',           authenticate, (req, res) => controller.getForMap(req, res));

/** GET /api/reportes/mapa/nuevos?desde= — Reportes nuevos desde timestamp (requiere autenticación) */
router.get('/mapa/nuevos',    authenticate, (req, res) => controller.getNewForMap(req, res));

/** GET /api/reportes/barrios?q= — Busca barrios similares al texto ingresado */
router.get('/barrios',        authenticate, (req, res) => controller.buscarBarrios(req, res));

/** GET /api/reportes — Lista todos los reportes no eliminados (requiere autenticación) */
router.get('/',               authenticate, (req, res) => controller.list(req, res));

/** GET /api/reportes/:id — Obtiene un reporte por su UUID (requiere autenticación) */
router.get('/:id',            authenticate, (req, res) => controller.getById(req, res));

export default router;