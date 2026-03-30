import CreateReport from "../../application/use-cases/createReport.js";
import GetReports from "../../application/use-cases/getReports.js";

/**
 * Controlador HTTP para los endpoints de reportes.
 * Delega la lógica de negocio a los casos de uso correspondientes.
 * @class ReportController
 */
class ReportController {

  /**
   * @param {import('../../domain/repositories/reportRepository.js').default} repository
   */
  constructor(repository) {
    this.createReport = new CreateReport(repository);
    this.getReports = new GetReports(repository);
  }

  /**
   * Maneja POST /api/reportes
   * Crea un nuevo reporte con los datos del body.
   * @param {import('express').Request} req
   * @param {import('express').Response} res
   */
  async create(req, res) {
    try {
      const result = await this.createReport.execute(req.body);
      res.json(result);
    } catch (error) {
      res.status(400).json({ error: error.message });
    }
  }

  /**
   * Maneja GET /api/reportes
   * Retorna todos los reportes no eliminados.
   * @param {import('express').Request} req
   * @param {import('express').Response} res
   */
  async list(req, res) {
    try {
      const result = await this.getReports.execute();
      res.json(result);
    } catch (error) {
      res.status(500).json({ error: error.message });
    }
  }

}

export default ReportController;
