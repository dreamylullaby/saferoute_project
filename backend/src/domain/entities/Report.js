// src/domain/models/Report.js

class Report {
  constructor({
    id,
    usuario_id,
    tipo_reportante,
    fecha_incidente,
    franja_horaria,
    latitud,
    longitud,
    direccion,
    comuna,
    tipo_hurto,
    descripcion,
    objeto_hurtado,
    numero_agresores,
    fecha_creacion,
    fecha_actualizacion,
    actualizado_por,
    estado
  }) {
    this.id = id;
    this.usuario_id = usuario_id;
    this.tipo_reportante = tipo_reportante;
    this.fecha_incidente = fecha_incidente;
    this.franja_horaria = franja_horaria;
    this.latitud = latitud;
    this.longitud = longitud;
    this.direccion = direccion;
    this.comuna = comuna;
    this.tipo_hurto = tipo_hurto;
    this.descripcion = descripcion;
    this.objeto_hurtado = objeto_hurtado;
    this.numero_agresores = numero_agresores;
    this.fecha_creacion = fecha_creacion;
    this.fecha_actualizacion = fecha_actualizacion;
    this.actualizado_por = actualizado_por;
    this.estado = estado;
  }
}

export default Report;