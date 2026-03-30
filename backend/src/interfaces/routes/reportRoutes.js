// src/interfaces/routes/reportRoutes.js

import express from "express";
import ReportController    from "../controllers/reportController.js";
import ReportRepositoryImpl from "../../infrastructure/database/repositoriesImplementation/reportRepositoryImpl.js";
import { authenticate } from "../middlewares/auth.js";

const router = express.Router();

const repository = new ReportRepositoryImpl();
const controller = new ReportController(repository);

/** POST /api/reportes — Crea un nuevo reporte (requiere autenticación) */
router.post('/',    authenticate, (req, res) => controller.create(req, res));

/** GET /api/reportes — Lista todos los reportes no eliminados (requiere autenticación) */
router.get('/',     authenticate, (req, res) => controller.list(req, res));

/** GET /api/reportes/:id — Obtiene un reporte por su UUID (requiere autenticación) */
router.get('/:id',  authenticate, (req, res) => controller.getById(req, res));

export default router;