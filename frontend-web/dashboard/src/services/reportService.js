import api from "./api";

/**
 * Obtiene el resumen de conteos para las tarjetas del dashboard.
 */
export const getResumen = async () => {
  const { data } = await api.get("/api/reportes/admin/resumen");
  return data.data;
};

/**
 * Lista reportes con filtros y paginación para el panel admin.
 * @param {Object} params - { page, limit, tipo_hurto, estado, fechaDesde, fechaHasta, comuna }
 */
export const getReportesAdmin = async (params = {}) => {
  const { data } = await api.get("/api/reportes/admin", { params });
  return data;
};

/**
 * Obtiene el detalle completo de un reporte por su ID.
 */
export const getReporteById = async (id) => {
  const { data } = await api.get(`/api/reportes/${id}`);
  return data.data;
};
