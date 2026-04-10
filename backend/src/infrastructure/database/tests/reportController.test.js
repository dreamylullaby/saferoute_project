import { jest } from '@jest/globals';
import ReportController from '../../../interfaces/controllers/reportController.js';

describe('HU-01 Backend - ReportController.create', () => {
  let repository;
  let controller;
  let req;
  let res;

  beforeEach(() => {
    repository = {
      create: jest.fn(),
      findById: jest.fn(),
      buscarBarrioPorTexto: jest.fn(),
    };

    controller = new ReportController(repository);

    req = {
      body: {
        usuario_id: 'user-1',
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
      },
    };

    res = {
      status: jest.fn().mockReturnThis(),
      json: jest.fn(),
    };
  });

  test('CP-HU01-07: manejo de campos incompletos backend', async () => {
    controller.CreateReportUC.execute = jest
      .fn()
      .mockRejectedValue(new Error('Faltan campos obligatorios'));

    req.body = {
      usuario_id: 'user-1',
      fecha_incidente: '',
      franja_horaria: '',
    };

    await controller.create(req, res);

    expect(controller.CreateReportUC.execute).toHaveBeenCalledWith(req.body);
    expect(res.status).toHaveBeenCalledWith(400);
    expect(res.json).toHaveBeenCalledWith({
      success: false,
      message: 'Faltan campos obligatorios',
    });
  });

  test('CP-HU01-09: confirmación al usuario', async () => {
    controller.CreateReportUC.execute = jest.fn().mockResolvedValue({
      id: 'uuid-123',
      usuario_id: 'user-1',
    });

    await controller.create(req, res);

    expect(controller.CreateReportUC.execute).toHaveBeenCalledWith(req.body);
    expect(res.status).toHaveBeenCalledWith(201);
    expect(res.json).toHaveBeenCalledWith({
      success: true,
      message: 'Reporte registrado con éxito.',
      data: {
        id: 'uuid-123',
        usuario_id: 'user-1',
      },
    });
  });

  test('CP-HU01-09B: error interno de base de datos', async () => {
    controller.CreateReportUC.execute = jest
      .fn()
      .mockRejectedValue(new Error('Error al crear reporte: db insert failed'));

    await controller.create(req, res);

    expect(res.status).toHaveBeenCalledWith(500);
    expect(res.json).toHaveBeenCalledWith({
      success: false,
      message: 'Error al crear reporte: db insert failed',
    });
  });
});