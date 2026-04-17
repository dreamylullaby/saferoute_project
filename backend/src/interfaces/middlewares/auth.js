// src/interfaces/middlewares/auth.js

/**
 * @module auth
 * @description Middlewares de autenticación y autorización.
 * Verifican el JWT del header Authorization y controlan acceso por rol.
 */

import { verifyToken } from "../../config/jwt.js";

/**
 * Middleware que verifica el JWT en el header Authorization.
 * Agrega `req.user` con el payload decodificado si el token es válido.
 * @param {import('express').Request}  req  - Debe incluir header `Authorization: Bearer <token>`
 * @param {import('express').Response} res
 * @param {import('express').NextFunction} next
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
 * @param {import('express').Request}  req  - Debe contener `req.user.rol`
 * @param {import('express').Response} res
 * @param {import('express').NextFunction} next
 */
export const requireAdmin = (req, res, next) => {
  if (req.user?.rol !== "admin") {
    return res.status(403).json({ message: "Acceso denegado" });
  }
  next();
};
