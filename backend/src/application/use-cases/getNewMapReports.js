// src/application/use-cases/getNewMapReports.js

/**
 * @class GetNewMapReports
 * @classdesc Caso de uso para obtener reportes nuevos desde un timestamp dado.
 * Usado por el cliente para actualizar el mapa sin recargar todos los marcadores.
 */
class GetNewMapReports {

  /**
   * @param {import('../../domain/repositories/reportRepository.js').default} reportRepository
   */
  constructor(reportRepository) {
    this.reportRepository = reportRepository;
  }

  /**
   * @param {string} desde - ISO 8601 timestamp. Ej: "2026-04-05T10:00:00.000Z"
   * @returns {Promise<Object[]>} Reportes activos creados después de `desde`
   */
  async execute(desde) {
    if (!desde) throw new Error('El parámetro "desde" es requerido');
    return await this.reportRepository.findNewSince(desde);
  }
}

export default GetNewMapReports;
