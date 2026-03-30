/**
 * Entidad de dominio que representa un reporte de hurto.
 * @class Report
 */
class Report {

  /**
   * Constructor de la entidad Report.
   * @param {Object} data - Datos del reporte
   * @param {string} data.id - Identificador único UUID del reporte
   * @param {string} data.usuario_id - UUID del usuario que crea el reporte
   * @param {string} data.tipo_reportante - Tipo de reportante ('victima' | 'testigo')
   * @param {Date} data.fecha_incidente - Fecha en la que ocurrió el incidente
   * @param {string} data.franja_horaria - Franja horaria del incidente ('00:00-05:59' | '06:00-11:59' | '12:00-17:59' | '18:00-23:59')
   * @param {number} data.latitud - Coordenada geográfica latitud
   * @param {number} data.longitud - Coordenada geográfica longitud
   * @param {string|null} data.direccion - Dirección del incidente (opcional)
   * @param {string} data.tipo_hurto - Tipo de hurto ('atraco' | 'raponazo' | 'cosquilleo' | 'fleteo')
   * @param {string|null} data.descripcion - Descripción detallada del incidente (máx. 300 caracteres)
   * @param {string|null} data.objeto_hurtado - Tipo de objeto hurtado ('celular' | 'dinero' | 'tarjetas_documentos' | 'articulos_personales' | 'dispositivos_electronicos')
   * @param {string|null} data.numero_agresores - Número de agresores ('1' | '2' | '3+' | 'desconocido')
   * @param {Date} data.fecha_creacion - Fecha de creación del registro
   * @param {Date|null} data.fecha_actualizacion - Fecha de última actualización
   * @param {string|null} data.actualizado_por - UUID del usuario que actualizó el reporte
   * @param {string} data.estado - Estado del reporte ('activo' | 'oculto' | 'eliminado')
   * @param {string} data.barrio_ingresado - Barrio ingresado manualmente por el usuario
   * @param {number|null} data.zona_id - ID de la zona validada (null si no hay coincidencia en la tabla zonas)
   */
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
