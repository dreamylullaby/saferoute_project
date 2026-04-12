// src/application/use-cases/getNearbyAlerts.js

/**
 * @class GetNearbyAlerts
 * @classdesc Calcula alertas para el usuario según su ubicación actual.
 * Busca reportes activos de las últimas 24h dentro del radio configurado.
 * Opción B: el cálculo ocurre cuando el usuario abre la app y envía su ubicación.
 */
class GetNearbyAlerts {

  constructor(alertRepository) {
    this.alertRepository = alertRepository;
  }

  /**
   * @param {string} usuarioId - UUID del usuario autenticado
   * @param {number} latitud   - Latitud actual del usuario
   * @param {number} longitud  - Longitud actual del usuario
   * @returns {Promise<Object>} { config, alertas }
   */
  async execute(usuarioId, latitud, longitud) {
    if (latitud === undefined || latitud === null)
      throw new Error('latitud es obligatoria');

    if (longitud === undefined || longitud === null)
      throw new Error('longitud es obligatoria');

    const lat = parseFloat(latitud);
    const lng = parseFloat(longitud);

    if (isNaN(lat) || isNaN(lng))
      throw new Error('latitud y longitud deben ser números válidos');

    // Obtener configuración del usuario (o defaults)
    const config = await this.alertRepository.findConfigByUsuario(usuarioId);
    const radioMetros = config?.radio_metros ?? 500;
    const activo      = config?.activo ?? true;

    // Si el usuario desactivó las alertas, retornar vacío
    if (!activo) return { config, alertas: [] };

    const alertas = await this.alertRepository.findReportesCercanos(lat, lng, radioMetros);
    return { config: config ?? { radio_metros: radioMetros, activo }, alertas };
  }
}

export default GetNearbyAlerts;
