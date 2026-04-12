// src/application/use-cases/upsertAlertConfig.js

/**
 * @class UpsertAlertConfig
 * @classdesc Crea o actualiza la configuración de alertas del usuario.
 */
class UpsertAlertConfig {

  constructor(alertRepository) {
    this.alertRepository = alertRepository;
  }

  /**
   * @param {string}  usuarioId   - UUID del usuario autenticado
   * @param {number}  radioMetros - Radio en metros (100-5000)
   * @param {boolean} activo      - Si las alertas están habilitadas
   * @returns {Promise<Object>} Configuración guardada
   */
  async execute(usuarioId, radioMetros, activo) {
    if (radioMetros === undefined || radioMetros === null)
      throw new Error('radio_metros es obligatorio');

    if (typeof radioMetros !== 'number' || !Number.isInteger(radioMetros))
      throw new Error('radio_metros debe ser un número entero');

    if (radioMetros < 100 || radioMetros > 5000)
      throw new Error('radio_metros debe estar entre 100 y 5000 metros');

    if (activo !== undefined && typeof activo !== 'boolean')
      throw new Error('activo debe ser un valor booleano');

    return await this.alertRepository.upsertConfig(
      usuarioId,
      radioMetros,
      activo ?? true
    );
  }
}

export default UpsertAlertConfig;
