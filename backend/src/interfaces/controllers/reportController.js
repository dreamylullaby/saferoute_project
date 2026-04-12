// src/interfaces/controllers/reportController.js

import CreateReport from "../../application/use-cases/createReport.js";
import GetReports from "../../application/use-cases/getReports.js";
import GetMapReports from "../../application/use-cases/getMapReports.js";
import GetNewMapReports from "../../application/use-cases/getNewMapReports.js";
import GetFilteredMapReports from "../../application/use-cases/getFilteredMapReports.js";

/**
 * @typedef {Object} Request  - Objeto de petición HTTP de Express
 * @typedef {Object} Response - Objeto de respuesta HTTP de Express
 */

/**
 * @class ReportController
 * @classdesc Controlador HTTP para el recurso `reportes`.
 * Recibe las peticiones Express, delega la lógica a los casos de uso y devuelve respuestas JSON estandarizadas al cliente.
 */
class ReportController {

  constructor(repository) {
    this.repository             = repository;
    this.CreateReportUC         = new CreateReport(repository);
    this.GetReportsUC           = new GetReports(repository);
    this.GetMapReportsUC        = new GetMapReports(repository);
    this.GetNewMapReportsUC     = new GetNewMapReports(repository);
    this.GetFilteredMapReportsUC = new GetFilteredMapReports(repository);
  }

  /**
   * Maneja POST /api/reportes — registra un nuevo reporte de hurto.
   * Flujo:
   * - Recibe datos del request
   * - Ejecuta el caso de uso CreateReport
   * - Retorna respuesta de éxito o error
   *
   * Respuestas:
   * - `201` Reporte creado exitosamente
   * - `400` Error de validación de campos
   * - `500` Error interno de base de datos
   */

  async create(req, res) {
    try {
      const result = await this.CreateReportUC.execute(req.body);
      return res.status(201).json({
        success: true,
        message: 'Reporte registrado con éxito.',
        data: result
      });
    } catch (error) {
      const isBDError = error.message.startsWith('Error al crear reporte:');
      const status = isBDError ? 500 : 400;
      return res.status(status).json({
        success: false,
        message: error.message
      });
    }
  }

  /**
   * Maneja GET /api/reportes — lista todos los reportes no eliminados.
   * Flujo:
   * - Ejecuta el caso de uso GetReports
   * - Retorna la lista de reportes
   *
   * Respuestas:
   * - `200` Lista obtenida exitosamente
   * - `500` Error interno de base de datos
   */
  async list(req, res) {
    try {
      const result = await this.GetReportsUC.execute();
      return res.status(200).json({
        success: true,
        data: result
      });
    } catch (error) {
      return res.status(500).json({
        success: false,
        message: 'Error al obtener los reportes.',
        detail: error.message
      });
    }
  }

  /**
   * Maneja GET /api/reportes/:id — obtiene un reporte por su UUID.
   * Flujo:
   * - Valida que el ID exista
   * - Consulta el repositorio
   * - Retorna el reporte encontrado
   *
   * Respuestas:
   * - `200` Reporte encontrado
   * - `400` El parámetro `id` no fue proporcionado
   * - `404` El reporte no existe en la base de datos
   */
  async getById(req, res) {
    try {
      const { id } = req.params;
      if (!id) {
        return res.status(400).json({
          success: false,
          message: 'Es necesario el ID'
        });
      }
      const result = await this.repository.findById(id);
      return res.status(200).json({
        success: true,
        data: result
      });
    } catch (error) {
      return res.status(404).json({
        success: false,
        message: error.message
      });
    }
  }

  /**
   * Maneja GET /api/reportes/mapa — reportes activos para el mapa interactivo.
   * Retorna solo los campos necesarios para pintar marcadores.
   *
   * Respuestas:
   * - `200` Lista de reportes para el mapa
   * - `500` Error interno
   */
  async getForMap(req, res) {
    try {
      const result = await this.GetMapReportsUC.execute();
      return res.status(200).json({ success: true, data: result });
    } catch (error) {
      return res.status(500).json({ success: false, message: error.message });
    }
  }

  /**
   * Maneja GET /api/reportes/mapa/nuevos?desde=<ISO timestamp>
   * Retorna solo los reportes creados después del timestamp dado.
   * Usado para actualización automática del mapa cada minuto.
   *
   * Respuestas:
   * - `200` Reportes nuevos desde el timestamp
   * - `400` Falta el parámetro `desde`
   * - `500` Error interno
   */
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

  /**
   * Maneja GET /api/reportes/mapa/filtros
   * Acepta query params opcionales: comunas, franjas, tipos, fechaDesde, fechaHasta
   * Todos los arrays se pasan como valores separados por coma.
   *
   * Ejemplo: /api/reportes/mapa/filtros?comunas=1,3&franjas=06:00-11:59&tipos=atraco
   *
   * Respuestas:
   * - `200` Reportes filtrados
   * - `400` Parámetros inválidos
   * - `500` Error interno
   */
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
   * Maneja GET /api/reportes/barrios?q=<texto>
   * Busca barrios similares al texto ingresado usando Levenshtein.
   * Retorna hasta 5 coincidencias ordenadas por similitud.
   */
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