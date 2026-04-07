import { loginAdmin } from '../services/authService';
import api from '../services/api';

jest.mock('../services/api', () => ({
  post: jest.fn(),
}));

describe('CP-HU03-10 - Persistencia de sesión administrativa', () => {
  beforeEach(() => {
    jest.clearAllMocks();
    sessionStorage.clear();
  });

  test('CP-HU03-10: guarda admin y token en sessionStorage después del login exitoso', async () => {
    const setItemSpy = jest.spyOn(Storage.prototype, 'setItem');

    const mockResponse = {
      data: {
        user: {
          id: 1,
          correo: 'admin@saferoute.com',
          rol: 'admin',
        },
        token: 'fake-jwt-token',
      },
    };

    api.post.mockResolvedValue(mockResponse);

    const result = await loginAdmin('admin@saferoute.com', 'admin123');

    expect(api.post).toHaveBeenCalledWith('/api/auth/admin-login', {
      correo: 'admin@saferoute.com',
      password: 'admin123',
    });

    expect(setItemSpy).toHaveBeenCalledWith(
      'admin',
      JSON.stringify({
        id: 1,
        correo: 'admin@saferoute.com',
        rol: 'admin',
      })
    );

    expect(setItemSpy).toHaveBeenCalledWith('token', 'fake-jwt-token');

    expect(sessionStorage.getItem('token')).toBe('fake-jwt-token');
    expect(sessionStorage.getItem('admin')).toBe(
      JSON.stringify({
        id: 1,
        correo: 'admin@saferoute.com',
        rol: 'admin',
      })
    );

    expect(result).toEqual(mockResponse.data);

    console.log('✅ CP-HU03-10 APROBADA');
  });
});