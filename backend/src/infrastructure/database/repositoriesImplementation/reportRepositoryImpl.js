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
        latitud:          data.latitud          ?? null,
        longitud:         data.longitud         ?? null,
        direccion:        data.direccion        ?? null,
        tipo_hurto:       data.tipo_hurto,
        descripcion:      data.descripcion      ?? null,
        objeto_hurtado:   data.objeto_hurtado   ?? null,
        numero_agresores: data.numero_agresores ?? null,
        estado:           data.estado           ?? 'activo',
        barrio_ingresado: data.barrio_ingresado,
        zona_tipo:        data.zona_tipo        ?? 'urbana',
        corregimiento_id: data.corregimiento_id ?? null,
        vereda_id:        data.vereda_id        ?? null,
        // zona_id lo asigna el trigger automáticamente (solo urbano)
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
   * Busca barrios por coordenadas usando la función RPC get_zona_por_coordenadas.
   * Detecta la comuna a partir de los polígonos DANE y retorna sus barrios.
   * @param {number} lat - Latitud del punto
   * @param {number} lng - Longitud del punto
   * @returns {Promise<Object|null>} { comuna, barrios } o null si no hay cobertura
   */
  async buscarBarriosPorCoordenadas(lat, lng) {
    const { data, error } = await supabase
      .rpc('get_zona_por_coordenadas', { lat, lng });

    if (error) throw new Error(`Error al buscar barrios por coordenadas: ${error.message}`);
    if (!data || data.length === 0) return null;
    return { comuna: data[0].comuna, barrios: data[0].barrios };
  }

  /**
   * Lista todos los corregimientos con su ID y nombre.
   * @returns {Promise<Array>} [{ id, nombre }]
   */
  async listarCorregimientos() {
    const { data, error } = await supabase
      .from('corregimientos')
      .select('id, nombre')
      .order('nombre');

    if (error) throw new Error(`Error al listar corregimientos: ${error.message}`);
    return data;
  }

  /**
   * Lista las veredas de un corregimiento específico.
   * @param {number} corregimientoId
   * @returns {Promise<Array>} [{ id, nombre, es_cabecera }]
   */
  async listarVeredasPorCorregimiento(corregimientoId) {
    const { data, error } = await supabase
      .from('veredas')
      .select('id, nombre, es_cabecera')
      .eq('corregimiento_id', corregimientoId)
      .order('nombre');

    if (error) throw new Error(`Error al listar veredas: ${error.message}`);
    return data;
  }

  /**
   * Detecta el corregimiento y sus veredas a partir de coordenadas.
   * Usa la función RPC get_corregimiento_por_coordenadas.
   * @param {number} lat
   * @param {number} lng
   * @returns {Promise<Object|null>} { corregimiento_id, corregimiento, veredas } o null
   */
  async buscarCorregimientoPorCoordenadas(lat, lng) {
    const { data, error } = await supabase
      .rpc('get_corregimiento_por_coordenadas', { lat, lng });

    if (error) throw new Error(`Error al buscar corregimiento por coordenadas: ${error.message}`);
    if (!data || data.length === 0) return null;
    return data[0];
  }

  /**
   * Busca veredas y corregimientos por texto (búsqueda fuzzy).
   * @param {string} texto
   * @returns {Promise<Array>} [{ nombre, tipo: 'corregimiento'|'vereda', corregimiento_nombre? }]
   */
  async buscarVeredaCorregimiento(texto) {
    const term = `%${texto}%`;

    // Buscar en corregimientos
    const { data: corrs, error: e1 } = await supabase
      .from('corregimientos')
      .select('id, nombre')
      .ilike('nombre', term)
      .limit(5);

    if (e1) throw new Error(`Error buscando corregimientos: ${e1.message}`);

    // Buscar en veredas con join al corregimiento
    const { data: veredas, error: e2 } = await supabase
      .from('veredas')
      .select('id, nombre, corregimiento_id, corregimientos(nombre)')
      .ilike('nombre', term)
      .limit(5);

    if (e2) throw new Error(`Error buscando veredas: ${e2.message}`);

    const resultados = [
      ...corrs.map(c => ({ nombre: c.nombre, tipo: 'corregimiento', id: c.id })),
      ...veredas.map(v => ({ nombre: v.nombre, tipo: 'vereda', id: v.id, corregimiento_nombre: v.corregimientos?.nombre })),
    ];

    return resultados;
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
  async findForMapFiltered({ comunas, franjas, tipos, fechaDesde, fechaHasta, corregimientos, zonaTipo } = {}) {
    let query = supabase
      .from('reportes')
      .select('id, latitud, longitud, tipo_hurto, franja_horaria, fecha_incidente, barrio_ingresado, comuna, zona_tipo, corregimiento_id, vereda_id')
      .eq('estado', 'activo')
      .order('fecha_creacion', { ascending: false });

    if (zonaTipo)               query = query.eq('zona_tipo', zonaTipo);
    if (comunas?.length)        query = query.in('comuna', comunas);
    if (corregimientos?.length) query = query.in('corregimiento_id', corregimientos);
    if (franjas?.length)        query = query.in('franja_horaria', franjas);
    if (tipos?.length)          query = query.in('tipo_hurto', tipos);
    if (fechaDesde)             query = query.gte('fecha_incidente', fechaDesde);
    if (fechaHasta)             query = query.lte('fecha_incidente', fechaHasta);

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

  /**
   * Lista reportes para el panel admin con filtros y paginación.
   */
  async findForAdmin({ page = 1, limit = 10, tipo_hurto, estado, fechaDesde, fechaHasta, comuna, zona_tipo, corregimiento_id, busqueda } = {}) {
    const from = (page - 1) * limit;
    const to   = from + limit - 1;

    let query = supabase
      .from('reportes')
      .select('id, tipo_hurto, tipo_reportante, franja_horaria, fecha_incidente, barrio_ingresado, comuna, estado, fecha_creacion, descripcion, objeto_hurtado, numero_agresores, latitud, longitud, zona_tipo, corregimiento_id, usuario_id', { count: 'exact' })
      .order('fecha_creacion', { ascending: false })
      .range(from, to);

    // Si se filtra por un estado específico, usar ese; si no, excluir eliminados por defecto
    if (estado)     query = query.eq('estado', estado);
    else            query = query.neq('estado', 'eliminado');

    if (tipo_hurto)       query = query.eq('tipo_hurto', tipo_hurto);
    if (fechaDesde)       query = query.gte('fecha_incidente', fechaDesde);
    if (fechaHasta)       query = query.lte('fecha_incidente', fechaHasta);
    if (comuna)           query = query.eq('comuna', Number(comuna));
    if (zona_tipo)        query = query.eq('zona_tipo', zona_tipo);
    if (corregimiento_id) query = query.eq('corregimiento_id', Number(corregimiento_id));

    const { data, error, count } = await query;
    if (error) throw new Error(`Error al obtener reportes admin: ${error.message}`);

    // Enriquecer con username y nombre de corregimiento
    const userIds = [...new Set(data.map(r => r.usuario_id).filter(Boolean))];
    const corrIds = [...new Set(data.map(r => r.corregimiento_id).filter(Boolean))];

    let userMap = {};
    let corrMap = {};

    if (userIds.length > 0) {
      const { data: users } = await supabase.from('usuarios').select('id, username').in('id', userIds);
      if (users) users.forEach(u => { userMap[u.id] = u.username; });
    }
    if (corrIds.length > 0) {
      const { data: corrs } = await supabase.from('corregimientos').select('id, nombre').in('id', corrIds);
      if (corrs) corrs.forEach(c => { corrMap[c.id] = c.nombre; });
    }

    const enriched = data.map(r => ({
      ...r,
      username: userMap[r.usuario_id] || null,
      corregimiento_nombre: corrMap[r.corregimiento_id] || null,
    }));

    // Filtrar por búsqueda (barrio, username o corregimiento)
    let filtered = enriched;
    if (busqueda) {
      const term = busqueda.toLowerCase();
      filtered = enriched.filter(r => {
        const username = r.username || '';
        const barrio = r.barrio_ingresado || '';
        const corr = r.corregimiento_nombre || '';
        return username.toLowerCase().includes(term) || barrio.toLowerCase().includes(term) || corr.toLowerCase().includes(term);
      });
    }

    return { data: filtered, total: busqueda ? filtered.length : count, page, totalPages: Math.ceil((busqueda ? filtered.length : count) / limit) };
  }

  /**
   * Retorna conteos de reportes agrupados por tipo y estado para el dashboard.
   */
  async getResumen(zonaTipo) {
    let query = supabase
      .from('reportes')
      .select('tipo_hurto, estado, comuna, franja_horaria, fecha_incidente, corregimiento_id')
      .neq('estado', 'eliminado');

    if (zonaTipo) query = query.eq('zona_tipo', zonaTipo);

    const { data, error } = await query;

    if (error) throw new Error(`Error al obtener resumen: ${error.message}`);

    // Obtener nombres de corregimientos
    const { data: corregimientos } = await supabase.from('corregimientos').select('id, nombre');
    const corrNombres = {};
    if (corregimientos) corregimientos.forEach(c => { corrNombres[c.id] = c.nombre; });

    const total       = data.length;
    const porTipo     = {};
    const porEstado   = {};
    const porComuna   = {};
    const porFranja   = {};
    const porFecha    = {};
    const porCorregimiento = {};
    const recientes   = [];

    // Ordenar por fecha descendente para obtener los más recientes
    const sorted = [...data].sort((a, b) => (b.fecha_incidente || '').localeCompare(a.fecha_incidente || ''));

    for (const r of sorted) {
      porTipo[r.tipo_hurto]       = (porTipo[r.tipo_hurto] || 0) + 1;
      porEstado[r.estado]         = (porEstado[r.estado] || 0) + 1;
      if (r.comuna) porComuna[r.comuna] = (porComuna[r.comuna] || 0) + 1;
      if (r.franja_horaria) porFranja[r.franja_horaria] = (porFranja[r.franja_horaria] || 0) + 1;
      if (r.fecha_incidente) porFecha[r.fecha_incidente] = (porFecha[r.fecha_incidente] || 0) + 1;
      if (r.corregimiento_id) {
        const nombre = corrNombres[r.corregimiento_id] || `Corr. ${r.corregimiento_id}`;
        porCorregimiento[nombre] = (porCorregimiento[nombre] || 0) + 1;
      }
      if (recientes.length < 5) recientes.push(r);
    }

    return { total, porTipo, porEstado, porComuna, porFranja, porFecha, porCorregimiento, recientes };
  }

  /**
   * Estadísticas de reportes por período agrupadas por fecha_incidente.
   * @param {string} fechaDesde  - YYYY-MM-DD
   * @param {string} fechaHasta  - YYYY-MM-DD
   * @param {string} agruparPor  - 'dia' | 'semana' | 'mes'
   */
  async getEstadisticasPorPeriodo({ fechaDesde, fechaHasta, agruparPor = 'dia' } = {}) {
    let query = supabase
      .from('reportes')
      .select('fecha_incidente, tipo_hurto')
      .eq('estado', 'activo');

    if (fechaDesde) query = query.gte('fecha_incidente', fechaDesde);
    if (fechaHasta) query = query.lte('fecha_incidente', fechaHasta);

    const { data, error } = await query;
    if (error) throw new Error(`Error al obtener estadísticas: ${error.message}`);

    // Agrupar en JS según el período solicitado
    const grupos = {};
    for (const r of data) {
      const fecha = new Date(r.fecha_incidente);
      let clave;

      if (agruparPor === 'mes') {
        clave = `${fecha.getFullYear()}-${String(fecha.getMonth() + 1).padStart(2, '0')}`;
      } else if (agruparPor === 'semana') {
        // Número de semana ISO
        const inicio = new Date(fecha.getFullYear(), 0, 1);
        const semana = Math.ceil(((fecha - inicio) / 86400000 + inicio.getDay() + 1) / 7);
        clave = `${fecha.getFullYear()}-S${String(semana).padStart(2, '0')}`;
      } else {
        clave = r.fecha_incidente;
      }

      if (!grupos[clave]) grupos[clave] = { periodo: clave, total: 0, porTipo: {} };
      grupos[clave].total++;
      grupos[clave].porTipo[r.tipo_hurto] = (grupos[clave].porTipo[r.tipo_hurto] || 0) + 1;
    }

    return Object.values(grupos).sort((a, b) => a.periodo.localeCompare(b.periodo));
  }

  /**
   * Compara conteos entre dos períodos para calcular tendencia.
   * @param {string} p1Desde - Período 1 inicio
   * @param {string} p1Hasta - Período 1 fin
   * @param {string} p2Desde - Período 2 inicio
   * @param {string} p2Hasta - Período 2 fin
   */
  async getComparacionPeriodos({ p1Desde, p1Hasta, p2Desde, p2Hasta }) {
    const [r1, r2] = await Promise.all([
      supabase.from('reportes').select('tipo_hurto', { count: 'exact' })
        .eq('estado', 'activo').gte('fecha_incidente', p1Desde).lte('fecha_incidente', p1Hasta),
      supabase.from('reportes').select('tipo_hurto', { count: 'exact' })
        .eq('estado', 'activo').gte('fecha_incidente', p2Desde).lte('fecha_incidente', p2Hasta),
    ]);

    if (r1.error) throw new Error(r1.error.message);
    if (r2.error) throw new Error(r2.error.message);

    const total1 = r1.count ?? 0;
    const total2 = r2.count ?? 0;
    const diferencia  = total2 - total1;
    const porcentaje  = total1 > 0 ? ((diferencia / total1) * 100).toFixed(1) : null;
    const tendencia   = diferencia > 0 ? 'incremento' : diferencia < 0 ? 'decremento' : 'estable';

    // Conteo por tipo en cada período
    const porTipo1 = {}, porTipo2 = {};
    for (const r of r1.data) porTipo1[r.tipo_hurto] = (porTipo1[r.tipo_hurto] || 0) + 1;
    for (const r of r2.data) porTipo2[r.tipo_hurto] = (porTipo2[r.tipo_hurto] || 0) + 1;

    return {
      periodo1: { desde: p1Desde, hasta: p1Hasta, total: total1, porTipo: porTipo1 },
      periodo2: { desde: p2Desde, hasta: p2Hasta, total: total2, porTipo: porTipo2 },
      diferencia, porcentaje, tendencia,
    };
  }

  /**
   * Retorna el top N de zonas con más hurtos, ordenado de mayor a menor.
   * @param {number} top         - Límite de resultados (default 10)
   * @param {string} fechaDesde  - Filtro opcional YYYY-MM-DD
   * @param {string} fechaHasta  - Filtro opcional YYYY-MM-DD
   */
  async getTopZonas({ top = 10, fechaDesde, fechaHasta } = {}) {
    let query = supabase
      .from('reportes')
      .select('barrio_ingresado, comuna')
      .eq('estado', 'activo');

    if (fechaDesde) query = query.gte('fecha_incidente', fechaDesde);
    if (fechaHasta) query = query.lte('fecha_incidente', fechaHasta);

    const { data, error } = await query;
    if (error) throw new Error(`Error al obtener top zonas: ${error.message}`);

    // Agrupar por barrio+comuna en JS
    const mapa = {};
    for (const r of data) {
      const clave = `${r.barrio_ingresado}||${r.comuna ?? ''}`;
      if (!mapa[clave]) {
        mapa[clave] = {
          barrio:  r.barrio_ingresado,
          comuna:  r.comuna,
          total:   0,
        };
      }
      mapa[clave].total++;
    }

    return Object.values(mapa)
      .sort((a, b) => b.total - a.total)
      .slice(0, Number(top));
  }

  /**
   * Obtiene todos los reportes de un usuario específico.
   */
  async findByUsuario(usuarioId) {
    const { data, error } = await supabase
      .from('reportes')
      .select('*, zonas(barrio)')
      .eq('usuario_id', usuarioId)
      .neq('estado', 'eliminado')
      .order('fecha_creacion', { ascending: false });

    if (error) throw new Error(`Error al obtener reportes del usuario: ${error.message}`);
    return data;
  }

  /**
   * Obtiene un reporte por ID verificando que pertenezca al usuario.
   */
  async findByIdAndUsuario(id, usuarioId) {
    const { data, error } = await supabase
      .from('reportes')
      .select('*, zonas(barrio)')
      .eq('id', id)
      .eq('usuario_id', usuarioId)
      .maybeSingle();

    if (error) throw new Error(`Error al buscar reporte: ${error.message}`);
    return data;
  }

  /**
   * Actualiza campos editables de un reporte propio.
   * Solo permite editar reportes activos.
   */
  async updateOwn(id, usuarioId, data) {
    const { data: updated, error } = await supabase
      .from('reportes')
      .update({
        ...data,
        fecha_actualizacion: new Date().toISOString(),
      })
      .eq('id', id)
      .eq('usuario_id', usuarioId)
      .eq('estado', 'activo')
      .select()
      .single();

    if (error) throw new Error(`Error al actualizar reporte: ${error.message}`);
    return updated;
  }

  /**
   * Crea una solicitud de eliminación para un reporte.
   * La BD previene duplicados pendientes con un índice único.
   */
  async crearSolicitudEliminacion(reporteId, usuarioId, motivo) {
    const { data, error } = await supabase
      .from('solicitudes_eliminacion')
      .insert({
        reporte_id:  reporteId,
        usuario_id:  usuarioId,
        motivo:      motivo ?? null,
        estado_solicitud: 'pendiente',
      })
      .select()
      .single();

    if (error) {
      if (error.code === '23505')
        throw new Error('Ya existe una solicitud de eliminación pendiente para este reporte');
      throw new Error(`Error al crear solicitud: ${error.message}`);
    }
    return data;
  }

  /**
   * Stats públicas para la pantalla de login del admin.
   * Retorna conteos de reportes activos, usuarios, corregimientos y comunas.
   */
  async getStatsLogin() {
    const [reportesRes, usuariosRes, corregimientosRes] = await Promise.all([
      supabase.from('reportes').select('id', { count: 'exact', head: true }).eq('estado', 'activo'),
      supabase.from('usuarios').select('id', { count: 'exact', head: true }),
      supabase.from('corregimientos').select('id', { count: 'exact', head: true }),
    ]);

    return {
      reportes: reportesRes.count ?? 0,
      usuarios: usuariosRes.count ?? 0,
      corregimientos: corregimientosRes.count ?? 0,
      comunas: 12,
    };
  }
}
