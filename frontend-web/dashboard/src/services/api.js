/**
 * Cliente HTTP Axios preconfigurado para el panel de administración.
 * Inyecta automáticamente el token JWT en cada petición.
 * @module api
 */
import axios from "axios";

const api = axios.create({
  baseURL: "http://localhost:3000",
});

// Agrega el token JWT en cada request si existe
api.interceptors.request.use((config) => {
  const token = sessionStorage.getItem("token");
  if (token) config.headers.Authorization = `Bearer ${token}`;
  return config;
});

export default api;
