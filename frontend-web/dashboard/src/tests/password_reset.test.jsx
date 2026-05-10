import React from "react";
import "@testing-library/jest-dom";
import { describe, test, expect, beforeEach, vi } from "vitest";
import { render, screen, fireEvent, waitFor } from "@testing-library/react";
import { MemoryRouter } from "react-router-dom";

import ForgotPassword from "../page/ForgotPassword";
import ResetPassword from "../page/ResetPassword";
import api from "../services/api";

const mockNavigate = vi.fn();
let mockToken = "token-valido";

vi.mock("../services/api", () => ({
  default: {
    post: vi.fn(),
  },
}));

vi.mock("react-router-dom", async () => {
  const actual = await vi.importActual("react-router-dom");
  return {
    ...actual,
    useNavigate: () => mockNavigate,
    useSearchParams: () => [new URLSearchParams(mockToken ? `token=${mockToken}` : "")],
  };
});

function renderWithRouter(ui) {
  return render(<MemoryRouter>{ui}</MemoryRouter>);
}

describe("HU-13 Frontend Web - ForgotPassword y ResetPassword", () => {
  beforeEach(() => {
    vi.clearAllMocks();
    mockToken = "token-valido";
  });

  describe("ForgotPassword", () => {
    test("CP-HU13-FE-W-02 muestra error si el correo está vacío", async () => {
      renderWithRouter(<ForgotPassword />);

      fireEvent.click(screen.getByRole("button", { name: /enviar enlace/i }));

      expect(screen.getByText("Ingresa un correo válido")).toBeInTheDocument();
      expect(api.post).not.toHaveBeenCalled();
    });

    test("CP-HU13-FE-W-02 muestra error si el correo es inválido", async () => {
      renderWithRouter(<ForgotPassword />);

      fireEvent.change(screen.getByPlaceholderText("admin@saferoute.com"), {
        target: { value: "correo-invalido" },
      });

      fireEvent.click(screen.getByRole("button", { name: /enviar enlace/i }));

      expect(api.post).not.toHaveBeenCalled();
    });

    test("CP-HU13-FE-W-01 envía solicitud con correo válido y muestra estado de éxito", async () => {
      api.post.mockResolvedValueOnce({ data: { message: "ok" } });

      renderWithRouter(<ForgotPassword />);

      fireEvent.change(screen.getByPlaceholderText("admin@saferoute.com"), {
        target: { value: "admin@saferoute.com" },
      });

      fireEvent.click(screen.getByRole("button", { name: /enviar enlace/i }));

      await waitFor(() => {
        expect(api.post).toHaveBeenCalledWith("/api/auth/forgot-password", {
          correo: "admin@saferoute.com",
          plataforma: "web",
        });
      });

      expect(screen.getByText(/revisa tu correo/i)).toBeInTheDocument();
    });

    test("muestra error genérico si la solicitud falla", async () => {
      api.post.mockRejectedValueOnce(new Error("network error"));

      renderWithRouter(<ForgotPassword />);

      fireEvent.change(screen.getByPlaceholderText("admin@saferoute.com"), {
        target: { value: "admin@saferoute.com" },
      });

      fireEvent.click(screen.getByRole("button", { name: /enviar enlace/i }));

      await waitFor(() => {
        expect(screen.getByText(/error al procesar la solicitud/i)).toBeInTheDocument();
      });
    });

    test("renderiza link para volver al login", () => {
      renderWithRouter(<ForgotPassword />);
      expect(screen.getByText("Volver al login")).toBeInTheDocument();
    });
  });

  describe("ResetPassword", () => {
    const getPasswordInputs = (container) => {
      const inputs = container.querySelectorAll('input[type="password"]');
      expect(inputs.length).toBeGreaterThanOrEqual(2);
      return inputs;
    };

    test("CP-HU13-FE-W-09 muestra error si no hay token en la URL", () => {
      mockToken = "";

      renderWithRouter(<ResetPassword />);

      expect(
        screen.getByText(/enlace inválido|solicita uno nuevo/i)
      ).toBeInTheDocument();

      expect(screen.getByRole("button", { name: /cambiar contraseña/i })).toBeDisabled();
    });

    test("CP-HU13-FE-W-07 valida longitud mínima de contraseña", async () => {
      const { container } = renderWithRouter(<ResetPassword />);
      const inputs = getPasswordInputs(container);

      fireEvent.change(inputs[0], { target: { value: "12345" } });
      fireEvent.change(inputs[1], { target: { value: "12345" } });

      fireEvent.click(screen.getByRole("button", { name: /cambiar contraseña/i }));

      expect(screen.getByText(/8 caracteres|mínimo/i)).toBeInTheDocument();
      expect(api.post).not.toHaveBeenCalled();
    });

    test("CP-HU13-FE-W-06 valida que las contraseñas coincidan", async () => {
      const { container } = renderWithRouter(<ResetPassword />);
      const inputs = getPasswordInputs(container);

      fireEvent.change(inputs[0], { target: { value: "Password123" } });
      fireEvent.change(inputs[1], { target: { value: "Password999" } });

      fireEvent.click(screen.getByRole("button", { name: /cambiar contraseña/i }));

      expect(screen.getByText(/no coinciden/i)).toBeInTheDocument();
      expect(api.post).not.toHaveBeenCalled();
    });

    test("CP-HU13-FE-W-05 restablece contraseña y navega al login", async () => {
      api.post.mockResolvedValueOnce({ data: { message: "ok" } });

      const { container } = renderWithRouter(<ResetPassword />);
      const inputs = getPasswordInputs(container);

      fireEvent.change(inputs[0], { target: { value: "Password123" } });
      fireEvent.change(inputs[1], { target: { value: "Password123" } });

      fireEvent.click(screen.getByRole("button", { name: /cambiar contraseña/i }));

      await waitFor(() => {
        expect(api.post).toHaveBeenCalled();
      });

      expect(mockNavigate).toHaveBeenCalled();
    });

    test("muestra mensaje del backend si reset falla con response.data.message", async () => {
      api.post.mockRejectedValueOnce({
        response: { data: { message: "Token expirado o inválido" } },
      });

      const { container } = renderWithRouter(<ResetPassword />);
      const inputs = getPasswordInputs(container);

      fireEvent.change(inputs[0], { target: { value: "Password123" } });
      fireEvent.change(inputs[1], { target: { value: "Password123" } });

      fireEvent.click(screen.getByRole("button", { name: /cambiar contraseña/i }));

      await waitFor(() => {
        expect(screen.getByText(/token expirado o inválido/i)).toBeInTheDocument();
      });
    });

    test("muestra error genérico si reset falla sin mensaje del backend", async () => {
      api.post.mockRejectedValueOnce(new Error("network error"));

      const { container } = renderWithRouter(<ResetPassword />);
      const inputs = getPasswordInputs(container);

      fireEvent.change(inputs[0], { target: { value: "Password123" } });
      fireEvent.change(inputs[1], { target: { value: "Password123" } });

      fireEvent.click(screen.getByRole("button", { name: /cambiar contraseña/i }));

      await waitFor(() => {
        expect(screen.getByText(/error al restablecer la contraseña/i)).toBeInTheDocument();
      });
    });

    test("renderiza link para volver al login", () => {
      renderWithRouter(<ResetPassword />);
      expect(screen.getByText("Volver al login")).toBeInTheDocument();
    });
  });
});