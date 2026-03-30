/**
 * Rutas de autenticación de usuarios.
 * Base: /api/auth
 * @module userRoutes
 */
import express from "express";
import { loginLocal, loginGoogle, registerLocal } from "../controllers/userController.js";

const router = express.Router();

/** POST /api/auth/register — Registro de usuario local */
router.post("/register", registerLocal);

/** POST /api/auth/login — Login con correo y contraseña */
router.post("/login", loginLocal);

/** POST /api/auth/google — Login o registro con Google (Firebase idToken) */
router.post("/google", loginGoogle);

export default router;
