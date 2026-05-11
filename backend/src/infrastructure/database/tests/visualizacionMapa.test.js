import { jest } from '@jest/globals';
import GetMapReports from '../../../application/use-cases/getMapReports.js';

describe('HU-08 Backend - GetMapReports', () => {
  let reportRepository;
  let useCase;

  beforeEach(() => {
    reportRepository = {
      findForMap: jest.fn(),
    };
    useCase = new GetMapReports(reportRepository);
  });

  test('CP-HU08-04: Obtener reportes activos backend', async () => {
    const reportesMock = [
      {
        id: 'r1',
        latitud: 1.2136,
        longitud: -77.2811,
        tipo_hurto: 'atraco',
        franja_horaria: '18:00-23:59',
        fecha_incidente: '2026-04-14',
        barrio_ingresado: 'Centro',
        comuna: 5,
      },
      {
        id: 'r2',
        latitud: 1.2140,
        longitud: -77.2820,
        tipo_hurto: 'raponazo',
        franja_horaria: '12:00-17:59',
        fecha_incidente: '2026-04-13',
        barrio_ingresado: 'San Juan',
        comuna: 3,
      },
    ];

    reportRepository.findForMap.mockResolvedValue(reportesMock);

    const result = await useCase.execute();

    expect(reportRepository.findForMap).toHaveBeenCalledTimes(1);
    expect(result).toEqual(reportesMock);

    console.log('Resultado: OK');
  });
});