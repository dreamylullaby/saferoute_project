// src/infrastructure/database/repositoriesImplementation/ReportRepositoryImpl.js

import supabase from '../dbScript/db.js';
import ReportRepository from '../../../domain/repositories/reportRepository.js';

/**
 * @class ReportRepositoryImpl
 * @extends ReportRepository
 * @classdesc Implementación concreta del contrato {@link ReportRepository} usando Supabase.
 * Toda interacción con la tabla `reportes` y la función PG `buscar_barrio_similar` ocurre aquí.
 */
export default class ReportRepositoryImpl extends ReportRepository {

  /**
   * Inserta un nuevo reporte en la tabla 'reportes'.
   * Los campos opcionales se normalizan a 'null' si no vienen en el objeto.
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
        direccion:        data.direccion        ?? null,
        tipo_hurto:       data.tipo_hurto,
        descripcion:      data.descripcion      ?? null,
        objeto_hurtado:   data.objeto_hurtado   ?? null,
        numero_agresores: data.numero_agresores ?? null,
        estado:           data.estado           ?? 'activo',
        barrio_ingresado: data.barrio_ingresado,
        zona_id:          data.zona_id          ?? null
      }])
      .select();

    if (error) throw new Error(`Error al crear reporte: ${error.message}`);
    return newRow[0];
  }

  /**
   * Obtiene todos los reportes no eliminados con datos de zona incluidos.
   * @throws {Error} Si Supabase retorna un error en la consulta
   */
  async findAll() {
    const { data, error } = await supabase
      .from('reportes')
      .select('*, zonas(barrio, comuna)')
      .neq('estado', 'eliminado')
      .order('fecha_creacion', { ascending: false });

    if (error) throw new Error(`Error al obtener reportes: ${error.message}`);
    return data;
  }

  /**
   * Busca un reporte por su UUID con datos de zona incluidos.
   * @param {string} id - UUID del reporte
   * @returns {Promise<Object>} El reporte encontrado
   * @throws {Error} Si el reporte no existe o Supabase retorna un error
   */
  async findById(id) {
    const { data, error } = await supabase
      .from('reportes')
      .select('*, zonas(barrio, comuna)')
      .eq('id', id)
      .maybeSingle();

    if (!data) throw new Error(`Reporte con id ${id} no encontrado`);
    if (error) throw new Error(`Error al buscar reporte: ${error.message}`);
    return data;
  }

  /**
 * Busca barrios similares usando una función RPC en Supabase.
 * @param {string} textoUsuario - Barrio ingresado por el usuario
 * @returns {Promise<Array>} Lista de hasta 5 barrios similares ordenados por coincidencia
 * @throws {Error} Si ocurre un error en la consulta
 */
  async buscarBarrioSimilar(textoUsuario) {
    const { data, error } = await supabase
      .rpc('buscar_barrio_similar', { texto_usuario: textoUsuario });

    if (error) throw new Error(`Error en búsqueda difusa: ${error.message}`);
    return data;
  }
}