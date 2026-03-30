// src/config/jwt.js
import jwt from 'jsonwebtoken';

const SECRET  = process.env.JWT_SECRET;
const EXPIRES = process.env.JWT_EXPIRES_IN || '8h';

/**
 * Genera un JWT con el payload del usuario.
 * @param {{ id: string, rol: string }} payload
 * @returns {string} Token firmado
 */
export const generateToken = (payload) =>
  jwt.sign(payload, SECRET, { expiresIn: EXPIRES });

/**
 * Verifica y decodifica un JWT.
 * @param {string} token
 * @returns {Object} Payload decodificado
 * @throws {Error} Si el token es inválido o expiró
 */
export const verifyToken = (token) =>
  jwt.verify(token, SECRET);
