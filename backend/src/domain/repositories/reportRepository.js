// src/domain/repositories/ReportRepository.js

/**
 * Repositorio de reportes.
 * Define las operaciones que se pueden hacer con los reportes.
 * La implementación real se hace en infraestructura.
 */
class ReportRepository {

  /**
   * Crea un nuevo reporte en la base de datos.
   * @param {Object} report - Datos del reporte a crear
   * @returns El reporte creado
   */
  async create(report) {}

  /**
   * Obtiene todos los reportes que no estén eliminados.
   * @returns Lista de reportes
   */
  async findAll() {}

  //Buscar un reporte por id
  async findById(id) {}

  async buscarBarrioSimilar(textoUsuario) {}

  /**
   * Obtiene reportes activos con solo los campos necesarios para el mapa.
   * @returns Lista de reportes para marcadores
   */
  async findForMap() {}

  /**
   * Obtiene reportes activos creados después de una fecha dada.
   * @param {string} desde - ISO timestamp
   * @returns {Promise<Array>} Reportes nuevos desde esa fecha
   */
  async findNewSince(desde) {}

  /**
   * Obtiene reportes activos del mapa aplicando filtros combinados.
   * @param {Object}   filtros
   * @param {number[]} [filtros.comunas]    - Comunas a incluir
   * @param {string[]} [filtros.franjas]    - Franjas horarias a incluir
   * @param {string[]} [filtros.tipos]      - Tipos de hurto a incluir
   * @param {string}   [filtros.fechaDesde] - Fecha mínima del incidente (YYYY-MM-DD)
   * @param {string}   [filtros.fechaHasta] - Fecha máxima del incidente (YYYY-MM-DD)
   * @returns {Promise<Array>} Reportes filtrados para el mapa
   */
  async findForMapFiltered(filtros) {}
}

export default ReportRepository;
