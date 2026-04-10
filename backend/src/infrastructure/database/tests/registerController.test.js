import { jest } from '@jest/globals';

jest.unstable_mockModule('../../../infrastructure/database/dbScript/db.js', () => ({
  default: {
    from: jest.fn(),
  },
}));

jest.unstable_mockModule('bcrypt', () => ({
  default: {
    hash: jest.fn(),
    compare: jest.fn(),
  },
}));

jest.unstable_mockModule('../../../config/jwt.js', () => ({
  generateToken: jest.fn(),
}));

jest.unstable_mockModule('../../../infrastructure/firebase/firebase.js', () => ({
  default: {
    auth: jest.fn(),
  },
}));

const { registerLocal } = await import('../../../interfaces/controllers/userController.js');
const db = (await import('../../../infrastructure/database/dbScript/db.js')).default;
const bcrypt = (await import('bcrypt')).default;
const { generateToken } = await import('../../../config/jwt.js');

describe('HU-04 Backend - registerLocal', () => {
  let req;
  let res;

  beforeEach(() => {
    jest.resetAllMocks();

    req = {
      body: {
        username: 'JuanP',
        correo: 'nuevo@pasto.com',
        password: 'pass123',
      },
    };

    res = {
      status: jest.fn().mockReturnThis(),
      json: jest.fn(),
    };
  });

  test('CP-HU04-01: valida campos obligatorios', async () => {
    req.body = { username: '', correo: '', password: '' };

    await registerLocal(req, res);

    expect(res.status).toHaveBeenCalledWith(400);
    expect(res.json).toHaveBeenCalledWith({
      message: 'Todos los campos son obligatorios',
    });
  });

  test('CP-HU04-10: apodo duplicado', async () => {
    req.body = {
      username: 'JuanP_existente',
      correo: 'nuevo@pasto.com',
      password: 'pass123',
    };

    const usernameChain = {
      select: jest.fn().mockReturnThis(),
      eq: jest.fn().mockReturnThis(),
      single: jest.fn().mockResolvedValue({
        data: { id: 55 },
        error: null,
      }),
    };

    db.from.mockReturnValueOnce(usernameChain);

    await registerLocal(req, res);

    expect(db.from).toHaveBeenCalledTimes(1);
    expect(res.status).toHaveBeenCalledWith(409);
    expect(res.json).toHaveBeenCalledWith({
      message: 'El apodo ya está en uso',
    });
    expect(bcrypt.hash).not.toHaveBeenCalled();
  });

  test('CP-HU04-09: correo ya registrado', async () => {
    const usernameChain = {
      select: jest.fn().mockReturnThis(),
      eq: jest.fn().mockReturnThis(),
      single: jest.fn().mockResolvedValue({
        data: null,
        error: null,
      }),
    };

    const correoChain = {
      select: jest.fn().mockReturnThis(),
      eq: jest.fn().mockReturnThis(),
      single: jest.fn().mockResolvedValue({
        data: { id: 1 },
        error: null,
      }),
    };

    db.from
      .mockReturnValueOnce(usernameChain)
      .mockReturnValueOnce(correoChain);

    await registerLocal(req, res);

    expect(db.from).toHaveBeenCalledTimes(2);
    expect(res.status).toHaveBeenCalledWith(409);
    expect(res.json).toHaveBeenCalledWith({
      message: 'El correo ya está registrado',
    });
    expect(bcrypt.hash).not.toHaveBeenCalled();
  });

  test('CP-HU04-08: registro exitoso con datos válidos', async () => {
    const usernameChain = {
      select: jest.fn().mockReturnThis(),
      eq: jest.fn().mockReturnThis(),
      single: jest.fn().mockResolvedValue({
        data: null,
        error: null,
      }),
    };

    const correoChain = {
      select: jest.fn().mockReturnThis(),
      eq: jest.fn().mockReturnThis(),
      single: jest.fn().mockResolvedValue({
        data: null,
        error: null,
      }),
    };

    const insertChain = {
      insert: jest.fn().mockReturnThis(),
      select: jest.fn().mockReturnThis(),
      single: jest.fn().mockResolvedValue({
        data: {
          id: 10,
          username: 'JuanP',
          correo: 'nuevo@pasto.com',
          rol: 'usuario',
        },
        error: null,
      }),
    };

    db.from
      .mockReturnValueOnce(usernameChain)
      .mockReturnValueOnce(correoChain)
      .mockReturnValueOnce(insertChain);

    bcrypt.hash.mockResolvedValue('hashed-pass');
    generateToken.mockReturnValue('fake-jwt');

    await registerLocal(req, res);

    expect(bcrypt.hash).toHaveBeenCalledWith('pass123', 12);
    expect(generateToken).toHaveBeenCalledWith({ id: 10, rol: 'usuario' });
    expect(res.status).toHaveBeenCalledWith(201);
    expect(res.json).toHaveBeenCalledWith({
      user: {
        id: 10,
        username: 'JuanP',
        correo: 'nuevo@pasto.com',
        rol: 'usuario',
      },
      token: 'fake-jwt',
    });
  });

  test('CP-HU04-11: hashing correcto de contraseña', async () => {
    const usernameChain = {
      select: jest.fn().mockReturnThis(),
      eq: jest.fn().mockReturnThis(),
      single: jest.fn().mockResolvedValue({
        data: null,
        error: null,
      }),
    };

    const correoChain = {
      select: jest.fn().mockReturnThis(),
      eq: jest.fn().mockReturnThis(),
      single: jest.fn().mockResolvedValue({
        data: null,
        error: null,
      }),
    };

    const insertChain = {
      insert: jest.fn().mockReturnThis(),
      select: jest.fn().mockReturnThis(),
      single: jest.fn().mockResolvedValue({
        data: {
          id: 11,
          username: 'JuanP',
          correo: 'nuevo@pasto.com',
          rol: 'usuario',
        },
        error: null,
      }),
    };

    db.from
      .mockReturnValueOnce(usernameChain)
      .mockReturnValueOnce(correoChain)
      .mockReturnValueOnce(insertChain);

    bcrypt.hash.mockResolvedValue('hashed-pass-123');
    generateToken.mockReturnValue('fake-jwt');

    await registerLocal(req, res);

    expect(bcrypt.hash).toHaveBeenCalledWith('pass123', 12);
  });

  test('CP-HU04-12: asigna rol usuario por defecto', async () => {
    const usernameChain = {
      select: jest.fn().mockReturnThis(),
      eq: jest.fn().mockReturnThis(),
      single: jest.fn().mockResolvedValue({
        data: null,
        error: null,
      }),
    };

    const correoChain = {
      select: jest.fn().mockReturnThis(),
      eq: jest.fn().mockReturnThis(),
      single: jest.fn().mockResolvedValue({
        data: null,
        error: null,
      }),
    };

    const insertMock = jest.fn().mockReturnThis();

    const insertChain = {
      insert: insertMock,
      select: jest.fn().mockReturnThis(),
      single: jest.fn().mockResolvedValue({
        data: {
          id: 12,
          username: 'JuanP',
          correo: 'nuevo@pasto.com',
          rol: 'usuario',
        },
        error: null,
      }),
    };

    db.from
      .mockReturnValueOnce(usernameChain)
      .mockReturnValueOnce(correoChain)
      .mockReturnValueOnce(insertChain);

    bcrypt.hash.mockResolvedValue('hashed-pass');
    generateToken.mockReturnValue('fake-jwt');

    await registerLocal(req, res);

    expect(insertMock).toHaveBeenCalledWith(
      expect.objectContaining({
        rol: 'usuario',
        auth_provider: 'local',
        estado: 'activo',
      })
    );
  });

  test('CP-HU04-13: genera token al registrar e inicia sesión lógica', async () => {
    const usernameChain = {
      select: jest.fn().mockReturnThis(),
      eq: jest.fn().mockReturnThis(),
      single: jest.fn().mockResolvedValue({
        data: null,
        error: null,
      }),
    };

    const correoChain = {
      select: jest.fn().mockReturnThis(),
      eq: jest.fn().mockReturnThis(),
      single: jest.fn().mockResolvedValue({
        data: null,
        error: null,
      }),
    };

    const insertChain = {
      insert: jest.fn().mockReturnThis(),
      select: jest.fn().mockReturnThis(),
      single: jest.fn().mockResolvedValue({
        data: {
          id: 13,
          username: 'JuanP',
          correo: 'nuevo@pasto.com',
          rol: 'usuario',
        },
        error: null,
      }),
    };

    db.from
      .mockReturnValueOnce(usernameChain)
      .mockReturnValueOnce(correoChain)
      .mockReturnValueOnce(insertChain);

    bcrypt.hash.mockResolvedValue('hashed-pass');
    generateToken.mockReturnValue('auto-login-jwt');

    await registerLocal(req, res);

    expect(generateToken).toHaveBeenCalledWith({ id: 13, rol: 'usuario' });
    expect(res.status).toHaveBeenCalledWith(201);
    expect(res.json).toHaveBeenCalledWith({
      user: {
        id: 13,
        username: 'JuanP',
        correo: 'nuevo@pasto.com',
        rol: 'usuario',
      },
      token: 'auto-login-jwt',
    });
  });

  test('CP-HU04-14: manejo error validación múltiple', async () => {
    req.body = { username: '', correo: '', password: '' };

    await registerLocal(req, res);

    expect(res.status).toHaveBeenCalledWith(400);
    expect(res.json).toHaveBeenCalledWith({
      message: 'Todos los campos son obligatorios',
    });
  });
});