import React from 'react';
import { render, screen } from '@testing-library/react';
import { describe, test, expect, beforeEach, vi } from 'vitest';
import { logoutAdmin } from '../services/authService';
import api from '../services/api';
import App from '../App';

vi.mock('../services/api', () => ({
  default: {
    post: vi.fn(),
  },
}));

vi.mock('../page/LoginAdmin', () => ({
  default: () => <div>Login Admin</div>,
}));

vi.mock('../page/Dashboard', () => ({
  default: () => <div>Dashboard</div>,
}));

describe('HU-05 Logout Admin React', () => {
  beforeEach(() => {
    vi.clearAllMocks();
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

  test('CP-H05-F-01: elimina completamente el token JWT del almacenamiento', async () => {
    api.post.mockResolvedValue({ data: { message: 'Logout ok' } });

    await logoutAdmin();

    expect(sessionStorage.getItem('token')).toBeNull();
  });

  test('CP-H05-F-02: limpia datos de sesión del estado', async () => {
    api.post.mockResolvedValue({ data: { message: 'Logout ok' } });

    await logoutAdmin();

    const adminState = sessionStorage.getItem('admin');
    const tokenState = sessionStorage.getItem('token');

    expect(adminState).toBeNull();
    expect(tokenState).toBeNull();
  });

  test('CP-H05-F-03: bloquea rutas protegidas post-cerrar sesión', () => {
    sessionStorage.removeItem('admin');
    sessionStorage.removeItem('token');
    window.history.pushState({}, '', '/dashboard');

    render(<App />);

    expect(screen.getByText('Login Admin')).toBeInTheDocument();
    expect(screen.queryByText('Dashboard')).not.toBeInTheDocument();
  });

  test('CP-H05-F-04: evita mostrar contenido protegido al usar atrás después del logout', async () => {
    window.history.pushState({}, '', '/dashboard');

    const { rerender } = render(<App />);

    expect(screen.getByText('Dashboard')).toBeInTheDocument();

    api.post.mockResolvedValue({ data: { message: 'Logout ok' } });
    await logoutAdmin();

    rerender(<App />);

    expect(screen.getByText('Login Admin')).toBeInTheDocument();
    expect(screen.queryByText('Dashboard')).not.toBeInTheDocument();
  });

  test('CP-H05-F-05: limpia datos sensibles del cliente al cerrar sesión', async () => {
    api.post.mockResolvedValue({ data: { message: 'Logout ok' } });

    await logoutAdmin();

    expect(api.post).toHaveBeenCalledWith('/api/auth/logout');
    expect(sessionStorage.getItem('admin')).toBeNull();
    expect(sessionStorage.getItem('token')).toBeNull();
  });

  test('CP-H05-F-06: después del logout el usuario queda no autenticado', async () => {
    api.post.mockResolvedValue({ data: { message: 'Logout ok' } });

    await logoutAdmin();

    const isAuthenticated = !!sessionStorage.getItem('token');
    expect(isAuthenticated).toBe(false);
  });

  test('CP-H05-F-07: el logout persiste después de recargar', async () => {
    api.post.mockResolvedValue({ data: { message: 'Logout ok' } });

    await logoutAdmin();

    expect(sessionStorage.getItem('token')).toBeNull();
    expect(sessionStorage.getItem('admin')).toBeNull();

    const persistedAuth = !!sessionStorage.getItem('token');
    expect(persistedAuth).toBe(false);
  });
});