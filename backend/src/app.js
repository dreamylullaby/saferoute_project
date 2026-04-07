// src/server.js

/**
 * @module server
 * @description Punto de entrada del servidor Express.
 * Configura middlewares globales (CORS, JSON) y registra las rutas principales.
 */

import express from "express";
import cors from "cors";
import dotenv from "dotenv";
import userRoutes   from "./interfaces/routes/userRoutes.js";
import reportRoutes from "./interfaces/routes/reportRoutes.js"; // ← una sola vez

dotenv.config();

const app = express();
app.use(cors());
app.use(express.json());

// Rutas
app.use("/api/auth",     userRoutes);
app.use("/api/reportes", reportRoutes);

export default app;