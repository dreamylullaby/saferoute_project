import { describe, test, expect, beforeEach, jest } from '@jest/globals';

const usernameSingleMock = jest.fn();
const correoSingleMock = jest.fn();
const hashMock = jest.fn();
const userInsertSingleMock = jest.fn();
const aceptacionInsertMock = jest.fn();

const usuariosInsertMock = jest.fn(() => ({
  select: jest.fn(() => ({
    single: userInsertSingleMock,
  })),
}));

const fromMock = jest.fn((table) => {
  if (table === 'usuarios') {
    return {
      select: jest.fn(() => ({
        eq: jest.fn((field) => ({
          single: field === 'username' ? usernameSingleMock : correoSingleMock,
        })),
      })),
      insert: usuariosInsertMock,
    };
  }

  if (table === 'aceptacion_terminos') {
    return {
      insert: aceptacionInsertMock,
    };
  }

  return {};
});

jest.unstable_mockModule('../dbScript/db.js', () => ({
  __esModule: true,
  default: { from: fromMock },
}));

jest.unstable_mockModule('bcrypt', () => ({
  __esModule: true,
  default: { hash: hashMock },
}));

jest.unstable_mockModule('../../../config/jwt.js', () => ({
  __esModule: true,
  generateToken: jest.fn(() => 'fake-jwt'),
  verifyToken: jest.fn(),
}));

jest.unstable_mockModule('../../firebase/firebase.js', () => ({
  __esModule: true,
  default: {},
}));

jest.unstable_mockModule('../../email/emailService.js', () => ({
  __esModule: true,
  enviarCorreoRecuperacion: jest.fn(),
}));

const { registerLocal, getTerminos } = await import('../../../interfaces/controllers/userController.js');

describe('HU-04 Unitarias Backend - Términos y Condiciones', () => {
  let req;
  let res;

  beforeEach(() => {
    req = {
      body: {
        username: 'Luna',
        correo: 'luna@test.com',
        password: 'ClaveSegura123',
        aceptaTerminos: true,
      },
      headers: { 'x-forwarded-for': '190.1.1.10' },
      socket: { remoteAddress: '127.0.0.1' },
    };

    res = {
      status: jest.fn().mockReturnThis(),
      json: jest.fn(),
    };

    jest.clearAllMocks();
  });

  test('CP-HU04-B-01 rechaza registro sin aceptar términos', async () => {
    req.body.aceptaTerminos = false;

    await registerLocal(req, res);

    expect(res.status).toHaveBeenCalledWith(400);
    expect(res.json).toHaveBeenCalledWith({
      message: 'Debes aceptar los términos y condiciones para registrarte',
    });
  });

  test('CP-HU04-B-02 guarda evidencia de aceptación al registrar', async () => {
    usernameSingleMock.mockResolvedValue({ data: null, error: null });
    correoSingleMock.mockResolvedValue({ data: null, error: null });
    hashMock.mockResolvedValue('hash-ok');

    userInsertSingleMock.mockResolvedValue({
      data: {
        id: 25,
        username: 'Luna',
        correo: 'luna@test.com',
        rol: 'usuario',
      },
      error: null,
    });

    aceptacionInsertMock.mockResolvedValue({ error: null });

    await registerLocal(req, res);

    expect(hashMock).toHaveBeenCalledWith('ClaveSegura123', 12);
    expect(aceptacionInsertMock).toHaveBeenCalledWith({
      usuario_id: 25,
      version_terminos: 'v1.0',
      ip_origen: '190.1.1.10',
    });
    expect(res.status).toHaveBeenCalledWith(201);
    expect(res.json).toHaveBeenCalledWith({
      user: {
        id: 25,
        username: 'Luna',
        correo: 'luna@test.com',
        rol: 'usuario',
      },
      token: 'fake-jwt',
    });
  });

  test('CP-HU04-B-03 retorna documento legal vigente', () => {
    getTerminos(req, res);

    expect(res.json).toHaveBeenCalledWith(
      expect.objectContaining({
        version: expect.any(String),
        fecha_vigencia: expect.any(String),
        terminos: expect.any(String),
        politica_privacidad: expect.any(String),
        aviso_ubicacion: expect.any(String),
      }),
    );
  });
});