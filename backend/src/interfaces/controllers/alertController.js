// src/interfaces/controllers/alertController.js

import GetAlertConfig    from '../../application/use-cases/getAlertConfig.js';
import UpsertAlertConfig from '../../application/use-cases/upsertAlertConfig.js';
import GetNearbyAlerts   from '../../application/use-cases/getNearbyAlerts.js';
import MarkAlertRead     from '../../application/use-cases/markAlertRead.js';

/**
 * @class AlertController
 * @classdesc Controlador HTTP para el módulo de alertas por proximidad.
 */
class AlertController {

  constructor(alertRepository) {
    this.GetAlertConfigUC    = new GetAlertConfig(alertRepository);
    this.UpsertAlertConfigUC = new UpsertAlertConfig(alertRepository);
    this.GetNearbyAlertsUC   = new GetNearbyAlerts(alertRepository);
    this.MarkAlertReadUC     = new MarkAlertRead(alertRepository);
  }

  /**
   * GET /api/alertas/configuracion
   * Retorna la configuración de alertas del usuario autenticado.
   */
  async getConfig(req, res) {
    try {
      const result = await this.GetAlertConfigUC.execute(req.user.id);
      return res.status(200).json({ success: true, data: result });
    } catch (error) {
      return res.status(500).json({ success: false, message: error.message });
    }
  }

  /**
   * PUT /api/alertas/configuracion
   * Body: { radio_metros: number, activo?: boolean }
   * Crea o actualiza la configuración de alertas del usuario.
   */
  async upsertConfig(req, res) {
    try {
      const { radio_metros, activo } = req.body;
      const result = await this.UpsertAlertConfigUC.execute(req.user.id, radio_metros, activo);
      return res.status(200).json({ success: true, data: result });
    } catch (error) {
      const status = error.message.includes('obligatorio') || error.message.includes('debe') ? 400 : 500;
      return res.status(status).json({ success: false, message: error.message });
    }
  }

  /**
   * GET /api/alertas?lat=&lng=
   * Retorna reportes cercanos al usuario según su radio configurado.
   * El Flutter envía la ubicación actual como query params.
   */
  async getNearby(req, res) {
    try {
      const { lat, lng } = req.query;
      const result = await this.GetNearbyAlertsUC.execute(req.user.id, lat, lng);
      return res.status(200).json({ success: true, data: result });
    } catch (error) {
      const status = error.message.includes('obligatori') || error.message.includes('válid') ? 400 : 500;
      return res.status(status).json({ success: false, message: error.message });
    }
  }

  /**
   * PATCH /api/alertas/:id/leida
   * Marca una alerta específica como leída.
   */
  async markRead(req, res) {
    try {
      const result = await this.MarkAlertReadUC.execute(req.params.id, req.user.id);
      return res.status(200).json({ success: true, data: result });
    } catch (error) {
      const status = error.message.includes('no encontrada') ? 404 : 500;
      return res.status(status).json({ success: false, message: error.message });
    }
  }
}

export default AlertController;
