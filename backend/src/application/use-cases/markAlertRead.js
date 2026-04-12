// src/application/use-cases/markAlertRead.js

/**
 * @class MarkAlertRead
 * @classdesc Marca una alerta como leída verificando que pertenezca al usuario.
 */
class MarkAlertRead {

  constructor(alertRepository) {
    this.alertRepository = alertRepository;
  }

  /**
   * @param {string} alertaId  - UUID de la alerta
   * @param {string} usuarioId - UUID del usuario autenticado
   * @returns {Promise<Object>} Alerta actualizada
   */
  async execute(alertaId, usuarioId) {
    if (!alertaId)  throw new Error('alertaId es obligatorio');
    if (!usuarioId) throw new Error('usuarioId es obligatorio');
    return await this.alertRepository.marcarLeida(alertaId, usuarioId);
  }
}

export default MarkAlertRead;
