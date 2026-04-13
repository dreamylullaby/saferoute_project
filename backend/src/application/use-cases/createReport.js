// src/application/use-cases/createReport.js

import Report from '../../domain/entities/Report.js';
import admin from '../../infrastructure/firebase/firebase.js';

/**
 * Caso de uso para crear un reporte de hurto.
 * Se encarga de validar los datos, resolver el barrio (si es posible),
 * delegar la persistencia al repositorio y enviar notificaciones push.
 */
class CreateReport {

  /**
   * @param {ReportRepository}  reportRepository
   * @param {AlertRepository}   [alertRepository] - Opcional, para envío de push
   */
  constructor(reportRepository, alertRepository = null) {
    this.reportRepository = reportRepository;
    this.alertRepository  = alertRepository;
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

    if (data.descripcion && data.descripcion.trim().length > 300)
      throw new Error('descripcion excede la longitud máxima de 300 caracteres');

    // zona_id lo asigna automáticamente el trigger en BD
    const reporte = await this.reportRepository.create({
      ...data,
      barrio_ingresado: data.barrio_ingresado.trim(),
      estado: 'activo'
    });

    // Enviar notificaciones push (fire and forget — no bloquea la respuesta)
    this._enviarPushCercanos(reporte).catch(() => {});

    return reporte;
  }

  /**
   * Envía notificaciones push a usuarios con alertas activas.
   * No lanza errores para no interrumpir la creación del reporte.
   */
  async _enviarPushCercanos(reporte) {
    if (!this.alertRepository) return;

    try {
      const usuarios = await this.alertRepository.findUsuariosCercanosConToken(
        reporte.latitud,
        reporte.longitud
      );

      if (!usuarios.length) {
        console.log(`[Push] No hay usuarios con token activo para notificar.`);
        return;
      }

      const tipo   = reporte.tipo_hurto[0].toUpperCase() + reporte.tipo_hurto.slice(1);
      const barrio = reporte.barrio_ingresado || 'zona cercana';

      console.log(`[Push] Enviando notificación a ${usuarios.length} usuario(s) — ${tipo} en ${barrio}`);

      const mensajes = usuarios.map(u => ({
        token: u.fcm_token,
        notification: {
          title: `⚠️ Alerta de hurto cercano`,
          body:  `${tipo} reportado en ${barrio}`,
        },
        data: {
          reporte_id: reporte.id,
          tipo_hurto: reporte.tipo_hurto,
          latitud:    String(reporte.latitud),
          longitud:   String(reporte.longitud),
          barrio:     barrio,
        },
        android: {
          priority: 'high',
          notification: { channelId: 'alertas_hurto' },
        },
      }));

      // Enviar en lotes de 500 (límite de FCM)
      for (let i = 0; i < mensajes.length; i += 500) {
        const lote = mensajes.slice(i, i + 500);
        const resultado = await admin.messaging().sendEach(lote);
        console.log(`[Push] Lote ${Math.floor(i/500) + 1}: ${resultado.successCount} enviados, ${resultado.failureCount} fallidos`);
      }
    } catch (err) {
      console.warn(`[Push] Error al enviar notificaciones: ${err.message}`);
    }
  }
}

export default CreateReport;
