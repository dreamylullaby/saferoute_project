/**
 * Repositorio abstracto para la entidad Report.
 * Define el contrato que debe implementar cualquier repositorio concreto de reportes.
 * @class ReportRepository
 */
class ReportRepository {

  /**
   * Crea un nuevo reporte en la base de datos.
   * @param {Object} report - Datos del reporte a crear
   * @returns {Promise<Object>} El reporte creado
   */
  async create(report) {}

  /**
   * Obtiene todos los reportes que no estén eliminados.
   * @returns {Promise<Array>} Lista de reportes
   */
  async findAll() {}

  /**
   * Obtiene un reporte por su ID.
   * @param {string} id - UUID del reporte
   * @returns {Promise<Object>} El reporte encontrado
   */
  async findById(id) {}

}

export default ReportRepository;
