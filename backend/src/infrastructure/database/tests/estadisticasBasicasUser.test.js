import { jest } from '@jest/globals';

const mockSupabase = {
  from: jest.fn(),
  rpc: jest.fn(),
};

await jest.unstable_mockModule('../dbScript/db.js', () => ({
  __esModule: true,
  default: mockSupabase,
}));

const { default: ReportRepositoryImpl } = await import('../repositoriesImplementation/ReportRepositoryImpl.js');

function createChainableThenable(result) {
  const chain = {
    select: jest.fn().mockReturnThis(),
    eq: jest.fn().mockReturnThis(),
    neq: jest.fn().mockReturnThis(),
    gt: jest.fn().mockReturnThis(),
    gte: jest.fn().mockReturnThis(),
    lte: jest.fn().mockReturnThis(),
    in: jest.fn().mockReturnThis(),
    ilike: jest.fn().mockReturnThis(),
    order: jest.fn().mockReturnThis(),
    limit: jest.fn().mockReturnThis(),
    range: jest.fn().mockReturnThis(),
    insert: jest.fn().mockReturnThis(),
    maybeSingle: jest.fn().mockResolvedValue(result),
    single: jest.fn().mockResolvedValue(result),
    then: (resolve, reject) => Promise.resolve(result).then(resolve, reject),
  };
  return chain;
}

describe('HU-11 ReportRepositoryImpl estadísticas', () => {
  let repository;

  beforeEach(() => {
    repository = new ReportRepositoryImpl();
    jest.clearAllMocks();
  });

  test('CP-HU11-03 recalcula estadisticas tras nuevos reportes', async () => {
    const initialData = [
      { fecha_incidente: '2026-05-15', tipo_hurto: 'atraco' },
      { fecha_incidente: '2026-05-20', tipo_hurto: 'raponazo' },
    ];

    const updatedData = [
      ...initialData,
      { fecha_incidente: '2026-05-21', tipo_hurto: 'atraco' },
      { fecha_incidente: '2026-05-22', tipo_hurto: 'fleteo' },
    ];

    mockSupabase.from
      .mockReturnValueOnce(createChainableThenable({ data: initialData, error: null }))
      .mockReturnValueOnce(createChainableThenable({ data: updatedData, error: null }));

    const before = await repository.getEstadisticasPorPeriodo({
      fechaDesde: '2026-05-01',
      fechaHasta: '2026-05-31',
      agruparPor: 'mes',
    });

    const after = await repository.getEstadisticasPorPeriodo({
      fechaDesde: '2026-05-01',
      fechaHasta: '2026-05-31',
      agruparPor: 'mes',
    });

    expect(before).toHaveLength(1);
    expect(after).toHaveLength(1);
    expect(before[0].total).toBe(2);
    expect(after[0].total).toBe(4);
    expect(after[0].total).toBeGreaterThan(before[0].total);
  });

  test('CP-HU11-04 compara dos semanas consecutivas con aumento', async () => {
    const periodo1 = {
      data: [
        { tipo_hurto: 'atraco' },
        { tipo_hurto: 'raponazo' },
      ],
      count: 2,
      error: null,
    };

    const periodo2 = {
      data: [
        { tipo_hurto: 'atraco' },
        { tipo_hurto: 'atraco' },
        { tipo_hurto: 'raponazo' },
        { tipo_hurto: 'fleteo' },
      ],
      count: 4,
      error: null,
    };

    mockSupabase.from
      .mockReturnValueOnce(createChainableThenable(periodo1))
      .mockReturnValueOnce(createChainableThenable(periodo2));

    const result = await repository.getComparacionPeriodos({
      p1Desde: '2026-04-01',
      p1Hasta: '2026-04-07',
      p2Desde: '2026-04-08',
      p2Hasta: '2026-04-14',
    });

    expect(result.periodo1.total).toBe(2);
    expect(result.periodo2.total).toBe(4);
    expect(result.diferencia).toBe(2);
    expect(result.porcentaje).toBe('100.0');
    expect(result.tendencia).toBe('incremento');
  });

  test('CP-HU11-05 compara dos semanas consecutivas con disminucion', async () => {
    const periodo1 = {
      data: [
        { tipo_hurto: 'atraco' },
        { tipo_hurto: 'atraco' },
        { tipo_hurto: 'raponazo' },
        { tipo_hurto: 'fleteo' },
      ],
      count: 4,
      error: null,
    };

    const periodo2 = {
      data: [
        { tipo_hurto: 'atraco' },
      ],
      count: 1,
      error: null,
    };

    mockSupabase.from
      .mockReturnValueOnce(createChainableThenable(periodo1))
      .mockReturnValueOnce(createChainableThenable(periodo2));

    const result = await repository.getComparacionPeriodos({
      p1Desde: '2026-04-01',
      p1Hasta: '2026-04-07',
      p2Desde: '2026-04-08',
      p2Hasta: '2026-04-14',
    });

    expect(result.periodo1.total).toBe(4);
    expect(result.periodo2.total).toBe(1);
    expect(result.diferencia).toBe(-3);
    expect(result.porcentaje).toBe('-75.0');
    expect(result.tendencia).toBe('decremento');
  });

  test('CP-HU11-06 compara dos periodos sin cambio', async () => {
    const periodo1 = {
      data: [
        { tipo_hurto: 'atraco' },
        { tipo_hurto: 'raponazo' },
      ],
      count: 2,
      error: null,
    };

    const periodo2 = {
      data: [
        { tipo_hurto: 'atraco' },
        { tipo_hurto: 'fleteo' },
      ],
      count: 2,
      error: null,
    };

    mockSupabase.from
      .mockReturnValueOnce(createChainableThenable(periodo1))
      .mockReturnValueOnce(createChainableThenable(periodo2));

    const result = await repository.getComparacionPeriodos({
      p1Desde: '2026-04-01',
      p1Hasta: '2026-04-07',
      p2Desde: '2026-04-08',
      p2Hasta: '2026-04-14',
    });

    expect(result.periodo1.total).toBe(2);
    expect(result.periodo2.total).toBe(2);
    expect(result.diferencia).toBe(0);
    expect(result.porcentaje).toBe('0.0');
    expect(result.tendencia).toBe('estable');
  });

  test('CP-HU11-09 periodo anterior en cero evita division invalida', async () => {
    const periodo1 = {
      data: [],
      count: 0,
      error: null,
    };

    const periodo2 = {
      data: [
        { tipo_hurto: 'atraco' },
        { tipo_hurto: 'raponazo' },
        { tipo_hurto: 'fleteo' },
      ],
      count: 3,
      error: null,
    };

    mockSupabase.from
      .mockReturnValueOnce(createChainableThenable(periodo1))
      .mockReturnValueOnce(createChainableThenable(periodo2));

    const result = await repository.getComparacionPeriodos({
      p1Desde: '2026-04-01',
      p1Hasta: '2026-04-07',
      p2Desde: '2026-04-08',
      p2Hasta: '2026-04-14',
    });

    expect(result.periodo1.total).toBe(0);
    expect(result.periodo2.total).toBe(3);
    expect(result.diferencia).toBe(3);
    expect(result.porcentaje).toBeNull();
    expect(result.tendencia).toBe('incremento');
  });

  test('agrupa estadisticas por semana correctamente', async () => {
    const rows = [
      { fecha_incidente: '2026-04-15', tipo_hurto: 'atraco' },
      { fecha_incidente: '2026-04-16', tipo_hurto: 'atraco' },
      { fecha_incidente: '2026-04-24', tipo_hurto: 'raponazo' },
    ];

    mockSupabase.from.mockReturnValueOnce(
      createChainableThenable({ data: rows, error: null })
    );

    const result = await repository.getEstadisticasPorPeriodo({
      fechaDesde: '2026-04-01',
      fechaHasta: '2026-04-30',
      agruparPor: 'semana',
    });

    expect(result.length).toBeGreaterThan(0);
    expect(result[0]).toHaveProperty('periodo');
    expect(result[0]).toHaveProperty('total');
    expect(result[0]).toHaveProperty('porTipo');
  });

  test('agrupa estadisticas por mes correctamente', async () => {
    const rows = [
      { fecha_incidente: '2026-04-15', tipo_hurto: 'atraco' },
      { fecha_incidente: '2026-04-20', tipo_hurto: 'raponazo' },
      { fecha_incidente: '2026-05-15', tipo_hurto: 'atraco' },
    ];

    mockSupabase.from.mockReturnValueOnce(
      createChainableThenable({ data: rows, error: null })
    );

    const result = await repository.getEstadisticasPorPeriodo({
      fechaDesde: '2026-04-01',
      fechaHasta: '2026-05-31',
      agruparPor: 'mes',
    });

    expect(result).toHaveLength(2);
    expect(result[0].periodo).toBe('2026-04');
    expect(result[0].total).toBe(2);
    expect(result[1].periodo).toBe('2026-05');
    expect(result[1].total).toBe(1);
  });
});