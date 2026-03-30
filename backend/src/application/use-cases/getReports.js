/**
 * Caso de uso para obtener todos los reportes activos.
 * @class GetReports
 */
class GetReports {

  /**
   * @param {import('../../domain/repositories/reportRepository.js').default} reportRepository
   */
  constructor(reportRepository) {
    this.reportRepository = reportRepository;
  }

  /**
   * Retorna todos los reportes que no estén en estado 'eliminado',
   * ordenados por fecha de creación descendente.
   * @returns {Promise<Array>} Lista de reportes con datos de zona incluidos
   */
  async execute() {
    return await this.reportRepository.findAll();
  }

}

export default GetReports;
