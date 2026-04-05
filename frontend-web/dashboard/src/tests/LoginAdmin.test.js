import React from 'react';
import { render, screen, fireEvent, waitFor } from '@testing-library/react';
import { BrowserRouter } from 'react-router-dom';
import LoginAdmin from '../page/LoginAdmin';
import * as authService from '../services/authService';

const mockNavigate = jest.fn();

jest.mock('react-router-dom', () => ({
  ...jest.requireActual('react-router-dom'),
  useNavigate: () => mockNavigate,
}));

jest.mock('../services/authService', () => ({
  loginAdmin: jest.fn(),
}));

describe('Pruebas LoginAdmin - HU-03', () => {
  beforeEach(() => {
    jest.clearAllMocks();
  });

  test('CP-HU03-01: Campo correo vacío muestra error de validación', async () => {
    render(
      <BrowserRouter>
        <LoginAdmin />
      </BrowserRouter>
    );

    const correoInput = screen.getByLabelText(/Correo/i);
    expect(correoInput).toBeInTheDocument();

    const passwordInput = screen.getByLabelText(/Contraseña/i);
    fireEvent.change(passwordInput, { target: { value: 'pass123' } });

    const submitButton = screen.getByRole('button', { name: /Iniciar sesión/i });
    fireEvent.click(submitButton);

    await waitFor(() => {
      const error = screen.getByText('El correo es obligatorio');
      expect(error).toBeInTheDocument();
    });

    expect(authService.loginAdmin).not.toHaveBeenCalled();

    console.log('✅ CP-HU03-01 APROBADA');
  });

  test('CP-HU03-04: debe iniciar sesión y redirigir al dashboard cuando las credenciales son válidas', async () => {
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

    const correoInput = screen.getByLabelText(/correo/i);
    const passwordInput = screen.getByLabelText(/contraseña/i);
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

    console.log('✅ CP-HU03-04 APROBADA');
  });
});