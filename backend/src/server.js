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
import reportRoutes from "./interfaces/routes/reportRoutes.js";
import alertRoutes  from "./interfaces/routes/alertRoutes.js";

dotenv.config();

const app = express();
app.use(cors());
app.use(express.json());

// Rutas
app.use("/api/auth",     userRoutes);
app.use("/api/reportes", reportRoutes);
app.use("/api/alertas",  alertRoutes);

const PORT = process.env.PORT || 3000;
app.listen(PORT, () => console.log(`Servidor corriendo en puerto ${PORT}`));
