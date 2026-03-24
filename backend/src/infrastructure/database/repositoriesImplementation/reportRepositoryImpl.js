// src/infrastructure/database/repositoriesImplementation/ReportRepositoryImpl.js

import supabase from '../dbScript/db.js';

export default class ReportRepositoryImpl {

  async create(data) {
    const { data: newRow, error } = await supabase
      .from('reportes')
      .insert([
        {
          usuario_id: data.usuario_id,
          tipo_reportante: data.tipo_reportante,
          fecha_incidente: data.fecha_incidente,
          franja_horaria: data.franja_horaria,
          latitud: data.latitud,
          longitud: data.longitud,
          direccion: data.direccion,
          comuna: data.comuna,
          tipo_hurto: data.tipo_hurto,
          descripcion: data.descripcion,
          objeto_hurtado: data.objeto_hurtado,
          numero_agresores: data.numero_agresores,
          estado: 'activo'
        }
      ])
      .select();

    if (error) throw error;

    return newRow[0];
  }


  async findAll() {
    const { data, error } = await supabase
      .from('reportes')
      .select('*')
      .neq('estado', 'eliminado')
      .order('fecha_creacion', { ascending: false });

    if (error) throw error;

    return data;
  }


  async findById(id) {
    const { data, error } = await supabase
      .from('reportes')
      .select('*')
      .eq('id', id)
      .single();

    if (error) throw error;

    return data;
  }

}