/**
 * Rutas de autenticación de usuarios.
 * Base: /api/auth
 * @module userRoutes
 */
import express from "express";
import { loginLocal, loginGoogle, registerLocal, loginAdmin, logoutUser } from "../controllers/userController.js";
import { authenticate, requireAdmin } from "../middlewares/auth.js";

const router = express.Router();

/** POST /api/auth/register — Registro de usuario local */
router.post("/register", registerLocal);

/** POST /api/auth/login — Login con correo y contraseña */
router.post("/login", loginLocal);

/** POST /api/auth/google — Login o registro con Google (Firebase idToken) */
router.post("/google", loginGoogle);

/** POST /api/auth/admin-login — Login exclusivo para administradores */
router.post("/admin-login", loginAdmin);

/** POST /api/auth/logout — Cierra sesión (requiere token válido) */
router.post("/logout", authenticate, logoutUser);

export default router;
