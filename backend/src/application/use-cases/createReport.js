// src/application/use-cases/createReport.js

import Report from '../../domain/entities/Report.js';

/**
 * Caso de uso para crear un reporte de hurto.
 * Se encarga de validar los datos, resolver el barrio (si es posible) y delegar la persistencia al repositorio.
 */
class CreateReport {

  /**
   * @param {ReportRepository} reportRepository
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
      throw new Error('tipo_reportante es obligatorio');

    if (!Report.tipo_reportante.includes(data.tipo_reportante))
      throw new Error(
        `tipo_reportante inválido. Valores permitidos: ${Report.tipo_reportante.join(', ')}`
      );

    if (!data.fecha_incidente)
      throw new Error('fecha_incidente es obligatoria');

    if (!data.franja_horaria)
      throw new Error('franja_horaria es obligatoria');

    if (!Report.franja_horaria.includes(data.franja_horaria))
      throw new Error(
        `franja_horaria inválida. Valores permitidos: ${Report.franja_horaria.join(', ')}`
      );

    if (data.latitud === undefined || data.latitud === null)
      throw new Error('latitud es obligatoria');

    if (data.longitud === undefined || data.longitud === null)
      throw new Error('longitud es obligatoria');

    if (!data.tipo_hurto)
      throw new Error('tipo_hurto es obligatorio');

    if (!Report.tipo_hurto.includes(data.tipo_hurto))
      throw new Error(
        `tipo_hurto inválido. Valores permitidos: ${Report.tipo_hurto.join(', ')}`
      );

    if (!data.barrio_ingresado || data.barrio_ingresado.trim() === '')
      throw new Error('barrio_ingresado es obligatorio');

    //Campos opcionales
    if (data.objeto_hurtado && !Report.objeto_hurtado.includes(data.objeto_hurtado))
      throw new Error(
        `objeto_hurtado inválido. Valores permitidos: ${Report.objeto_hurtado.join(', ')}`
      );

    if (data.numero_agresores && !Report.numero_agresores.includes(data.numero_agresores))
      throw new Error(
        `numero_agresores inválido. Valores permitidos: ${Report.numero_agresores.join(', ')}`
      );

    //Resolución de barrio Campo opcional
    let zona_id = null;

    try {
      const sugerencias = await this.reportRepository.buscarBarrioSimilar(
        data.barrio_ingresado.trim()
      );

      if (sugerencias.length > 0 && sugerencias[0].similitud <= 3) {
        zona_id = sugerencias[0].id;
      }
    } catch (_) {
      console.warn('No se pudo resolver el barrio, se continuará sin zona_id');
    }

    //Persistencia
    return await this.reportRepository.create({
      ...data,
      barrio_ingresado: data.barrio_ingresado.trim(),
      zona_id,
      estado: 'activo'
    });
  }
}

export default CreateReport;
