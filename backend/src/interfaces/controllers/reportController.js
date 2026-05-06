// src/interfaces/controllers/reportController.js

import CreateReport from "../../application/use-cases/createReport.js";
import GetReports from "../../application/use-cases/getReports.js";
import GetMapReports from "../../application/use-cases/getMapReports.js";
import GetNewMapReports from "../../application/use-cases/getNewMapReports.js";
import GetFilteredMapReports from "../../application/use-cases/getFilteredMapReports.js";
import AlertRepositoryImpl from "../../infrastructure/database/repositoriesImplementation/alertRepositoryImpl.js";
import Report from "../../domain/entities/Report.js";

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
      const { comunas, franjas, tipos, fechaDesde, fechaHasta, corregimientos, zonaTipo } = req.query;
      const filtros = {
        comunas:         comunas         ? comunas.split(',').map(Number)         : undefined,
        corregimientos:  corregimientos  ? corregimientos.split(',').map(Number)  : undefined,
        franjas:         franjas         ? franjas.split(',')                     : undefined,
        tipos:           tipos           ? tipos.split(',')                       : undefined,
        fechaDesde:      fechaDesde      || undefined,
        fechaHasta:      fechaHasta      || undefined,
        zonaTipo:        zonaTipo        || undefined,
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

  /** GET /api/reportes/corregimientos — Lista todos los corregimientos */
  async listarCorregimientos(req, res) {
    try {
      const data = await this.repository.listarCorregimientos();
      return res.status(200).json({ success: true, data });
    } catch (error) {
      return res.status(500).json({ success: false, message: error.message });
    }
  }

  /** GET /api/reportes/corregimientos/:id/veredas — Veredas de un corregimiento */
  async listarVeredas(req, res) {
    try {
      const { id } = req.params;
      const data = await this.repository.listarVeredasPorCorregimiento(Number(id));
      return res.status(200).json({ success: true, data });
    } catch (error) {
      return res.status(500).json({ success: false, message: error.message });
    }
  }

  /** GET /api/reportes/corregimientos-por-coordenadas?lat=X&lng=Y */
  async buscarCorregimientoPorCoordenadas(req, res) {
    try {
      const { lat, lng } = req.query;
      if (!lat || !lng) return res.status(400).json({ success: false, message: 'lat y lng son requeridos' });
      const latNum = parseFloat(lat);
      const lngNum = parseFloat(lng);
      if (isNaN(latNum) || isNaN(lngNum))
        return res.status(400).json({ success: false, message: 'lat y lng deben ser números válidos' });

      const result = await this.repository.buscarCorregimientoPorCoordenadas(latNum, lngNum);
      if (!result)
        return res.status(200).json({ success: true, data: null, mensaje: 'coordenadas_sin_cobertura_rural' });

      return res.status(200).json({ success: true, data: result });
    } catch (error) {
      return res.status(500).json({ success: false, message: error.message });
    }
  }

  /** GET /api/reportes/buscar-rural?q=texto — Busca veredas y corregimientos por texto */
  async buscarRural(req, res) {
    try {
      const { q } = req.query;
      if (!q || q.trim().length < 2)
        return res.status(200).json({ success: true, data: [] });

      const data = await this.repository.buscarVeredaCorregimiento(q.trim());
      return res.status(200).json({ success: true, data });
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
      const { page = 1, limit = 10, tipo_hurto, estado, fechaDesde, fechaHasta, comuna, zona_tipo, corregimiento_id, busqueda } = req.query;
      const result = await this.repository.findForAdmin({
        page:             Number(page),
        limit:            Number(limit),
        tipo_hurto:       tipo_hurto       || undefined,
        estado:           estado           || undefined,
        fechaDesde:       fechaDesde       || undefined,
        fechaHasta:       fechaHasta       || undefined,
        comuna:           comuna           || undefined,
        zona_tipo:        zona_tipo        || undefined,
        corregimiento_id: corregimiento_id || undefined,
        busqueda:         busqueda         || undefined,
      });
      return res.status(200).json({ success: true, ...result });
    } catch (error) {
      return res.status(500).json({ success: false, message: error.message });
    }
  }

  /** GET /api/reportes/admin/resumen — conteos para tarjetas del dashboard (solo admin) */
  async getResumen(req, res) {
    try {
      const { zona_tipo } = req.query;
      const result = await this.repository.getResumen(zona_tipo || null);
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

  /** GET /api/reportes/mis-reportes — reportes del usuario autenticado */
  async getMisReportes(req, res) {
    try {
      const result = await this.repository.findByUsuario(req.user.id);
      return res.status(200).json({ success: true, data: result });
    } catch (error) {
      return res.status(500).json({ success: false, message: error.message });
    }
  }

  /** GET /api/reportes/mis-reportes/:id — detalle de reporte propio */
  async getMiReporteById(req, res) {
    try {
      const reporte = await this.repository.findByIdAndUsuario(req.params.id, req.user.id);
      if (!reporte)
        return res.status(404).json({ success: false, message: 'Reporte no encontrado o no te pertenece' });
      return res.status(200).json({ success: true, data: reporte });
    } catch (error) {
      return res.status(500).json({ success: false, message: error.message });
    }
  }

  /** PUT /api/reportes/:id — editar reporte propio */
  async updateOwn(req, res) {
    try {
      const { id } = req.params;

      // Verificar ownership
      const reporte = await this.repository.findByIdAndUsuario(id, req.user.id);
      if (!reporte)
        return res.status(404).json({ success: false, message: 'Reporte no encontrado o no te pertenece' });

      if (reporte.estado !== 'activo')
        return res.status(400).json({ success: false, message: 'Solo se pueden editar reportes activos' });

      const {
        tipo_reportante, fecha_incidente, franja_horaria,
        tipo_hurto, descripcion, objeto_hurtado,
        numero_agresores, barrio_ingresado, direccion,
      } = req.body;

      // Validar campos con los valores permitidos de la entidad
      if (tipo_reportante && !Report.tipo_reportante.includes(tipo_reportante))
        return res.status(400).json({ success: false, message: `tipo_reportante inválido. Valores: ${Report.tipo_reportante.join(', ')}` });

      if (franja_horaria && !Report.franja_horaria.includes(franja_horaria))
        return res.status(400).json({ success: false, message: `franja_horaria inválida. Valores: ${Report.franja_horaria.join(', ')}` });

      if (tipo_hurto && !Report.tipo_hurto.includes(tipo_hurto))
        return res.status(400).json({ success: false, message: `tipo_hurto inválido. Valores: ${Report.tipo_hurto.join(', ')}` });

      if (objeto_hurtado && !Report.objeto_hurtado.includes(objeto_hurtado))
        return res.status(400).json({ success: false, message: `objeto_hurtado inválido. Valores: ${Report.objeto_hurtado.join(', ')}` });

      if (numero_agresores && !Report.numero_agresores.includes(numero_agresores))
        return res.status(400).json({ success: false, message: `numero_agresores inválido. Valores: ${Report.numero_agresores.join(', ')}` });

      if (descripcion && descripcion.trim().length > 300)
        return res.status(400).json({ success: false, message: 'descripcion excede 300 caracteres' });

      // Solo actualizar campos que vienen en el body
      const campos = {};
      if (tipo_reportante !== undefined) campos.tipo_reportante = tipo_reportante;
      if (fecha_incidente  !== undefined) campos.fecha_incidente  = fecha_incidente;
      if (franja_horaria   !== undefined) campos.franja_horaria   = franja_horaria;
      if (tipo_hurto       !== undefined) campos.tipo_hurto       = tipo_hurto;
      if (descripcion      !== undefined) campos.descripcion      = descripcion;
      if (objeto_hurtado   !== undefined) campos.objeto_hurtado   = objeto_hurtado;
      if (numero_agresores !== undefined) campos.numero_agresores = numero_agresores;
      if (barrio_ingresado !== undefined) campos.barrio_ingresado = barrio_ingresado.trim();
      if (direccion        !== undefined) campos.direccion        = direccion;

      if (Object.keys(campos).length === 0)
        return res.status(400).json({ success: false, message: 'No se enviaron campos para actualizar' });

      const updated = await this.repository.updateOwn(id, req.user.id, campos);
      return res.status(200).json({ success: true, data: updated });
    } catch (error) {
      return res.status(500).json({ success: false, message: error.message });
    }
  }

  /** POST /api/reportes/:id/solicitar-eliminacion */
  async solicitarEliminacion(req, res) {
    try {
      const { id }    = req.params;
      const { motivo } = req.body;

      // Verificar ownership
      const reporte = await this.repository.findByIdAndUsuario(id, req.user.id);
      if (!reporte)
        return res.status(404).json({ success: false, message: 'Reporte no encontrado o no te pertenece' });

      if (reporte.estado === 'eliminado')
        return res.status(400).json({ success: false, message: 'El reporte ya está eliminado' });

      const solicitud = await this.repository.crearSolicitudEliminacion(id, req.user.id, motivo);
      return res.status(201).json({ success: true, data: solicitud });
    } catch (error) {
      const status = error.message.includes('pendiente') ? 409 : 500;
      return res.status(status).json({ success: false, message: error.message });
    }
  }
  /** GET /api/reportes/stats-login — Stats públicas para pantalla de login admin */
  async getStatsLogin(req, res) {
    try {
      const stats = await this.repository.getStatsLogin();
      return res.status(200).json({ success: true, data: stats });
    } catch (error) {
      return res.status(200).json({ success: true, data: { reportes: 0, usuarios: 0, corregimientos: 0, comunas: 12 } });
    }
  }
}

export default ReportController;
