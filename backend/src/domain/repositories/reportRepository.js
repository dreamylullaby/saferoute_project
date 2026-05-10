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

  /**
   * Busca un reporte por su UUID.
   * @param {string} id - UUID del reporte
   * @returns {Promise<Object>} El reporte encontrado con datos de zona
   * @throws {Error} Si el reporte no existe
   */
  async findById(id) {}

  /**
   * Busca barrios similares al texto ingresado usando distancia Levenshtein.
   * @param {string} textoUsuario - Texto del barrio ingresado por el usuario
   * @returns {Promise<Array>} Lista de hasta 5 barrios ordenados por similitud
   */
  async buscarBarrioSimilar(textoUsuario) {}

  /**
   * Busca barrios por coordenadas usando la función RPC get_zona_por_coordenadas.
   * @param {number} lat - Latitud del punto
   * @param {number} lng - Longitud del punto
   * @returns {Promise<Object|null>} { comuna, barrios } o null si no hay cobertura
   */
  async buscarBarriosPorCoordenadas(lat, lng) {}

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

  async findForAdmin(opciones) {}
  async getResumen() {}
  async getEstadisticasPorPeriodo(opciones) {}
  async getComparacionPeriodos(opciones) {}
  async getTopZonas(opciones) {}
  async findByUsuario(usuarioId) {}
  async findByIdAndUsuario(id, usuarioId) {}
  async updateOwn(id, usuarioId, data) {}
  async crearSolicitudEliminacion(reporteId, usuarioId, motivo) {}
}

export default ReportRepository;
