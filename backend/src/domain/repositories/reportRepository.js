// src/domain/repositories/ReportRepository.js

/**
 * Repositorio de reportes (contrato).
 * Define las operaciones que se pueden hacer con los reportes.
 * La implementación real se hace en infraestructura.
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

  //Buscar un reporte por id
  async findById(id) {}

  async buscarBarrioSimilar(textoUsuario) {}

  /**
   * Obtiene reportes activos con solo los campos necesarios para el mapa.
   * @returns {Promise<Array>} Lista de reportes para marcadores
   */
  async findForMap() {}

  /**
   * Obtiene reportes activos creados después de una fecha dada.
   * @param {string} desde - ISO timestamp
   * @returns {Promise<Array>} Reportes nuevos desde esa fecha
   */
  async findNewSince(desde) {}
}

export default ReportRepository;
