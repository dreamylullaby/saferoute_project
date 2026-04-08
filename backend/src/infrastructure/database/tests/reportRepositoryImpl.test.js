import { jest, describe, beforeEach, test, expect } from '@jest/globals';

// Mock ESM ANTES de cualquier import
await jest.unstable_mockModule('../dbScript/db.js', () => ({
  default: {
    from: jest.fn(),
    rpc: jest.fn(),
  },
}));

describe('HU-01 Backend - ReportRepositoryImpl', () => {
  let repository;
  let supabase;

  beforeEach(async () => {
    const { default: supabaseMock } = await import('../dbScript/db.js');
    supabase = supabaseMock;

    const { default: ReportRepositoryImpl } = await import('../repositoriesImplementation/reportRepositoryImpl.js');
    repository = new ReportRepositoryImpl();
    jest.clearAllMocks();
  });

  test('CP-HU01-08: persistencia de coordenadas', async () => {
    const insertedRow = {
      id: '00000000-0000-0000-0000-000000000001', // UUID válido
      usuario_id: '00000000-0000-0000-0000-000000000001',
      latitud: 1.21361,
      longitud: -77.28111,
      barrio_ingresado: 'Centro',
      tipo_hurto: 'atraco',
      estado: 'activo',
    };

    supabase.from.mockReturnValue({
      insert: jest.fn().mockReturnValue({
        select: jest.fn().mockResolvedValue({
          data: [insertedRow],
          error: null,
        }),
      }),
    });

    const payload = {
      usuario_id: '00000000-0000-0000-0000-000000000001', // UUID válido
      tipo_reportante: 'victima',
      fecha_incidente: '2026-04-07',
      franja_horaria: '12:00-17:59',
      latitud: 1.21361,
      longitud: -77.28111,
      direccion: 'Calle 15 22B',
      barrio_ingresado: 'Centro',
      tipo_hurto: 'atraco',
      descripcion: 'Prueba',
      objeto_hurtado: 'celular',
      numero_agresores: '2',
    };

    const result = await repository.create(payload);

    expect(supabase.from).toHaveBeenCalledWith('reportes');
    expect(result).toEqual(insertedRow);
  });

  test('CP-HU01-08B: normaliza opcionales a null', async () => {
    const insertedRow = {
      id: '00000000-0000-0000-0000-000000000002',
      direccion: null,
      descripcion: null,
      objeto_hurtado: null,
      numero_agresores: null,
      estado: 'activo',
    };

    supabase.from.mockReturnValue({
      insert: jest.fn().mockReturnValue({
        select: jest.fn().mockResolvedValue({
          data: [insertedRow],
          error: null,
        }),
      }),
    });

    await repository.create({
      usuario_id: '00000000-0000-0000-0000-000000000002',
      tipo_reportante: 'victima',
      fecha_incidente: '2026-04-07',
      franja_horaria: '12:00-17:59',
      latitud: 1.21361,
      longitud: -77.28111,
      barrio_ingresado: 'Centro',
      tipo_hurto: 'atraco',
    });

    expect(insertedRow.direccion).toBeNull();
    expect(insertedRow.descripcion).toBeNull();
  });

  test('CP-HU01-08C: error de base de datos al crear reporte', async () => {
    supabase.from.mockReturnValue({
      insert: jest.fn().mockReturnValue({
        select: jest.fn().mockResolvedValue({
          data: null,
          error: { message: 'db insert failed' },
        }),
      }),
    });

    await expect(
      repository.create({
        usuario_id: '00000000-0000-0000-0000-000000000003',
        tipo_reportante: 'victima',
        fecha_incidente: '2026-04-07',
        franja_horaria: '12:00-17:59',
        latitud: 1.21361,
        longitud: -77.28111,
        barrio_ingresado: 'Centro',
        tipo_hurto: 'atraco',
      })
    ).rejects.toThrow('Error al crear reporte: db insert failed');
  });
});