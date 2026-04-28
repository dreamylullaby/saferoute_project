// src/interfaces/controllers/reportController.js

import CreateReport from "../../application/use-cases/createReport.js";
import GetReports from "../../application/use-cases/getReports.js";
import GetMapReports from "../../application/use-cases/getMapReports.js";
import GetNewMapReports from "../../application/use-cases/getNewMapReports.js";
import GetFilteredMapReports from "../../application/use-cases/getFilteredMapReports.js";
import AlertRepositoryImpl from "../../infrastructure/database/repositoriesImplementation/alertRepositoryImpl.js";

/**
 * @class ReportController
 * @classdesc Controlador HTTP para el recurso `reportes`.
 */
class ReportController {

  constructor(repository) {
    this.repository              = repository;
    this.CreateReportUC          = new CreateReport(repository, new AlertRepositoryImpl());
    this.GetReportsUC            = new GetReports(repository);
    this.GetMapReportsUC         = new GetMapReports(repository);
    this.GetNewMapReportsUC      = new GetNewMapReports(repository);
    this.GetFilteredMapReportsUC = new GetFilteredMapReports(repository);
  }

  /** POST /api/reportes */
  async create(req, res) {
    try {
      const result = await this.CreateReportUC.execute(req.body);
      return res.status(201).json({ success: true, message: 'Reporte registrado con éxito.', data: result });
    } catch (error) {
      const status = error.message.startsWith('Error al crear reporte:') ? 500 : 400;
      return res.status(status).json({ success: false, message: error.message });
    }
  }

  /** GET /api/reportes */
  async list(req, res) {
    try {
      const result = await this.GetReportsUC.execute();
      return res.status(200).json({ success: true, data: result });
    } catch (error) {
      return res.status(500).json({ success: false, message: 'Error al obtener los reportes.', detail: error.message });
    }
  }

  /** GET /api/reportes/:id */
  async getById(req, res) {
    try {
      const { id } = req.params;
      if (!id) return res.status(400).json({ success: false, message: 'Es necesario el ID' });
      const result = await this.repository.findById(id);
      return res.status(200).json({ success: true, data: result });
    } catch (error) {
      return res.status(404).json({ success: false, message: error.message });
    }
  }

  /** GET /api/reportes/mapa */
  async getForMap(req, res) {
    try {
      const result = await this.GetMapReportsUC.execute();
      return res.status(200).json({ success: true, data: result });
    } catch (error) {
      return res.status(500).json({ success: false, message: error.message });
    }
  }

  /** GET /api/reportes/mapa/nuevos?desde= */
  async getNewForMap(req, res) {
    try {
      const { desde } = req.query;
      const result = await this.GetNewMapReportsUC.execute(desde);
      return res.status(200).json({ success: true, data: result });
    } catch (error) {
      const status = error.message.includes('requerido') ? 400 : 500;
      return res.status(status).json({ success: false, message: error.message });
    }
  }

  /** GET /api/reportes/mapa/filtros */
  async getFiltered(req, res) {
    try {
      const { comunas, franjas, tipos, fechaDesde, fechaHasta } = req.query;
      const filtros = {
        comunas:    comunas    ? comunas.split(',').map(Number) : undefined,
        franjas:    franjas    ? franjas.split(',')             : undefined,
        tipos:      tipos      ? tipos.split(',')               : undefined,
        fechaDesde: fechaDesde || undefined,
        fechaHasta: fechaHasta || undefined,
      };
      const result = await this.GetFilteredMapReportsUC.execute(filtros);
      return res.status(200).json({ success: true, data: result });
    } catch (error) {
      const status = error.message.includes('inválid') ? 400 : 500;
      return res.status(status).json({ success: false, message: error.message });
    }
  }

  /**
   * GET /api/reportes/barrios-por-coordenadas?lat=X&lng=Y
   * Detecta la comuna a partir de coordenadas y retorna los barrios de esa comuna.
   * (Agregado por Sarah — sprint 2)
   */
  async buscarBarriosPorCoordenadas(req, res) {
    try {
      const { lat, lng } = req.query;
      if (!lat || !lng)
        return res.status(400).json({ success: false, message: 'Se requieren los parámetros lat y lng' });

      const latNum = parseFloat(lat);
      const lngNum = parseFloat(lng);
      if (isNaN(latNum) || isNaN(lngNum))
        return res.status(400).json({ success: false, message: 'lat y lng deben ser números válidos' });

      const result = await this.repository.buscarBarriosPorCoordenadas(latNum, lngNum);

      if (!result)
        return res.status(200).json({ success: true, data: null, mensaje: 'coordenadas_sin_cobertura' });

      return res.status(200).json({ success: true, data: result });
    } catch (error) {
      return res.status(500).json({ success: false, message: error.message });
    }
  }

  /** GET /api/reportes/zonas/top?top=10&fechaDesde=&fechaHasta= */
  async getTopZonas(req, res) {
    try {
      const { top = 10, fechaDesde, fechaHasta } = req.query;
      if (isNaN(Number(top)) || Number(top) < 1 || Number(top) > 50)
        return res.status(400).json({ success: false, message: 'top debe ser un número entre 1 y 50' });

      const result = await this.repository.getTopZonas({
        top:        Number(top),
        fechaDesde: fechaDesde || undefined,
        fechaHasta: fechaHasta || undefined,
      });
      return res.status(200).json({ success: true, data: result });
    } catch (error) {
      return res.status(500).json({ success: false, message: error.message });
    }
  }

  /** GET /api/reportes/estadisticas?fechaDesde=&fechaHasta=&agruparPor= */
  async getEstadisticas(req, res) {
    try {
      const { fechaDesde, fechaHasta, agruparPor = 'dia' } = req.query;
      if (!['dia', 'semana', 'mes'].includes(agruparPor))
        return res.status(400).json({ success: false, message: 'agruparPor debe ser: dia, semana o mes' });

      const result = await this.repository.getEstadisticasPorPeriodo({ fechaDesde, fechaHasta, agruparPor });
      return res.status(200).json({ success: true, data: result });
    } catch (error) {
      return res.status(500).json({ success: false, message: error.message });
    }
  }

  /** GET /api/reportes/estadisticas/comparacion?p1Desde=&p1Hasta=&p2Desde=&p2Hasta= */
  async getComparacion(req, res) {
    try {
      const { p1Desde, p1Hasta, p2Desde, p2Hasta } = req.query;
      if (!p1Desde || !p1Hasta || !p2Desde || !p2Hasta)
        return res.status(400).json({ success: false, message: 'Se requieren p1Desde, p1Hasta, p2Desde, p2Hasta' });

      const result = await this.repository.getComparacionPeriodos({ p1Desde, p1Hasta, p2Desde, p2Hasta });
      return res.status(200).json({ success: true, data: result });
    } catch (error) {
      return res.status(500).json({ success: false, message: error.message });
    }
  }

  /** GET /api/reportes/admin — listado paginado con filtros (solo admin) */
  async listAdmin(req, res) {
    try {
      const { page = 1, limit = 10, tipo_hurto, estado, fechaDesde, fechaHasta, comuna } = req.query;
      const result = await this.repository.findForAdmin({
        page:       Number(page),
        limit:      Number(limit),
        tipo_hurto: tipo_hurto || undefined,
        estado:     estado     || undefined,
        fechaDesde: fechaDesde || undefined,
        fechaHasta: fechaHasta || undefined,
        comuna:     comuna     || undefined,
      });
      return res.status(200).json({ success: true, ...result });
    } catch (error) {
      return res.status(500).json({ success: false, message: error.message });
    }
  }

  /** GET /api/reportes/admin/resumen — conteos para tarjetas del dashboard (solo admin) */
  async getResumen(req, res) {
    try {
      const result = await this.repository.getResumen();
      return res.status(200).json({ success: true, data: result });
    } catch (error) {
      return res.status(500).json({ success: false, message: error.message });
    }
  }

  /** GET /api/reportes/barrios?q= */
  async buscarBarrios(req, res) {
    try {
      const { q } = req.query;
      if (!q || q.trim().length < 2)
        return res.status(400).json({ success: false, message: 'Mínimo 2 caracteres' });

      const result = await this.repository.buscarBarrioPorTexto(q.trim());
      return res.status(200).json({ success: true, data: result });
    } catch (error) {
      return res.status(500).json({ success: false, message: error.message });
    }
  }
}

export default ReportController;
