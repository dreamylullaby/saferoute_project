// src/domain/repositories/alertRepository.js

/**
 * Repositorio de alertas (contrato).
 * Define las operaciones sobre configuracion_alertas y alertas.
 */
class AlertRepository {

  /**
   * Obtiene la configuración de alertas de un usuario.
   * Si no existe, retorna null.
   * @param {string} usuarioId - UUID del usuario
   * @returns {Promise<Object|null>}
   */
  async findConfigByUsuario(usuarioId) {}

  /**
   * Crea o actualiza la configuración de alertas de un usuario (upsert).
   * @param {string}  usuarioId   - UUID del usuario
   * @param {number}  radioMetros - Radio en metros (100-5000)
   * @param {boolean} activo      - Si las alertas están activas
   * @returns {Promise<Object>} Configuración guardada
   */
  async upsertConfig(usuarioId, radioMetros, activo) {}

  /**
   * Busca reportes activos dentro del radio del usuario usando la fórmula de Haversine.
   * Solo considera reportes creados en las últimas 24h para no saturar.
   * @param {number} latitud     - Latitud actual del usuario
   * @param {number} longitud    - Longitud actual del usuario
   * @param {number} radioMetros - Radio de búsqueda en metros
   * @returns {Promise<Array>}   - Reportes cercanos con distancia calculada
   */
  async findReportesCercanos(latitud, longitud, radioMetros) {}

  /**
   * Lista las alertas no leídas de un usuario.
   * @param {string} usuarioId
   * @returns {Promise<Array>}
   */
  async findNoLeidasByUsuario(usuarioId) {}

  /**
   * Marca una alerta como leída.
   * @param {string} alertaId  - UUID de la alerta
   * @param {string} usuarioId - UUID del usuario (para verificar ownership)
   * @returns {Promise<Object>}
   */
  async marcarLeida(alertaId, usuarioId) {}
}

export default AlertRepository;
