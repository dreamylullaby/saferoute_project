import { jest } from '@jest/globals';
import GetFilteredMapReports from '../../../application/use-cases/getFilteredMapReports';

describe('HU-09 Backend - GetFilteredMapReports', () => {
  let mockReportRepository;
  let useCase;

  beforeEach(() => {
    mockReportRepository = {
      findForMapFiltered: jest.fn(),
    };

    useCase = new GetFilteredMapReports(mockReportRepository);
  });

  test('CP-HU09-BE-01: filtra hurtos por rango de fechas', async () => {
    const filtros = {
      fechaDesde: '2026-04-01',
      fechaHasta: '2026-04-10',
    };

    const respuestaMock = [
      {
        id: 1,
        tipo_hurto: 'atraco',
        comuna: 3,
        franja_horaria: '06:00-11:59',
        fecha_incidente: '2026-04-05',
      },
    ];

    mockReportRepository.findForMapFiltered.mockResolvedValue(respuestaMock);

    const result = await useCase.execute(filtros);

    expect(mockReportRepository.findForMapFiltered).toHaveBeenCalledWith({
      comunas: undefined,
      franjas: undefined,
      tipos: undefined,
      fechaDesde: '2026-04-01',
      fechaHasta: '2026-04-10',
    });

    expect(result).toEqual(respuestaMock);
    console.log('CP-HU09-BE-01 OK');
  });

  test('CP-HU09-BE-02: filtra hurtos por franja horaria válida', async () => {
    const filtros = {
      franjas: ['06:00-11:59'],
    };

    const respuestaMock = [
      {
        id: 2,
        tipo_hurto: 'raponazo',
        comuna: 2,
        franja_horaria: '06:00-11:59',
        fecha_incidente: '2026-04-08',
      },
    ];

    mockReportRepository.findForMapFiltered.mockResolvedValue(respuestaMock);

    const result = await useCase.execute(filtros);

    expect(mockReportRepository.findForMapFiltered).toHaveBeenCalledWith({
      comunas: undefined,
      franjas: ['06:00-11:59'],
      tipos: undefined,
      fechaDesde: undefined,
      fechaHasta: undefined,
    });

    expect(result).toEqual(respuestaMock);
    console.log('CP-HU09-BE-02 OK');
  });

  test('CP-HU09-BE-03: filtra hurtos por zona/comuna válida', async () => {
    const filtros = {
      comunas: [5],
    };

    const respuestaMock = [
      {
        id: 3,
        tipo_hurto: 'fleteo',
        comuna: 5,
        franja_horaria: '12:00-17:59',
        fecha_incidente: '2026-04-09',
      },
    ];

    mockReportRepository.findForMapFiltered.mockResolvedValue(respuestaMock);

    const result = await useCase.execute(filtros);

    expect(mockReportRepository.findForMapFiltered).toHaveBeenCalledWith({
      comunas: [5],
      franjas: undefined,
      tipos: undefined,
      fechaDesde: undefined,
      fechaHasta: undefined,
    });

    expect(result).toEqual(respuestaMock);
    console.log('CP-HU09-BE-03 OK');
  });

  test('CP-HU09-BE-04: combina filtros de fecha, horario y zona', async () => {
    const filtros = {
      comunas: [4],
      franjas: ['18:00-23:59'],
      fechaDesde: '2026-04-01',
      fechaHasta: '2026-04-30',
    };

    const respuestaMock = [
      {
        id: 4,
        tipo_hurto: 'cosquilleo',
        comuna: 4,
        franja_horaria: '18:00-23:59',
        fecha_incidente: '2026-04-14',
      },
    ];

    mockReportRepository.findForMapFiltered.mockResolvedValue(respuestaMock);

    const result = await useCase.execute(filtros);

    expect(mockReportRepository.findForMapFiltered).toHaveBeenCalledWith({
      comunas: [4],
      franjas: ['18:00-23:59'],
      tipos: undefined,
      fechaDesde: '2026-04-01',
      fechaHasta: '2026-04-30',
    });

    expect(result).toEqual(respuestaMock);
    console.log('CP-HU09-BE-04 OK');
  });

  test('CP-HU09-BE-05: retorna lista vacía cuando no hay datos para los filtros', async () => {
    const filtros = {
      comunas: [9],
      franjas: ['00:00-05:59'],
      fechaDesde: '2026-04-01',
      fechaHasta: '2026-04-02',
    };

    mockReportRepository.findForMapFiltered.mockResolvedValue([]);

    const result = await useCase.execute(filtros);

    expect(mockReportRepository.findForMapFiltered).toHaveBeenCalledWith({
      comunas: [9],
      franjas: ['00:00-05:59'],
      tipos: undefined,
      fechaDesde: '2026-04-01',
      fechaHasta: '2026-04-02',
    });

    expect(result).toEqual([]);
    console.log('CP-HU09-BE-05 OK');
  });

  test('CP-HU09-BE-06: lanza error cuando la franja horaria es inválida', async () => {
    const filtros = {
      franjas: ['madrugada'],
    };

    await expect(useCase.execute(filtros)).rejects.toThrow(/Franjas inválidas/i);
    expect(mockReportRepository.findForMapFiltered).not.toHaveBeenCalled();
    console.log('CP-HU09-BE-06 OK');
  });

  test('CP-HU09-BE-07: lanza error cuando el tipo de hurto es inválido', async () => {
    const filtros = {
      tipos: ['robo'],
    };

    await expect(useCase.execute(filtros)).rejects.toThrow(/Tipos de hurto inválidos/i);
    expect(mockReportRepository.findForMapFiltered).not.toHaveBeenCalled();
    console.log('CP-HU09-BE-07 OK');
  });

  test('CP-HU09-BE-08: lanza error cuando la comuna está fuera del rango permitido', async () => {
    const filtros = {
      comunas: [0, 13],
    };

    await expect(useCase.execute(filtros)).rejects.toThrow(/Comunas inválidas/i);
    expect(mockReportRepository.findForMapFiltered).not.toHaveBeenCalled();
    console.log('CP-HU09-BE-08 OK');
  });
});