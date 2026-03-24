import CreateReport from "../../application/use-cases/createReport.js";
import GetReports from "../../application/use-cases/getReports.js";

class ReportController {

    constructor(repository) {
        this.createReport = new CreateReport(repository);
        this.getReports = new GetReports(repository);
    }

    async create(req, res) {
        try {
            const result = await this.createReport.execute(req.body);
            res.json(result);
        } catch (error) {
            res.status(400).json({ error: error.message });
        }
    }

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