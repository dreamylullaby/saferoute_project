// src/domain/entities/Report.js

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
    tipo_hurto,
    descripcion,
    objeto_hurtado,
    numero_agresores,
    fecha_creacion,
    fecha_actualizacion,
    actualizado_por,
    estado,
    barrio_ingresado,
    zona_id
  }) {
    this.id = id;
    this.usuario_id = usuario_id;
    this.tipo_reportante = tipo_reportante;
    this.fecha_incidente = fecha_incidente;
    this.franja_horaria = franja_horaria;
    this.latitud = latitud;
    this.longitud = longitud;
    this.direccion = direccion;
    this.tipo_hurto = tipo_hurto;
    this.descripcion = descripcion;
    this.objeto_hurtado = objeto_hurtado;
    this.numero_agresores = numero_agresores;
    this.fecha_creacion = fecha_creacion;
    this.fecha_actualizacion = fecha_actualizacion;
    this.actualizado_por = actualizado_por;
    this.estado = estado;
    this.barrio_ingresado = barrio_ingresado;
    this.zona_id = zona_id;
  }
}

export default Report;
