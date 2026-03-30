/**
 * Caso de uso para crear un nuevo reporte de hurto.
 * Valida los campos obligatorios antes de persistir en el repositorio.
 * @class CreateReport
 */
class CreateReport {

  /**
   * @param {import('../../domain/repositories/reportRepository.js').default} reportRepository
   */
  constructor(reportRepository) {
    this.reportRepository = reportRepository;
  }

  /**
   * Ejecuta la creación del reporte tras validar los campos requeridos.
   * @param {Object} data - Datos del reporte
   * @param {string} data.usuario_id - UUID del usuario que reporta (obligatorio)
   * @param {string} data.tipo_reportante - 'victima' o 'testigo' (obligatorio)
   * @param {string} data.fecha_incidente - Fecha del incidente en formato ISO (obligatorio)
   * @param {string} data.franja_horaria - Franja horaria del incidente (obligatorio)
   * @param {number} data.latitud - Latitud de la ubicación (obligatorio)
   * @param {number} data.longitud - Longitud de la ubicación (obligatorio)
   * @param {string} data.tipo_hurto - Tipo de hurto (obligatorio)
   * @param {string} data.barrio_ingresado - Barrio ingresado por el usuario (obligatorio)
   * @returns {Promise<Object>} El reporte creado
   * @throws {Error} Si algún campo obligatorio está ausente
   */
  async execute(data) {

    if (!data.usuario_id)
      throw new Error("usuario_id es obligatorio");

    if (!data.tipo_reportante)
      throw new Error("tipo_reportante es obligatorio");

    if (!data.fecha_incidente)
      throw new Error("fecha_incidente es obligatoria");

    if (!data.franja_horaria)
      throw new Error("franja_horaria es obligatoria");

    if (!data.latitud || !data.longitud)
      throw new Error("coordenadas obligatorias");

    if (!data.tipo_hurto)
      throw new Error("tipo_hurto es obligatorio");

    if (!data.barrio_ingresado)
      throw new Error("barrio_ingresado es obligatorio");

    return await this.reportRepository.create(data);

  }

}

export default CreateReport;
