/**
 * Rutas para la gestión de reportes de hurto.
 * Base: /api/reportes
 * @module reportRoutes
 */
import express from "express";
import ReportController from "../controllers/reportController.js";
import ReportRepositoryImpl from "../../infrastructure/database/repositoriesImplementation/reportRepositoryImpl.js";

const router = express.Router();

const repository = new ReportRepositoryImpl();
const controller = new ReportController(repository);

/** POST /api/reportes — Crea un nuevo reporte */
router.post("/", (req, res) => controller.create(req, res));

/** GET /api/reportes — Lista todos los reportes activos */
router.get("/", (req, res) => controller.list(req, res));

export default router;
