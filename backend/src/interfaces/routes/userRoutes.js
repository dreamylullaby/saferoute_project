/**
 * Rutas de autenticación de usuarios.
 * Base: /api/auth
 * @module userRoutes
 */
import express from "express";
import rateLimit from "express-rate-limit";
import { loginLocal, loginGoogle, registerLocal, loginAdmin, logoutUser, updateUsername, updateFcmToken, forgotPassword, resetPassword, getTerminos } from "../controllers/userController.js";
import { authenticate, requireAdmin } from "../middlewares/auth.js";

const router = express.Router();

// Rate limit: máx 5 solicitudes por IP cada 15 minutos para rutas sensibles
const authLimiter = rateLimit({
  windowMs: 15 * 60 * 1000,
  max: 5,
  message: { message: "Demasiadas solicitudes. Intenta de nuevo en 15 minutos." },
  standardHeaders: true,
  legacyHeaders: false,
});

/** POST /api/auth/register — Registro de usuario local */
router.post("/register", registerLocal);

/** GET /api/auth/terminos — Consultar términos y condiciones vigentes (público) */
router.get("/terminos", getTerminos);

/** POST /api/auth/login — Login con correo y contraseña */
router.post("/login", loginLocal);

/** POST /api/auth/google — Login o registro con Google (Firebase idToken) */
router.post("/google", loginGoogle);

/** POST /api/auth/admin-login — Login exclusivo para administradores */
router.post("/admin-login", loginAdmin);

/** POST /api/auth/logout — Cierra sesión (requiere token válido) */
router.post("/logout", authenticate, logoutUser);

/** PATCH /api/auth/username — Actualiza el apodo del usuario (requiere token válido) */
router.patch("/username", authenticate, updateUsername);

/** PATCH /api/auth/fcm-token — Guarda el FCM token del dispositivo (requiere token válido) */
router.patch("/fcm-token", authenticate, updateFcmToken);

/** POST /api/auth/forgot-password — Solicitar recuperación de contraseña */
router.post("/forgot-password", authLimiter, forgotPassword);

/** POST /api/auth/reset-password — Restablecer contraseña con token */
router.post("/reset-password", authLimiter, resetPassword);

export default router;
