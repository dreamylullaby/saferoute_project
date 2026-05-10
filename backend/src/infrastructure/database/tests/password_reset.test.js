import { jest } from '@jest/globals';

const mockDb = {
  from: jest.fn(),
};

const mockEnviarCorreoRecuperacion = jest.fn();
const mockHash = jest.fn();
const mockRandomBytes = jest.fn();

await jest.unstable_mockModule('../dbScript/db.js', () => ({
  __esModule: true,
  default: mockDb,
}));

await jest.unstable_mockModule('../../email/emailService.js', () => ({
  __esModule: true,
  enviarCorreoRecuperacion: mockEnviarCorreoRecuperacion,
}));

await jest.unstable_mockModule('bcrypt', () => ({
  __esModule: true,
  default: {
    hash: mockHash,
    compare: jest.fn(),
  },
  hash: mockHash,
  compare: jest.fn(),
}));

await jest.unstable_mockModule('crypto', () => ({
  __esModule: true,
  default: {
    randomBytes: mockRandomBytes,
  },
  randomBytes: mockRandomBytes,
}));

const { forgotPassword, resetPassword } = await import('../../../interfaces/controllers/userController.js');

function mockResponse() {
  const res = {};
  res.status = jest.fn().mockReturnValue(res);
  res.json = jest.fn().mockReturnValue(res);
  return res;
}

function createSingleResult(data, error = null) {
  return {
    select: jest.fn().mockReturnThis(),
    eq: jest.fn().mockReturnThis(),
    insert: jest.fn().mockReturnThis(),
    update: jest.fn().mockReturnThis(),
    single: jest.fn().mockResolvedValue({ data, error }),
  };
}

function createInsertResult(error = null) {
  return {
    insert: jest.fn().mockResolvedValue({ error }),
  };
}

function createUpdateResult(error = null) {
  return {
    update: jest.fn().mockReturnThis(),
    eq: jest.fn().mockResolvedValue({ error }),
  };
}

describe('HU-13 userController recuperación de contraseña', () => {
  beforeEach(() => {
    jest.clearAllMocks();
  });

  test('CP-HU13-BE-11 correo inválido en forgotPassword responde 400', async () => {
    const req = {
      body: { correo: 'correo-invalido', plataforma: 'web' },
    };
    const res = mockResponse();

    await forgotPassword(req, res);

    expect(res.status).toHaveBeenCalledWith(400);
    expect(res.json).toHaveBeenCalledWith({ message: 'Correo inválido' });
    expect(mockDb.from).not.toHaveBeenCalled();
  });

  test('CP-HU13-BE-03 correo no registrado responde mensaje genérico', async () => {
    const req = {
      body: { correo: 'noexiste@gmail.com', plataforma: 'web' },
    };
    const res = mockResponse();

    mockDb.from.mockReturnValueOnce(createSingleResult(null));

    await forgotPassword(req, res);

    expect(mockDb.from).toHaveBeenCalledWith('usuarios');
    expect(res.json).toHaveBeenCalledWith({
      message: 'Si el correo está registrado, recibirás un enlace de recuperación.',
    });
    expect(mockEnviarCorreoRecuperacion).not.toHaveBeenCalled();
  });

  test('CP-HU13-BE-01 correo válido y registrado genera token y envía correo', async () => {
    const req = {
      body: { correo: 'usuario@gmail.com', plataforma: 'web' },
    };
    const res = mockResponse();

    const usuario = {
      id: 7,
      correo: 'usuario@gmail.com',
      auth_provider: 'local',
    };

    const usuariosChain = createSingleResult(usuario);
    const passwordResetInsert = createInsertResult(null);

    mockRandomBytes.mockReturnValue({
      toString: jest.fn().mockReturnValue('token-prueba-123'),
    });

    mockDb.from
      .mockReturnValueOnce(usuariosChain)
      .mockReturnValueOnce(passwordResetInsert);

    await forgotPassword(req, res);

    expect(mockDb.from).toHaveBeenNthCalledWith(1, 'usuarios');
    expect(mockDb.from).toHaveBeenNthCalledWith(2, 'password_resets');
    expect(passwordResetInsert.insert).toHaveBeenCalledWith(
      expect.objectContaining({
        usuario_id: 7,
        token: 'token-prueba-123',
        usado: false,
      })
    );
    expect(mockEnviarCorreoRecuperacion).toHaveBeenCalledWith(
      'usuario@gmail.com',
      'token-prueba-123',
      'web'
    );
    expect(res.json).toHaveBeenCalledWith({
      message: 'Si el correo está registrado, recibirás un enlace de recuperación.',
    });
  });

  test('correo registrado con auth_provider distinto de local no genera token', async () => {
    const req = {
      body: { correo: 'google@gmail.com', plataforma: 'web' },
    };
    const res = mockResponse();

    const usuario = {
      id: 9,
      correo: 'google@gmail.com',
      auth_provider: 'google',
    };

    mockDb.from.mockReturnValueOnce(createSingleResult(usuario));

    await forgotPassword(req, res);

    expect(mockDb.from).toHaveBeenCalledTimes(1);
    expect(mockEnviarCorreoRecuperacion).not.toHaveBeenCalled();
    expect(res.json).toHaveBeenCalledWith({
      message: 'Si el correo está registrado, recibirás un enlace de recuperación.',
    });
  });

  test('si falla el envío del correo, forgotPassword responde igual', async () => {
    const req = {
      body: { correo: 'usuario@gmail.com', plataforma: 'web' },
    };
    const res = mockResponse();

    const usuario = {
      id: 3,
      correo: 'usuario@gmail.com',
      auth_provider: 'local',
    };

    mockRandomBytes.mockReturnValue({
      toString: jest.fn().mockReturnValue('token-email-falla'),
    });

    mockEnviarCorreoRecuperacion.mockRejectedValueOnce(new Error('fallo email'));

    mockDb.from
      .mockReturnValueOnce(createSingleResult(usuario))
      .mockReturnValueOnce(createInsertResult(null));

    await forgotPassword(req, res);

    expect(mockEnviarCorreoRecuperacion).toHaveBeenCalled();
    expect(res.json).toHaveBeenCalledWith({
      message: 'Si el correo está registrado, recibirás un enlace de recuperación.',
    });
  });

  test('resetPassword sin token responde 400', async () => {
    const req = {
      body: { token: '', nuevaPassword: 'Password123' },
    };
    const res = mockResponse();

    await resetPassword(req, res);

    expect(res.status).toHaveBeenCalledWith(400);
    expect(res.json).toHaveBeenCalledWith({ message: 'Token requerido' });
  });

  test('CP-HU13-BE-12 nueva contraseña corta responde 400', async () => {
    const req = {
      body: { token: 'token-valido', nuevaPassword: '12345' },
    };
    const res = mockResponse();

    await resetPassword(req, res);

    expect(res.status).toHaveBeenCalledWith(400);
    expect(res.json).toHaveBeenCalledWith({
      message: 'La contraseña debe tener al menos 8 caracteres',
    });
  });

  test('CP-HU13-BE-09 token inválido responde 400', async () => {
    const req = {
      body: { token: 'token-invalido', nuevaPassword: 'Password123' },
    };
    const res = mockResponse();

    const passwordResetChain = {
      select: jest.fn().mockReturnThis(),
      eq: jest.fn().mockReturnThis(),
      single: jest.fn().mockResolvedValue({ data: null, error: new Error('not found') }),
    };

    mockDb.from.mockReturnValueOnce(passwordResetChain);

    await resetPassword(req, res);

    expect(mockDb.from).toHaveBeenCalledWith('password_resets');
    expect(res.status).toHaveBeenCalledWith(400);
    expect(res.json).toHaveBeenCalledWith({ message: 'Token inválido' });
  });

  test('CP-HU13-BE-10 token ya usado responde 400', async () => {
    const req = {
      body: { token: 'token-usado', nuevaPassword: 'Password123' },
    };
    const res = mockResponse();

    const reset = {
      id: 10,
      usuario_id: 5,
      token: 'token-usado',
      usado: true,
      expiration: '2099-01-01T00:00:00.000Z',
    };

    mockDb.from.mockReturnValueOnce(createSingleResult(reset));

    await resetPassword(req, res);

    expect(res.status).toHaveBeenCalledWith(400);
    expect(res.json).toHaveBeenCalledWith({
      message: 'Este enlace ya fue utilizado',
    });
  });

  test('CP-HU13-BE-08 token expirado responde 400', async () => {
    const req = {
      body: { token: 'token-expirado', nuevaPassword: 'Password123' },
    };
    const res = mockResponse();

    const reset = {
      id: 11,
      usuario_id: 5,
      token: 'token-expirado',
      usado: false,
      expiration: '2020-01-01T00:00:00.000Z',
    };

    mockDb.from.mockReturnValueOnce(createSingleResult(reset));

    await resetPassword(req, res);

    expect(res.status).toHaveBeenCalledWith(400);
    expect(res.json).toHaveBeenCalledWith({
      message: 'El enlace ha expirado. Solicita uno nuevo.',
    });
  });

  test('CP-HU13-BE-05 restablece contraseña correctamente y marca token como usado', async () => {
    const req = {
      body: { token: 'token-ok', nuevaPassword: 'Password123' },
    };
    const res = mockResponse();

    const reset = {
      id: 15,
      usuario_id: 8,
      token: 'token-ok',
      usado: false,
      expiration: '2099-01-01T00:00:00.000Z',
    };

    mockHash.mockResolvedValueOnce('hash-nuevo');

    const passwordResetSelectChain = createSingleResult(reset);
    const usuariosUpdateChain = createUpdateResult(null);
    const passwordResetUpdateChain = createUpdateResult(null);

    mockDb.from
      .mockReturnValueOnce(passwordResetSelectChain)
      .mockReturnValueOnce(usuariosUpdateChain)
      .mockReturnValueOnce(passwordResetUpdateChain);

    await resetPassword(req, res);

    expect(mockHash).toHaveBeenCalledWith('Password123', 12);

    expect(mockDb.from).toHaveBeenNthCalledWith(1, 'password_resets');
    expect(mockDb.from).toHaveBeenNthCalledWith(2, 'usuarios');
    expect(mockDb.from).toHaveBeenNthCalledWith(3, 'password_resets');

    expect(res.json).toHaveBeenCalledWith({
      message: 'Contraseña actualizada correctamente',
    });
  });

  test('si ocurre error inesperado en forgotPassword responde 500', async () => {
    const req = {
      body: { correo: 'usuario@gmail.com', plataforma: 'web' },
    };
    const res = mockResponse();

    mockDb.from.mockImplementationOnce(() => {
      throw new Error('fallo db');
    });

    await forgotPassword(req, res);

    expect(res.status).toHaveBeenCalledWith(500);
    expect(res.json).toHaveBeenCalledWith({ message: 'fallo db' });
  });

  test('si ocurre error inesperado en resetPassword responde 500', async () => {
    const req = {
      body: { token: 'token-ok', nuevaPassword: 'Password123' },
    };
    const res = mockResponse();

    const reset = {
      id: 99,
      usuario_id: 20,
      token: 'token-ok',
      usado: false,
      expiration: '2099-01-01T00:00:00.000Z',
    };

    mockHash.mockResolvedValueOnce('hash-nuevo');

    const passwordResetSelectChain = createSingleResult(reset);
    const usuariosUpdateChain = createUpdateResult(new Error('fallo update usuario'));

    mockDb.from
      .mockReturnValueOnce(passwordResetSelectChain)
      .mockReturnValueOnce(usuariosUpdateChain);

    await resetPassword(req, res);

    expect(res.status).toHaveBeenCalledWith(500);
    expect(res.json).toHaveBeenCalledWith({ message: 'fallo update usuario' });
  });
});