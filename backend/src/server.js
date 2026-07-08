/**
 * @file app.js
 * @module app
 * @description Configuración principal del servidor backend de SafeRoute.
 * Inicializa Express, registra middlewares globales y monta las rutas
 * principales de autenticación, reportes, alertas, administración y perfil.
 */

import express from "express";
import cors from "cors";
import dotenv from "dotenv";

import userRoutes from "./interfaces/routes/userRoutes.js";
import reportRoutes from "./interfaces/routes/reportRoutes.js";
import alertRoutes from "./interfaces/routes/alertRoutes.js";
import adminRoutes from "./interfaces/routes/adminRoutes.js";
import perfilRoutes from "./interfaces/routes/perfilRoutes.js";

/**
 * Carga las variables de entorno desde el archivo .env
 */
dotenv.config();

/**
 * Instancia principal de la aplicación Express.
 * @type {import("express").Express}
 */
const app = express();

/**
 * Middleware para habilitar solicitudes CORS.
 * Permite comunicación entre frontend y backend.
 */
app.use(cors());

/**
 * Middleware para parsear cuerpos JSON en las solicitudes HTTP.
 */
app.use(express.json());

/* =========================
   Registro de rutas API
========================= */

/**
 * Rutas de autenticación y gestión de usuarios.
 * Prefijo base: /api/auth
 */
app.use("/api/auth", userRoutes);

/**
 * Rutas relacionadas con reportes de hurto.
 * Prefijo base: /api/reportes
 */
app.use("/api/reportes", reportRoutes);

/**
 * Rutas relacionadas con alertas de seguridad.
 * Prefijo base: /api/alertas
 */
app.use("/api/alertas", alertRoutes);

/**
 * Rutas exclusivas de administración.
 * Prefijo base: /api/admin
 */
app.use("/api/admin", adminRoutes);

/**
 * Rutas de perfil de usuario.
 * Prefijo base: /api/perfil
 */
app.use("/api/perfil", perfilRoutes);

/**
 * Exportación de la instancia Express.
 * Se utiliza principalmente en pruebas de integración con Supertest.
 */
export { app };
export default app;

/**
 * Puerto de ejecución del servidor.
 * Usa la variable de entorno PORT o el puerto 3000 por defecto.
 */
const PORT = process.env.PORT || 3000;

/**
 * Inicializa el servidor HTTP.
 * No se ejecuta durante pruebas automatizadas (NODE_ENV=test).
 */
if (process.env.NODE_ENV !== "test") {

  app.listen(PORT, "0.0.0.0", () => {

    console.log(`Servidor corriendo en 0.0.0.0:${PORT}`);

  });

}
