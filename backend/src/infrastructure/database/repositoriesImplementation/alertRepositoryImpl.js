// src/infrastructure/database/repositoriesImplementation/alertRepositoryImpl.js

import supabase from '../dbScript/db.js';
import AlertRepository from '../../../domain/repositories/alertRepository.js';

/**
 * @class AlertRepositoryImpl
 * @extends AlertRepository
 * @classdesc Implementación concreta usando Supabase.
 * Maneja configuracion_alertas y alertas.
 */
export default class AlertRepositoryImpl extends AlertRepository {

  /**
   * Obtiene la configuración de alertas de un usuario.
   */
  async findConfigByUsuario(usuarioId) {
    const { data, error } = await supabase
      .from('configuracion_alertas')
      .select('*')
      .eq('usuario_id', usuarioId)
      .maybeSingle();

    if (error) throw new Error(`Error al obtener configuración: ${error.message}`);
    return data;
  }

  /**
   * Crea o actualiza la configuración de alertas (upsert por usuario_id).
   */
  async upsertConfig(usuarioId, radioMetros, activo) {
    const { data, error } = await supabase
      .from('configuracion_alertas')
      .upsert(
        {
          usuario_id:          usuarioId,
          radio_metros:        radioMetros,
          activo:              activo,
          fecha_actualizacion: new Date().toISOString(),
        },
        { onConflict: 'usuario_id' }
      )
      .select()
      .single();

    if (error) throw new Error(`Error al guardar configuración: ${error.message}`);
    return data;
  }

  /**
   * Busca reportes activos cercanos usando la fórmula de Haversine en JS.
   * Filtra reportes de las últimas 24h para no saturar resultados.
   *
   * Haversine: calcula distancia en metros entre dos puntos geográficos.
   */
  async findReportesCercanos(latitud, longitud, radioMetros) {
    const hace24h = new Date(Date.now() - 24 * 60 * 60 * 1000).toISOString();

    const { data, error } = await supabase
      .from('reportes')
      .select('id, latitud, longitud, tipo_hurto, franja_horaria, fecha_incidente, barrio_ingresado, fecha_creacion')
      .eq('estado', 'activo')
      .gte('fecha_creacion', hace24h);

    if (error) throw new Error(`Error al buscar reportes cercanos: ${error.message}`);

    // Calcular distancia con Haversine y filtrar por radio
    return data
      .map(r => ({ ...r, distancia_metros: haversine(latitud, longitud, r.latitud, r.longitud) }))
      .filter(r => r.distancia_metros <= radioMetros)
      .sort((a, b) => a.distancia_metros - b.distancia_metros);
  }

  /**
   * Lista alertas no leídas del usuario con datos del reporte asociado.
   */
  async findNoLeidasByUsuario(usuarioId) {
    const { data, error } = await supabase
      .from('alertas')
      .select('id, distancia_metros, leida, fecha_creacion, reportes(id, tipo_hurto, barrio_ingresado, latitud, longitud, fecha_incidente)')
      .eq('usuario_id', usuarioId)
      .eq('leida', false)
      .order('fecha_creacion', { ascending: false });

    if (error) throw new Error(`Error al obtener alertas: ${error.message}`);
    return data;
  }

  /**
   * Marca una alerta como leída, verificando que pertenezca al usuario.
   */
  async marcarLeida(alertaId, usuarioId) {
    const { data: existing } = await supabase
      .from('alertas')
      .select('id')
      .eq('id', alertaId)
      .eq('usuario_id', usuarioId)
      .maybeSingle();

    if (!existing) throw new Error('Alerta no encontrada o no pertenece al usuario');

    const { data, error } = await supabase
      .from('alertas')
      .update({ leida: true, fecha_leida: new Date().toISOString() })
      .eq('id', alertaId)
      .select()
      .single();

    if (error) throw new Error(`Error al marcar alerta: ${error.message}`);
    return data;
  }
}

// ── Haversine ────────────────────────────────────────────────────────────────
/**
 * Calcula la distancia en metros entre dos coordenadas geográficas.
 * @param {number} lat1
 * @param {number} lon1
 * @param {number} lat2
 * @param {number} lon2
 * @returns {number} Distancia en metros
 */
function haversine(lat1, lon1, lat2, lon2) {
  const R = 6371000; // radio de la Tierra en metros
  const toRad = deg => deg * Math.PI / 180;
  const dLat = toRad(lat2 - lat1);
  const dLon = toRad(lon2 - lon1);
  const a =
    Math.sin(dLat / 2) ** 2 +
    Math.cos(toRad(lat1)) * Math.cos(toRad(lat2)) * Math.sin(dLon / 2) ** 2;
  return R * 2 * Math.atan2(Math.sqrt(a), Math.sqrt(1 - a));
}
