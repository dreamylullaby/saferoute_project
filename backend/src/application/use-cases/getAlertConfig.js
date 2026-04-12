// src/application/use-cases/getAlertConfig.js

/**
 * @class GetAlertConfig
 * @classdesc Obtiene la configuración de alertas del usuario autenticado.
 * Si no tiene configuración, retorna los valores por defecto.
 */
class GetAlertConfig {

  constructor(alertRepository) {
    this.alertRepository = alertRepository;
  }

  /**
   * @param {string} usuarioId - UUID del usuario autenticado
   * @returns {Promise<Object>} Configuración actual o valores por defecto
   */
  async execute(usuarioId) {
    const config = await this.alertRepository.findConfigByUsuario(usuarioId);
    return config ?? { usuario_id: usuarioId, radio_metros: 500, activo: true };
  }
}

export default GetAlertConfig;
