import express from "express";
import ReportController from "../controllers/reportController.js";
import ReportRepositoryImpl from "../../infrastructure/database/repositoriesImplementation/reportRepositoryImpl.js";

const router = express.Router();

// Instanciar repositorio y controlador
const repository = new ReportRepositoryImpl();
const controller = new ReportController(repository);

// Rutas
router.post("/", (req, res) => controller.create(req, res));
router.get("/", (req, res) => controller.list(req, res));

export default router;