// src/application/usecases/GetReports.js
class GetReports {

  constructor(reportRepository) {
    this.reportRepository = reportRepository;
  }

  async execute() {
    return await this.reportRepository.findAll();
  }

}

export default GetReports;