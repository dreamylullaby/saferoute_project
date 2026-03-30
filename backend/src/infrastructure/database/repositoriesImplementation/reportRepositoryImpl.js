/**
 * Implementación concreta del repositorio de reportes usando Supabase.
 * @class ReportRepositoryImpl
 */
import supabase from '../dbScript/db.js';

export default class ReportRepositoryImpl {

  /**
   * Inserta un nuevo reporte en la tabla 'reportes'.
   * @param {Object} data - Datos del reporte
   * @param {string} data.usuario_id - UUID del usuario
   * @param {string} data.tipo_reportante - 'victima' | 'testigo'
   * @param {string} data.fecha_incidente - Fecha ISO del incidente
   * @param {string} data.franja_horaria - Franja horaria
   * @param {number} data.latitud - Latitud
   * @param {number} data.longitud - Longitud
   * @param {string|null} data.direccion - Dirección (opcional)
   * @param {string} data.tipo_hurto - Tipo de hurto
   * @param {string|null} data.descripcion - Descripción (opcional)
   * @param {string|null} data.objeto_hurtado - Objeto hurtado (opcional)
   * @param {string|null} data.numero_agresores - Número de agresores (opcional)
   * @param {string} data.barrio_ingresado - Barrio ingresado por el usuario
   * @param {number|null} data.zona_id - ID de zona validada (opcional)
   * @returns {Promise<Object>} El reporte creado
   */
  async create(data) {
    const { data: newRow, error } = await supabase
      .from('reportes')
      .insert([{
        usuario_id:       data.usuario_id,
        tipo_reportante:  data.tipo_reportante,
        fecha_incidente:  data.fecha_incidente,
        franja_horaria:   data.franja_horaria,
        latitud:          data.latitud,
        longitud:         data.longitud,
        direccion:        data.direccion,
        tipo_hurto:       data.tipo_hurto,
        descripcion:      data.descripcion,
        objeto_hurtado:   data.objeto_hurtado,
        numero_agresores: data.numero_agresores,
        barrio_ingresado: data.barrio_ingresado,
        zona_id:          data.zona_id ?? null,
        estado:           'activo'
      }])
      .select();

    if (error) throw error;
    return newRow[0];
  }

  /**
   * Obtiene todos los reportes no eliminados con datos de zona.
   * @returns {Promise<Array>} Lista de reportes ordenados por fecha_creacion DESC
   */
  async findAll() {
    const { data, error } = await supabase
      .from('reportes')
      .select('*, zonas(barrio, comuna)')
      .neq('estado', 'eliminado')
      .order('fecha_creacion', { ascending: false });

    if (error) throw error;
    return data;
  }

  /**
   * Obtiene un reporte por su UUID con datos de zona.
   * @param {string} id - UUID del reporte
   * @returns {Promise<Object>} El reporte encontrado
   */
  async findById(id) {
    const { data, error } = await supabase
      .from('reportes')
      .select('*, zonas(barrio, comuna)')
      .eq('id', id)
      .single();

    if (error) throw error;
    return data;
  }

}
