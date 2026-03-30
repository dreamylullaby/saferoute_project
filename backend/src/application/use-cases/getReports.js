// src/application/use-cases/getReports.js

/**
 * @class GetReports
 * @classdesc Caso de uso para obtener todos los reportes activos.
 * Delega directamente al repositorio sin lógica de negocio adicional.
 */
class GetReports {

  /**
   * @param {import('../../domain/repositories/reportRepository.js').default} reportRepository
   *   Instancia del repositorio que implementa el contrato ReportRepository.
   */
  constructor(reportRepository) {
    this.reportRepository = reportRepository;
  }

  /**
   * Ejecuta la consulta de reportes.
   * Retorna todos los reportes cuyo estado no sea 'eliminado',
   * ordenados por fecha de creación descendente.
   * @returns {Promise<Object[]>} Lista de reportes
   */
  async execute() {
    return await this.reportRepository.findAll();
  }
}

export default GetReports;