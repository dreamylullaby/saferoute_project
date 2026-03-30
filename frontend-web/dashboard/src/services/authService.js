import api from "./api";

/**
 * Servicio de autenticación para el panel de administración.
 * @module authService
 */

/**
 * Realiza el login de un administrador contra el backend.
 * @param {string} correo - Correo electrónico del administrador
 * @param {string} password - Contraseña del administrador
 * @returns {Promise<{user: {id: string, username: string, correo: string, rol: string}}>}
 * @throws {Error} Si las credenciales son inválidas o hay error de red
 */
export const loginAdmin = async (correo, password) => {
  const response = await api.post("/api/auth/login", { correo, password });
  return response.data;
};
