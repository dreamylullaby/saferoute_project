import { jest } from '@jest/globals';
import { logoutUser } from '../../../interfaces/controllers/userController.js'; // ← CAMBIO AQUÍ

describe('HU-05 Backend - logoutUser', () => {
  let req, res;

  beforeEach(() => {
    req = {};

    res = {
      status: jest.fn().mockReturnThis(),
      json: jest.fn(),
    };

    jest.clearAllMocks();
  });

  test('CP-HU05-07: responde confirmando el cierre de sesión', () => {
    logoutUser(req, res);

    expect(res.json).toHaveBeenCalledWith({
      message: 'Sesión cerrada correctamente',
    });
  });
});