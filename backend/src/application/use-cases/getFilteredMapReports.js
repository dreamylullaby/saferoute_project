// src/application/use-cases/getFilteredMapReports.js

import Report from '../../domain/entities/Report.js';

/**
 * @class GetFilteredMapReports
 * @classdesc Caso de uso para obtener reportes del mapa aplicando filtros combinados.
 * Soporta filtrado por comuna, franja horaria, tipo de hurto y rango de fechas.
 */
class GetFilteredMapReports {

  /**
   * @param {import('../../domain/repositories/reportRepository.js').default} reportRepository
   */
  constructor(reportRepository) {
    this.reportRepository = reportRepository;
  }

  /**
   * @param {Object}   filtros
   * @param {number[]} [filtros.comunas]      - Lista de comunas (1-12)
   * @param {string[]} [filtros.franjas]      - Franjas horarias válidas
   * @param {string[]} [filtros.tipos]        - Tipos de hurto válidos
   * @param {string}   [filtros.fechaDesde]   - ISO date string (YYYY-MM-DD)
   * @param {string}   [filtros.fechaHasta]   - ISO date string (YYYY-MM-DD)
   * @returns {Promise<Object[]>} Reportes filtrados para el mapa
   */
  async execute(filtros = {}) {
    const { comunas, franjas, tipos, fechaDesde, fechaHasta } = filtros;

    // Validar franjas
    if (franjas?.length) {
      const invalidas = franjas.filter(f => !Report.franja_horaria.includes(f));
      if (invalidas.length)
        throw new Error(`Franjas inválidas: ${invalidas.join(', ')}. Válidas: ${Report.franja_horaria.join(', ')}`);
    }

    // Validar tipos
    if (tipos?.length) {
      const invalidos = tipos.filter(t => !Report.tipo_hurto.includes(t));
      if (invalidos.length)
        throw new Error(`Tipos de hurto inválidos: ${invalidos.join(', ')}. Válidos: ${Report.tipo_hurto.join(', ')}`);
    }

    // Validar comunas
    if (comunas?.length) {
      const invalidas = comunas.filter(c => c < 1 || c > 12);
      if (invalidas.length)
        throw new Error(`Comunas inválidas: ${invalidas.join(', ')}. Rango permitido: 1-12`);
    }

    return await this.reportRepository.findForMapFiltered({ comunas, franjas, tipos, fechaDesde, fechaHasta });
  }
}

export default GetFilteredMapReports;
