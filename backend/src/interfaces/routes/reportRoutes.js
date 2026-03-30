// src/interfaces/routes/reportRoutes.js

import express from "express";
import ReportController    from "../controllers/reportController.js";
import ReportRepositoryImpl from "../../infrastructure/database/repositoriesImplementation/reportRepositoryImpl.js";

const router = express.Router();

/**
 * Inicialización de dependencias
 * - Repository: acceso a datos
 * - Controller: manejo de peticiones HTTP
 */
const repository = new ReportRepositoryImpl();
const controller = new ReportController(repository);

/** POST /api/reportes — Crea un nuevo reporte */
router.post('/',    (req, res) => controller.create(req, res));

/** GET /api/reportes — Lista todos los reportes no eliminados */
router.get('/',     (req, res) => controller.list(req, res));

/** GET /api/reportes/:id — Obtiene un reporte por su UUID */
router.get('/:id',  (req, res) => controller.getById(req, res));

export default router;