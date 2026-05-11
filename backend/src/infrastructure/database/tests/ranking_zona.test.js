import { jest, describe, beforeEach, test, expect } from '@jest/globals';

jest.unstable_mockModule('../dbScript/db.js', () => ({
  default: {
    from: jest.fn(),
  },
}));

const supabase = (await import('../dbScript/db.js')).default;
const { default: ReportRepositoryImpl } = await import('../repositoriesImplementation/reportRepositoryImpl.js');
const { default: ReportController } = await import('../../../interfaces/controllers/reportController.js');

describe('HU-12 Backend - Ranking de zonas', () => {
  let repository;
  let controller;
  let req;
  let res;

  const rawData = [
    { barrio_ingresado: 'Centro', comuna: 1 },
    { barrio_ingresado: 'Centro', comuna: 1 },
    { barrio_ingresado: 'La Minga', comuna: 2 },
    { barrio_ingresado: 'La Minga', comuna: 2 },
    { barrio_ingresado: 'La Minga', comuna: 2 },
    { barrio_ingresado: 'Obrero', comuna: 3 },
  ];

  const rankingDesc = [
    { barrio: 'La Minga', comuna: 2, total: 3 },
    { barrio: 'Centro', comuna: 1, total: 2 },
    { barrio: 'Obrero', comuna: 3, total: 1 },
  ];

  beforeEach(() => {
    jest.clearAllMocks();
    repository = new ReportRepositoryImpl();
    controller = new ReportController(repository);
    req = { query: {} };
    res = {
      status: jest.fn().mockReturnThis(),
      json: jest.fn(),
    };
  });

  function mockQuery(data, error = null) {
    const result = { data, error };

    const query = {
      select: jest.fn().mockReturnThis(),
      eq: jest.fn().mockReturnThis(),
      gte: jest.fn().mockReturnThis(),
      lte: jest.fn().mockReturnThis(),
      order: jest.fn().mockReturnThis(),
      then: (resolve, reject) => Promise.resolve(result).then(resolve, reject),
      catch: (reject) => Promise.resolve(result).catch(reject),
      finally: (cb) => Promise.resolve(result).finally(cb),
    };

    supabase.from.mockReturnValue(query);
    return query;
  }

  function printOk(name) {
    console.log(`✅ PASS: ${name}`);
  }

  test('CP-HU12-BE-01 obtiene ranking de zonas con datos válidos', async () => {
    mockQuery(rawData);

    const result = await repository.getTopZonas({
      top: 3,
      fechaDesde: '2026-04-01',
      fechaHasta: '2026-04-30',
    });

    expect(supabase.from).toHaveBeenCalledWith('reportes');
    expect(result).toEqual(rankingDesc);
    printOk('CP-HU12-BE-01 obtiene ranking de zonas con datos válidos');
  });

  test('CP-HU12-BE-02 ordena de mayor a menor por total', async () => {
    mockQuery(rawData);

    const result = await repository.getTopZonas({ top: 3 });

    expect(result[0].total).toBe(3);
    expect(result[1].total).toBe(2);
    expect(result[2].total).toBe(1);
    printOk('CP-HU12-BE-02 ordena de mayor a menor por total');
  });

  test('CP-HU12-BE-03 aplica límite top correctamente', async () => {
    mockQuery(rawData);

    const result = await repository.getTopZonas({ top: 2 });

    expect(result).toHaveLength(2);
    expect(result[0].barrio).toBe('La Minga');
    expect(result[1].barrio).toBe('Centro');
    printOk('CP-HU12-BE-03 aplica límite top correctamente');
  });

  test('CP-HU12-BE-04 filtra por fechaDesde y fechaHasta', async () => {
    const query = mockQuery(rawData);

    await repository.getTopZonas({
      top: 3,
      fechaDesde: '2026-04-01',
      fechaHasta: '2026-04-30',
    });

    expect(query.gte).toHaveBeenCalledWith('fecha_incidente', '2026-04-01');
    expect(query.lte).toHaveBeenCalledWith('fecha_incidente', '2026-04-30');
    printOk('CP-HU12-BE-04 filtra por fechaDesde y fechaHasta');
  });

  test('CP-HU12-BE-05 devuelve lista vacía si no hay reportes', async () => {
    mockQuery([]);

    const result = await repository.getTopZonas({ top: 3 });

    expect(result).toEqual([]);
    printOk('CP-HU12-BE-05 devuelve lista vacía si no hay reportes');
  });

  test('CP-HU12-BE-06 lanza error si Supabase falla', async () => {
    mockQuery(null, { message: 'db failure' });

    await expect(repository.getTopZonas({ top: 3 })).rejects.toThrow(
      'Error al obtener top zonas: db failure',
    );
    printOk('CP-HU12-BE-06 lanza error si Supabase falla');
  });

  test('CP-HU12-BE-07 controller responde 200 con ranking', async () => {
    mockQuery(rawData);

    req.query = { top: '3', fechaDesde: '2026-04-01', fechaHasta: '2026-04-30' };

    await controller.getTopZonas(req, res);

    expect(res.status).toHaveBeenCalledWith(200);
    expect(res.json).toHaveBeenCalledWith({
      success: true,
      data: rankingDesc,
    });
    printOk('CP-HU12-BE-07 controller responde 200 con ranking');
  });

  test('CP-HU12-BE-08 controller usa top=10 por defecto', async () => {
    mockQuery(rawData);

    req.query = {};

    await controller.getTopZonas(req, res);

    expect(res.status).toHaveBeenCalledWith(200);
    expect(res.json).toHaveBeenCalledWith({
      success: true,
      data: rankingDesc,
    });
    printOk('CP-HU12-BE-08 controller usa top=10 por defecto');
  });

  test('CP-HU12-BE-09 controller responde 400 si top es inválido', async () => {
    req.query = { top: 'abc' };

    await controller.getTopZonas(req, res);

    expect(res.status).toHaveBeenCalledWith(400);
    expect(res.json).toHaveBeenCalledWith({
      success: false,
      message: 'top debe ser un número entre 1 y 50',
    });
    printOk('CP-HU12-BE-09 controller responde 400 si top es inválido');
  });

  test('CP-HU12-BE-10 controller responde 500 si el repository falla', async () => {
    mockQuery(null, { message: 'db failure' });

    req.query = { top: '3' };

    await controller.getTopZonas(req, res);

    expect(res.status).toHaveBeenCalledWith(500);
    expect(res.json).toHaveBeenCalledWith({
      success: false,
      message: 'Error al obtener top zonas: db failure',
    });
    printOk('CP-HU12-BE-10 controller responde 500 si el repository falla');
  });
});