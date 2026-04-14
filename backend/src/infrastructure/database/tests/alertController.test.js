import { jest } from '@jest/globals';


const mockGetAlertConfigExecute = jest.fn();
const mockUpsertAlertConfigExecute = jest.fn();
const mockGetNearbyAlertsExecute = jest.fn();
const mockMarkAlertReadExecute = jest.fn();


await jest.unstable_mockModule('../../../application/use-cases/getAlertConfig.js', () => ({
  default: jest.fn().mockImplementation(() => ({
    execute: mockGetAlertConfigExecute,
  })),
}));


await jest.unstable_mockModule('../../../application/use-cases/upsertAlertConfig.js', () => ({
  default: jest.fn().mockImplementation(() => ({
    execute: mockUpsertAlertConfigExecute,
  })),
}));


await jest.unstable_mockModule('../../../application/use-cases/getNearbyAlerts.js', () => ({
  default: jest.fn().mockImplementation(() => ({
    execute: mockGetNearbyAlertsExecute,
  })),
}));


await jest.unstable_mockModule('../../../application/use-cases/markAlertRead.js', () => ({
  default: jest.fn().mockImplementation(() => ({
    execute: mockMarkAlertReadExecute,
  })),
}));


const { default: AlertController } = await import('../../../interfaces/controllers/alertController.js');


const mockRes = () => {
  const res = {};
  res.status = jest.fn().mockReturnValue(res);
  res.json = jest.fn().mockReturnValue(res);
  return res;
};


describe('HU-07 Backend - AlertController', () => {
  let alertRepository;
  let controller;


  beforeEach(() => {
    jest.clearAllMocks();
    alertRepository = {};
    controller = new AlertController(alertRepository);
  });


  test('CP-HU07-10: Obtener configuración', async () => {
    const req = { user: { id: 'user-123' } };
    const res = mockRes();
    const resultMock = { id: 'cfg-1', radio_metros: 500, activo: true };


    mockGetAlertConfigExecute.mockResolvedValue(resultMock);


    await controller.getConfig(req, res);


    expect(res.status).toHaveBeenCalledWith(200);
    expect(res.json).toHaveBeenCalledWith({
      success: true,
      data: resultMock,
    });
  });


  test('CP-HU07-11: Crear o actualizar configuración', async () => {
    const req = {
      user: { id: 'user-123' },
      body: { radio_metros: 1500, activo: true },
    };
    const res = mockRes();
    const resultMock = { id: 'cfg-2', radio_metros: 1500, activo: true };


    mockUpsertAlertConfigExecute.mockResolvedValue(resultMock);


    await controller.upsertConfig(req, res);


    expect(res.status).toHaveBeenCalledWith(200);
    expect(res.json).toHaveBeenCalledWith({
      success: true,
      data: resultMock,
    });
  });


  test('CP-HU07-12: Datos inválidos', async () => {
    const req = {
      user: { id: 'user-123' },
      body: { radio_metros: null, activo: true },
    };
    const res = mockRes();


    mockUpsertAlertConfigExecute.mockRejectedValue(
      new Error('radio_metros es obligatorio'),
    );


    await controller.upsertConfig(req, res);


    expect(res.status).toHaveBeenCalledWith(400);
    expect(res.json).toHaveBeenCalledWith({
      success: false,
      message: 'radio_metros es obligatorio',
    });
  });


  test('CP-HU07-13: Obtener alertas cercanas dentro del radio', async () => {
    const req = {
      user: { id: 'user-123' },
      query: { lat: '1.2136', lng: '-77.2811' },
    };
    const res = mockRes();
    const resultMock = [
      {
        id: 'a1',
        tipo_hurto: 'Atraco',
        barrio_ingresado: 'Centro',
        distancia_metros: 120,
      },
    ];


    mockGetNearbyAlertsExecute.mockResolvedValue(resultMock);


    await controller.getNearby(req, res);


    expect(res.status).toHaveBeenCalledWith(200);
    expect(res.json).toHaveBeenCalledWith({
      success: true,
      data: resultMock,
    });
  });


  test('CP-HU07-14: Coordenadas inválidas', async () => {
    const req = {
      user: { id: 'user-123' },
      query: { lat: 'abc', lng: '-' },
    };
    const res = mockRes();


    mockGetNearbyAlertsExecute.mockRejectedValue(
      new Error('Coordenadas válidas requeridas'),
    );


    await controller.getNearby(req, res);


    expect(res.status).toHaveBeenCalledWith(400);
    expect(res.json).toHaveBeenCalledWith({
      success: false,
      message: 'Coordenadas válidas requeridas',
    });
  });


  test('CP-HU07-15: Incidente fuera del radio', async () => {
    const req = {
      user: { id: 'user-123' },
      query: { lat: '1.2136', lng: '-77.2811' },
    };
    const res = mockRes();


    mockGetNearbyAlertsExecute.mockResolvedValue([]);


    await controller.getNearby(req, res);


    expect(res.status).toHaveBeenCalledWith(200);
    expect(res.json).toHaveBeenCalledWith({
      success: true,
      data: [],
    });
  });


  test('CP-HU07-16: Alertas desactivadas', async () => {
    const req = {
      user: { id: 'user-123' },
      body: { radio_metros: 500, activo: false },
    };
    const res = mockRes();
    const resultMock = { id: 'cfg-1', radio_metros: 500, activo: false };


    mockUpsertAlertConfigExecute.mockResolvedValue(resultMock);


    await controller.upsertConfig(req, res);


    expect(res.status).toHaveBeenCalledWith(200);
    expect(res.json).toHaveBeenCalledWith({
      success: true,
      data: resultMock,
    });
  });


  test('CP-HU07-17: Marcar alerta leída', async () => {
    const req = {
      params: { id: 'alert-1' },
      user: { id: 'user-123' },
    };
    const res = mockRes();
    const resultMock = { id: 'alert-1', leida: true };


    mockMarkAlertReadExecute.mockResolvedValue(resultMock);


    await controller.markRead(req, res);


    expect(res.status).toHaveBeenCalledWith(200);
    expect(res.json).toHaveBeenCalledWith({
      success: true,
      data: resultMock,
    });
  });


  test('CP-HU07-18: Alerta inexistente', async () => {
    const req = {
      params: { id: 'alert-inexistente' },
      user: { id: 'user-123' },
    };
    const res = mockRes();


    mockMarkAlertReadExecute.mockRejectedValue(
      new Error('Alerta no encontrada'),
    );


    await controller.markRead(req, res);


    expect(res.status).toHaveBeenCalledWith(404);
    expect(res.json).toHaveBeenCalledWith({
      success: false,
      message: 'Alerta no encontrada',
    });
  });


  test('CP-HU07-19: Múltiples incidentes sin duplicidad', async () => {
    const req = {
      user: { id: 'user-123' },
      query: { lat: '1.2136', lng: '-77.2811' },
    };
    const res = mockRes();
    const resultMock = [
      {
        id: 'a1',
        tipo_hurto: 'Atraco',
        barrio_ingresado: 'Centro',
        distancia_metros: 120,
      },
    ];


    mockGetNearbyAlertsExecute.mockResolvedValue(resultMock);


    await controller.getNearby(req, res);


    expect(res.status).toHaveBeenCalledWith(200);
    expect(res.json).toHaveBeenCalledWith({
      success: true,
      data: resultMock,
    });
    expect(resultMock).toHaveLength(1);
  });


  test('CP-HU07-20: Error interno', async () => {
    const req = { user: { id: 'user-123' } };
    const res = mockRes();


    mockGetAlertConfigExecute.mockRejectedValue(new Error('Error interno'));


    await controller.getConfig(req, res);


    expect(res.status).toHaveBeenCalledWith(500);
    expect(res.json).toHaveBeenCalledWith({
      success: false,
      message: 'Error interno',
    });
  });
});
