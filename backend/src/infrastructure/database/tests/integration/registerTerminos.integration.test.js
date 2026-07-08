import request from 'supertest';
import { describe, test, expect, beforeEach, jest } from '@jest/globals';

const usernameSingleMock = jest.fn();
const correoSingleMock = jest.fn();
const hashMock = jest.fn();
const userInsertSingleMock = jest.fn();
const aceptacionInsertMock = jest.fn();

const fromMock = jest.fn((table) => {
  if (table === 'usuarios') {
    return {
      select: jest.fn(() => ({
        eq: jest.fn((field) => ({
          single: field === 'username' ? usernameSingleMock : correoSingleMock,
        })),
      })),
      insert: jest.fn(() => ({
        select: jest.fn(() => ({
          single: userInsertSingleMock,
        })),
      })),
    };
  }

  if (table === 'aceptacion_terminos') {
    return {
      insert: aceptacionInsertMock,
    };
  }

  return {};
});

jest.unstable_mockModule('../../dbScript/db.js', () => ({
  __esModule: true,
  default: { from: fromMock },
}));

jest.unstable_mockModule('bcrypt', () => ({
  __esModule: true,
  default: { hash: hashMock },
}));

jest.unstable_mockModule('../../../../config/jwt.js', () => ({
  __esModule: true,
  generateToken: jest.fn(() => 'jwt-integracion'),
  verifyToken: jest.fn((req, res, next) => {
    req.user = { id: 44, rol: 'usuario' };
    if (typeof next === 'function') next();
  }),
}));

jest.unstable_mockModule('../../../firebase/firebase.js', () => ({
  __esModule: true,
  default: {},
}));

jest.unstable_mockModule('../../../email/emailService.js', () => ({
  __esModule: true,
  enviarCorreoRecuperacion: jest.fn(),
}));

const app = (await import('../../../../server.js')).default;

describe('HU-04 Integrales Backend - Términos y Condiciones', () => {
  beforeEach(() => {
    jest.clearAllMocks();
  });

  test('CP-HU04-I-01 bloquea registro si no acepta términos', async () => {
    const res = await request(app).post('/api/auth/register').send({
      username: 'Luna',
      correo: 'luna@test.com',
      password: 'ClaveSegura123',
      aceptaTerminos: false,
    });

    expect(res.status).toBe(400);
    expect(res.body).toEqual({
      message: 'Debes aceptar los términos y condiciones para registrarte',
    });
  });

  test('CP-HU04-I-02 guarda evidencia de aceptación al registrar', async () => {
    usernameSingleMock.mockResolvedValue({ data: null, error: null });
    correoSingleMock.mockResolvedValue({ data: null, error: null });
    hashMock.mockResolvedValue('hash-ok');

    userInsertSingleMock.mockResolvedValue({
      data: {
        id: 44,
        username: 'Luna',
        correo: 'luna@test.com',
        rol: 'usuario',
      },
      error: null,
    });

    aceptacionInsertMock.mockResolvedValue({ error: null });

    const res = await request(app)
      .post('/api/auth/register')
      .set('x-forwarded-for', '181.55.10.20')
      .send({
        username: 'Luna',
        correo: 'luna@test.com',
        password: 'ClaveSegura123',
        aceptaTerminos: true,
      });

    expect(res.status).toBe(201);
    expect(aceptacionInsertMock).toHaveBeenCalledWith({
      usuario_id: 44,
      version_terminos: 'v1.0',
      ip_origen: '181.55.10.20',
    });
  });

  test('CP-HU04-I-03 retorna documento legal vigente', async () => {
    const res = await request(app).get('/api/auth/terminos');

    expect(res.status).toBe(200);
    expect(res.body).toEqual(
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