import React from "react";
import "@testing-library/jest-dom";
import { describe, test, expect, beforeEach, vi } from "vitest";
import { render, screen, fireEvent, waitFor } from "@testing-library/react";
import { MemoryRouter, Routes, Route } from "react-router-dom";

import ForgotPassword from "../../page/ForgotPassword";
import ResetPassword from "../../page/ResetPassword";
import api from "../../services/api";

const mockNavigate = vi.fn();
let mockToken = "token-valido";

vi.mock("../../services/api", () => ({
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

function renderForgotPassword() {
  return render(
    <MemoryRouter initialEntries={["/forgot-password"]}>
      <Routes>
        <Route path="/forgot-password" element={<ForgotPassword />} />
      </Routes>
    </MemoryRouter>
  );
}

function renderResetPassword() {
  return render(
    <MemoryRouter initialEntries={[`/reset-password?token=${mockToken}`]}>
      <Routes>
        <Route path="/reset-password" element={<ResetPassword />} />
      </Routes>
    </MemoryRouter>
  );
}

function getPasswordInputs(container) {
  const inputs = container.querySelectorAll('input[type="password"]');
  expect(inputs.length).toBeGreaterThanOrEqual(2);
  return inputs;
}

describe("HU-13 Pruebas Integrales Frontend Web", () => {
  beforeEach(() => {
    vi.clearAllMocks();
    mockToken = "token-valido";
  });

  test("PI-HU13-FE-01 correo válido solicita recuperación y muestra confirmación", async () => {
    api.post.mockResolvedValueOnce({ data: { ok: true, message: "Correo enviado" } });

    renderForgotPassword();

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
    console.log("✓ PI-HU13-FE-01 correo válido solicita recuperación y muestra confirmación");
  });

  test("PI-HU13-FE-02 correo inválido bloquea la solicitud", async () => {
    renderForgotPassword();

    fireEvent.change(screen.getByPlaceholderText("admin@saferoute.com"), {
      target: { value: "correo-invalido" },
    });

    fireEvent.click(screen.getByRole("button", { name: /enviar enlace/i }));

    await waitFor(() => {
      expect(api.post).not.toHaveBeenCalled();
    });

    console.log("✓ PI-HU13-FE-02 correo inválido bloquea la solicitud");
  });

  test("PI-HU13-FE-03 token inválido muestra enlace inválido", async () => {
    mockToken = "";

    renderResetPassword();

    expect(
      screen.getByText(/enlace inválido|solicita uno nuevo/i)
    ).toBeInTheDocument();

    expect(screen.getByRole("button", { name: /cambiar contraseña/i })).toBeDisabled();
    console.log("✓ PI-HU13-FE-03 token inválido muestra enlace inválido");
  });

  test("PI-HU13-FE-04 token válido restablece contraseña y redirige al login", async () => {
    api.post.mockResolvedValueOnce({ data: { ok: true, message: "Contraseña actualizada" } });

    const { container } = renderResetPassword();
    const inputs = getPasswordInputs(container);

    fireEvent.change(inputs[0], { target: { value: "Password123" } });
    fireEvent.change(inputs[1], { target: { value: "Password123" } });

    fireEvent.click(screen.getByRole("button", { name: /cambiar contraseña/i }));

    await waitFor(() => {
      expect(api.post).toHaveBeenCalledWith("/api/auth/reset-password", {
        token: "token-valido",
        nuevaPassword: "Password123",
      });
    });

    expect(mockNavigate).toHaveBeenCalled();
    console.log("✓ PI-HU13-FE-04 token válido restablece contraseña y redirige al login");
  });
});