// src/application/use-cases/createReport.js
class CreateReport {

  constructor(reportRepository) {
    this.reportRepository = reportRepository;
  }

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
