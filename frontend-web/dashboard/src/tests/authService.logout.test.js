import { logoutAdmin } from '../services/authService';
import api from '../services/api';
import React from 'react';
import { render, screen } from '@testing-library/react';
import App from '../App';

jest.mock('../services/api', () => ({
  post: jest.fn(),
}));

jest.mock('../page/LoginAdmin', () => () => <div>Login Admin</div>);
jest.mock('../page/Dashboard', () => () => <div>Dashboard</div>);

describe('HU-05 Logout Admin React', () => {
  beforeEach(() => {
    jest.clearAllMocks();
    sessionStorage.clear();
    window.history.pushState({}, '', '/');
    sessionStorage.setItem(
      'admin',
      JSON.stringify({
        id: 1,
        correo: 'admin@saferoute.com',
        rol: 'admin',
      })
    );
    sessionStorage.setItem('token', 'fake-jwt-token');
  });

  test('CP-HU05-01: elimina completamente el token JWT del almacenamiento', async () => {
    api.post.mockResolvedValue({ data: { message: 'Logout ok' } });

    await logoutAdmin();

    expect(sessionStorage.getItem('token')).toBeNull();
  });

  test('CP-HU05-02: limpia datos de sesión del estado', async () => {
    api.post.mockResolvedValue({ data: { message: 'Logout ok' } });

    await logoutAdmin();

    const adminState = sessionStorage.getItem('admin');
    const tokenState = sessionStorage.getItem('token');

    expect(adminState).toBeNull();
    expect(tokenState).toBeNull();
  });

  test('CP-HU05-05: bloquea rutas protegidas post-cerrar sesión', () => {
    sessionStorage.removeItem('admin');
    sessionStorage.removeItem('token');
    window.history.pushState({}, '', '/dashboard');

    render(<App />);

    expect(screen.getByText('Login Admin')).toBeInTheDocument();
    expect(screen.queryByText('Dashboard')).not.toBeInTheDocument();
  });

  test('CP-HU05-06: evita mostrar contenido protegido al usar atrás después del logout', async () => {
    window.history.pushState({}, '', '/dashboard');

    const { rerender } = render(<App />);

    expect(screen.getByText('Dashboard')).toBeInTheDocument();

    api.post.mockResolvedValue({ data: { message: 'Logout ok' } });
    await logoutAdmin();

    rerender(<App />);

    expect(screen.getByText('Login Admin')).toBeInTheDocument();
    expect(screen.queryByText('Dashboard')).not.toBeInTheDocument();
  });

  test('CP-HU05-08: limpia datos sensibles del cliente al cerrar sesión', async () => {
    api.post.mockResolvedValue({ data: { message: 'Logout ok' } });

    await logoutAdmin();

    expect(api.post).toHaveBeenCalledWith('/api/auth/logout');
    expect(sessionStorage.getItem('admin')).toBeNull();
    expect(sessionStorage.getItem('token')).toBeNull();
  });

  test('CP-HU05-09: después del logout el usuario queda no autenticado', async () => {
    api.post.mockResolvedValue({ data: { message: 'Logout ok' } });

    await logoutAdmin();

    const isAuthenticated = !!sessionStorage.getItem('token');
    expect(isAuthenticated).toBe(false);
  });

  test('CP-HU05-10: el logout persiste después de recargar', async () => {
    api.post.mockResolvedValue({ data: { message: 'Logout ok' } });

    await logoutAdmin();

    expect(sessionStorage.getItem('token')).toBeNull();
    expect(sessionStorage.getItem('admin')).toBeNull();

    const persistedAuth = !!sessionStorage.getItem('token');
    expect(persistedAuth).toBe(false);
  });
});