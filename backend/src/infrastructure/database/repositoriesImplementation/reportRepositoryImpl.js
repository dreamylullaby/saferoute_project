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
        barrio_ingresado: data.barrio_ingresado
        // zona_id lo asigna el trigger automáticamente
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
      .select('*, zonas(barrio)')
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
      .select('*, zonas(barrio)')
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

  /**
   * Obtiene reportes activos con solo los campos necesarios para pintar el mapa.
   * @returns {Promise<Array>} Lista reducida: id, latitud, longitud, tipo_hurto, franja_horaria, fecha_incidente, barrio_ingresado
   */
  async findForMap() {
    const { data, error } = await supabase
      .from('reportes')
      .select('id, latitud, longitud, tipo_hurto, franja_horaria, fecha_incidente, barrio_ingresado, comuna')
      .eq('estado', 'activo')
      .order('fecha_creacion', { ascending: false });

    if (error) throw new Error(`Error al obtener reportes del mapa: ${error.message}`);
    return data;
  }

  /**
   * Obtiene reportes activos creados después del timestamp indicado.
   * Usado para la actualización automática del mapa cada minuto.
   * @param {string} desde - ISO 8601 timestamp
   * @returns {Promise<Array>} Reportes nuevos desde esa fecha
   */
  async findNewSince(desde) {
    const { data, error } = await supabase
      .from('reportes')
      .select('id, latitud, longitud, tipo_hurto, franja_horaria, fecha_incidente, barrio_ingresado, comuna')
      .eq('estado', 'activo')
      .gt('fecha_creacion', desde)
      .order('fecha_creacion', { ascending: false });

    if (error) throw new Error(`Error al obtener reportes nuevos: ${error.message}`);
    return data;
  }

  /**
   * Obtiene reportes activos del mapa aplicando filtros combinados.
   * Todos los filtros son opcionales y se combinan con AND.
   * @param {Object}   filtros
   * @param {number[]} [filtros.comunas]    - Comunas a incluir
   * @param {string[]} [filtros.franjas]    - Franjas horarias a incluir
   * @param {string[]} [filtros.tipos]      - Tipos de hurto a incluir
   * @param {string}   [filtros.fechaDesde] - Fecha mínima del incidente (YYYY-MM-DD)
   * @param {string}   [filtros.fechaHasta] - Fecha máxima del incidente (YYYY-MM-DD)
   * @returns {Promise<Array>} Reportes filtrados para el mapa
   */
  async findForMapFiltered({ comunas, franjas, tipos, fechaDesde, fechaHasta } = {}) {
    let query = supabase
      .from('reportes')
      .select('id, latitud, longitud, tipo_hurto, franja_horaria, fecha_incidente, barrio_ingresado, comuna')
      .eq('estado', 'activo')
      .order('fecha_creacion', { ascending: false });

    if (comunas?.length)    query = query.in('comuna', comunas);
    if (franjas?.length)    query = query.in('franja_horaria', franjas);
    if (tipos?.length)      query = query.in('tipo_hurto', tipos);
    if (fechaDesde)         query = query.gte('fecha_incidente', fechaDesde);
    if (fechaHasta)         query = query.lte('fecha_incidente', fechaHasta);

    const { data, error } = await query;
    if (error) throw new Error(`Error al obtener reportes filtrados: ${error.message}`);
    return data;
  }

  /**
   * Busca barrios que contengan el texto ingresado.
   * @param {string} texto - Texto parcial del barrio
   * @returns {Promise<Array>} Lista de barrios que coinciden
   */
  async buscarBarrioPorTexto(texto) {
    const { data, error } = await supabase
      .from('zonas')
      .select('id, barrio, comuna')
      .ilike('barrio', `%${texto}%`)
      .order('barrio', { ascending: true })
      .limit(10);

    if (error) throw new Error(`Error al buscar barrios: ${error.message}`);
    return data;
  }
}