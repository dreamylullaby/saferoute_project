import React from 'react';
import { render, screen, fireEvent, waitFor } from '@testing-library/react';
import { BrowserRouter } from 'react-router-dom';
import { describe, test, expect, beforeEach, vi } from 'vitest';
import LoginAdmin from '../page/LoginAdmin';
import * as authService from '../services/authService';

const mockNavigate = vi.fn();

vi.mock('react-router-dom', async () => {
  const actual = await vi.importActual('react-router-dom');
  return {
    ...actual,
    useNavigate: () => mockNavigate,
  };
});

vi.mock('../services/authService', () => ({
  loginAdmin: vi.fn(),
}));

describe('Pruebas LoginAdmin - HU-03', () => {
  beforeEach(() => {
    vi.clearAllMocks();
  });

  test('CP-H03-F-01: campo correo vacío muestra error de validación', async () => {
    render(
      <BrowserRouter>
        <LoginAdmin />
      </BrowserRouter>
    );

    const correoInput = screen.getByLabelText(/correo/i, { selector: 'input' });
    expect(correoInput).toBeInTheDocument();

    const passwordInput = screen.getByLabelText(/contraseña/i, {
      selector: 'input',
    });
    fireEvent.change(passwordInput, { target: { value: 'pass123' } });

    const submitButton = screen.getByRole('button', { name: /iniciar sesión/i });
    fireEvent.click(submitButton);

    await waitFor(() => {
      expect(screen.getByText('El correo es obligatorio')).toBeInTheDocument();
    });

    expect(authService.loginAdmin).not.toHaveBeenCalled();
  });

  test('CP-H03-F-02: debe iniciar sesión y redirigir al dashboard cuando las credenciales son válidas', async () => {
    authService.loginAdmin.mockResolvedValue({
      user: {
        id: 1,
        correo: 'admin@saferoute.com',
        rol: 'admin',
      },
      token: 'fake-jwt-token',
    });

    render(
      <BrowserRouter>
        <LoginAdmin />
      </BrowserRouter>
    );

    const correoInput = screen.getByLabelText(/correo/i, { selector: 'input' });
    const passwordInput = screen.getByLabelText(/contraseña/i, {
      selector: 'input',
    });
    const submitButton = screen.getByRole('button', { name: /iniciar sesión/i });

    fireEvent.change(correoInput, {
      target: { value: 'admin@saferoute.com' },
    });

    fireEvent.change(passwordInput, {
      target: { value: 'admin123' },
    });

    fireEvent.click(submitButton);

    await waitFor(() => {
      expect(authService.loginAdmin).toHaveBeenCalledWith(
        'admin@saferoute.com',
        'admin123'
      );
    });

    expect(mockNavigate).toHaveBeenCalledWith('/dashboard');
    expect(screen.queryByText(/error al iniciar sesión/i)).not.toBeInTheDocument();
  });
});