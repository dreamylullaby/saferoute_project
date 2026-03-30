// src/interfaces/middlewares/auth.js
import { verifyToken } from "../../config/jwt.js";

/**
 * Middleware que verifica el JWT en el header Authorization.
 * Agrega `req.user` con el payload decodificado si el token es válido.
 */
export const authenticate = (req, res, next) => {
  const header = req.headers.authorization;

  if (!header || !header.startsWith("Bearer ")) {
    return res.status(401).json({ message: "Token requerido" });
  }

  try {
    req.user = verifyToken(header.split(" ")[1]);
    next();
  } catch {
    return res.status(401).json({ message: "Token inválido o expirado" });
  }
};

/**
 * Middleware que verifica que el usuario autenticado tenga rol 'admin'.
 * Debe usarse después de `authenticate`.
 */
export const requireAdmin = (req, res, next) => {
  if (req.user?.rol !== "admin") {
    return res.status(403).json({ message: "Acceso denegado" });
  }
  next();
};
