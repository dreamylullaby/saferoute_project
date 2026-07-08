import { describe, test, expect, beforeEach, jest } from '@jest/globals';

const singleMock = jest.fn();
const eqMock = jest.fn(() => ({ single: singleMock }));
const selectMock = jest.fn(() => ({ eq: eqMock }));
const rpcMock = jest.fn();

jest.unstable_mockModule('../dbScript/db.js', () => ({
  default: {
    from: jest.fn(() => ({
      select: selectMock,
    })),
    rpc: rpcMock,
  },
}));

jest.unstable_mockModule('bcrypt', () => ({
  default: {
    compare: jest.fn(),
  },
}));

const bcrypt = (await import('bcrypt')).default;
const { eliminarCuenta } = await import('../../../interfaces/controllers/perfilController.js');

describe('HU-21 Unitarias Backend - eliminarCuenta', () => {
  let req;
  let res;

  beforeEach(() => {
    req = {
      user: { id: 21 },
      body: {},
    };

    res = {
      status: jest.fn().mockReturnThis(),
      json: jest.fn(),
    };

    jest.clearAllMocks();
  });

  test('CP-HU21-B-01 elimina cuenta local con contraseña válida', async () => {
    req.body = { password: 'ClaveValida123' };

    singleMock.mockResolvedValueOnce({
      data: {
        id: 21,
        auth_provider: 'local',
        password_hash: 'hash',
        estado: 'activo',
      },
      error: null,
    });

    bcrypt.compare.mockResolvedValue(true);
    rpcMock.mockResolvedValue({ error: null });

    await eliminarCuenta(req, res);

    expect(bcrypt.compare).toHaveBeenCalledWith('ClaveValida123', 'hash');
    expect(rpcMock).toHaveBeenCalledWith('eliminar_cuenta_usuario', {
      p_usuario_id: 21,
    });
    expect(res.status).toHaveBeenCalledWith(200);
    expect(res.json).toHaveBeenCalledWith({
      message: 'Cuenta eliminada correctamente. Tus reportes han sido conservados de forma anónima.',
    });
  });

  test('CP-HU21-B-02 rechaza eliminación local sin contraseña', async () => {
    singleMock.mockResolvedValueOnce({
      data: {
        id: 21,
        auth_provider: 'local',
        password_hash: 'hash',
        estado: 'activo',
      },
      error: null,
    });

    await eliminarCuenta(req, res);

    expect(res.status).toHaveBeenCalledWith(400);
    expect(res.json).toHaveBeenCalledWith({
      message: 'Debes confirmar tu contraseña para eliminar la cuenta',
    });
  });

  test('CP-HU21-B-03 rechaza contraseña incorrecta', async () => {
    req.body = { password: 'incorrecta' };

    singleMock.mockResolvedValueOnce({
      data: {
        id: 21,
        auth_provider: 'local',
        password_hash: 'hash',
        estado: 'activo',
      },
      error: null,
    });

    bcrypt.compare.mockResolvedValue(false);

    await eliminarCuenta(req, res);

    expect(res.status).toHaveBeenCalledWith(401);
    expect(res.json).toHaveBeenCalledWith({
      message: 'Contraseña incorrecta',
    });
  });

  test('CP-HU21-B-04 permite eliminar cuenta Google sin contraseña', async () => {
    singleMock.mockResolvedValueOnce({
      data: {
        id: 21,
        auth_provider: 'google',
        password_hash: null,
        estado: 'activo',
      },
      error: null,
    });

    rpcMock.mockResolvedValue({ error: null });

    await eliminarCuenta(req, res);

    expect(bcrypt.compare).not.toHaveBeenCalled();
    expect(rpcMock).toHaveBeenCalledWith('eliminar_cuenta_usuario', {
      p_usuario_id: 21,
    });
    expect(res.status).toHaveBeenCalledWith(200);
  });

  test('CP-HU21-B-05 rechaza usuario inexistente', async () => {
    singleMock.mockResolvedValueOnce({
      data: null,
      error: { message: 'not found' },
    });

    await eliminarCuenta(req, res);

    expect(res.status).toHaveBeenCalledWith(404);
    expect(res.json).toHaveBeenCalledWith({
      message: 'Usuario no encontrado',
    });
  });

  test('CP-HU21-B-06 rechaza cuenta no activa', async () => {
    singleMock.mockResolvedValueOnce({
      data: {
        id: 21,
        auth_provider: 'local',
        password_hash: 'hash',
        estado: 'eliminado',
      },
      error: null,
    });

    await eliminarCuenta(req, res);

    expect(res.status).toHaveBeenCalledWith(400);
    expect(res.json).toHaveBeenCalledWith({
      message: 'La cuenta ya no está activa',
    });
  });

  test('CP-HU21-B-07 maneja error RPC', async () => {
    req.body = { password: 'ClaveValida123' };

    singleMock.mockResolvedValueOnce({
      data: {
        id: 21,
        auth_provider: 'local',
        password_hash: 'hash',
        estado: 'activo',
      },
      error: null,
    });

    bcrypt.compare.mockResolvedValue(true);
    rpcMock.mockResolvedValue({ error: { message: 'rpc failed' } });

    await eliminarCuenta(req, res);

    expect(res.status).toHaveBeenCalledWith(500);
    expect(res.json).toHaveBeenCalledWith({
      message: 'rpc failed',
    });
  });
});