import api from "./api";

/**
 * Servicio de autenticación para el panel de administración.
 * @module authService
 */

/**
 * Login exclusivo para administradores.
 * Guarda el token y datos del admin en sessionStorage.
 */
export const loginAdmin = async (correo, password) => {
  const response = await api.post("/api/auth/admin-login", { correo, password });
  const { user, token } = response.data;
  sessionStorage.setItem("admin", JSON.stringify(user));
  sessionStorage.setItem("token", token);
  return response.data;
};

/**
 * Cierra sesión llamando al backend y limpiando sessionStorage.
 */
export const logoutAdmin = async () => {
  try {
    await api.post("/api/auth/logout");
  } finally {
    sessionStorage.removeItem("admin");
    sessionStorage.removeItem("token");
  }
};
