// src/application/use-cases/getMapReports.js

/**
 * @class GetMapReports
 * @classdesc Caso de uso para obtener los reportes activos destinados al mapa interactivo.
 * Retorna solo los campos necesarios para pintar marcadores (coordenadas + metadata básica).
 */
class GetMapReports {

  /**
   * @param {import('../../domain/repositories/reportRepository.js').default} reportRepository
   */
  constructor(reportRepository) {
    this.reportRepository = reportRepository;
  }

  /** @returns {Promise<Object[]>} Reportes activos para el mapa */
  async execute() {
    return await this.reportRepository.findForMap();
  }
}

export default GetMapReports;
