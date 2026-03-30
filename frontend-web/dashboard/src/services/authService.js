import api from "./api";

export const loginAdmin = async (correo, password) => {
  const response = await api.post("/api/auth/login", { correo, password });
  return response.data;
};
