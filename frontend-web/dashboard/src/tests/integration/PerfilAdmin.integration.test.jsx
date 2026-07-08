import React from "react";
import { describe, test, expect, beforeEach, vi } from "vitest";
import { render, screen, waitFor } from "@testing-library/react";
import userEvent from "@testing-library/user-event";
import { MemoryRouter, Routes, Route } from "react-router-dom";
import "@testing-library/jest-dom/vitest";

import PerfilAdminPage from "../../page/tabs/TabPerfil.jsx";
import api from "../../services/api.js";

const mockNavigate = vi.fn();

vi.mock("react-router-dom", async () => {
  const actual = await vi.importActual("react-router-dom");
  return {
    ...actual,
    useNavigate: () => mockNavigate,
  };
});

vi.mock("../../services/api.js", () => ({
  default: {
    get: vi.fn(),
    put: vi.fn(),
    patch: vi.fn(),
    post: vi.fn(),
    delete: vi.fn(),
  },
}));

function renderPerfil() {
  return render(
    <MemoryRouter initialEntries={["/perfil"]}>
      <Routes>
        <Route path="/perfil" element={<PerfilAdminPage />} />
        <Route path="/login" element={<div>Login Screen</div>} />
      </Routes>
    </MemoryRouter>
  );
}

describe("HU-19 Integrales React - Perfil Admin", () => {
  beforeEach(() => {
    vi.clearAllMocks();

    localStorage.clear();
    sessionStorage.clear();

    localStorage.setItem("token", "fake-token");
    localStorage.setItem("admin_dark", "false");
    localStorage.setItem("admin_lang", "es");

    sessionStorage.setItem(
      "admin",
      JSON.stringify({
        email: "admin@saferoute.com",
        username: "AdminLuna",
        foto_url: "https://test.com/foto.png",
        created_at: "2026-05-01T10:00:00.000Z",
        notificaciones_activas: true,
        rol: "Usuario",
        auth_provider: "local",
      })
    );

    Object.defineProperty(navigator, "clipboard", {
      configurable: true,
      value: {
        writeText: vi.fn().mockResolvedValue(undefined),
      },
    });

    api.get.mockResolvedValue({
      data: {
        data: {
          id: "admin-1",
          correo: "admin@saferoute.com",
          username: "AdminLuna",
          foto_url: "https://test.com/foto.png",
          fecha_creacion: "2026-05-01T10:00:00.000Z",
          notificaciones_activas: true,
          rol: "user",
          auth_provider: "local",
        },
      },
    });

    api.patch.mockResolvedValue({
      data: {
        data: {
          username: "AdminLuna",
        },
      },
    });

    api.put.mockResolvedValue({
      data: {
        success: true,
      },
    });
  });

  test("CP-HU19-I-01 carga y muestra datos del perfil", async () => {
    renderPerfil();

    expect(await screen.findByText(/adminluna/i)).toBeInTheDocument();
    expect(screen.getByText(/información de la cuenta/i)).toBeInTheDocument();
    expect(screen.getByText(/editar perfil/i)).toBeInTheDocument();
    expect(screen.getByText(/seguridad/i)).toBeInTheDocument();
    expect(screen.getByText(/preferencias/i)).toBeInTheDocument();

    await waitFor(() => {
      expect(api.get).toHaveBeenCalledTimes(1);
    });
  });

  test("CP-HU19-I-02 actualiza apodo y ejecuta guardado", async () => {
    const user = userEvent.setup();

    api.patch.mockResolvedValueOnce({
      data: {
        data: {
          username: "AdminSeguro",
        },
      },
    });

    renderPerfil();

    const usernameInput = await screen.findByDisplayValue(/AdminLuna/i);
    await user.clear(usernameInput);
    await user.type(usernameInput, "AdminSeguro");

    await user.click(screen.getByRole("button", { name: /^guardar$/i }));

    await waitFor(() => {
      expect(api.patch).toHaveBeenCalledWith("/api/perfil", {
        username: "AdminSeguro",
      });
    });

    await waitFor(() => {
      expect(screen.getByDisplayValue("AdminSeguro")).toBeInTheDocument();
    });
  });

  test("CP-HU19-I-03 cambia contraseña exitosamente", async () => {
  const user = userEvent.setup();

  api.put.mockResolvedValueOnce({
    data: {
      success: true,
    },
  });

  const { container } = renderPerfil();

  await screen.findByText(/seguridad/i);

  const passwordInputs = container.querySelectorAll('input[type="password"]');
  expect(passwordInputs.length).toBeGreaterThanOrEqual(3);

  await user.type(passwordInputs[0], "Anterior123");
  await user.type(passwordInputs[1], "NuevaSegura123");
  await user.type(passwordInputs[2], "NuevaSegura123");

  await user.click(screen.getByRole("button", { name: /cambiar contraseña/i }));

  await waitFor(() => {
    expect(api.put).toHaveBeenCalledWith("/api/perfil/password", {
      passwordActual: "Anterior123",
      nuevaPassword: "NuevaSegura123",
    });
  });
});

  test("CP-HU19-I-04 cambia modo oscuro y actualiza preferencias locales", async () => {
    const user = userEvent.setup();

    renderPerfil();

    await screen.findByText(/preferencias/i);

    expect(document.documentElement).toHaveAttribute("data-theme", "light");

    const buttons = screen.getAllByRole("button");
    const darkModeButton = buttons.find(
      (btn) =>
        btn.textContent?.trim() === "" &&
        btn.getAttribute("title") !== "Copiar correo"
    );

    expect(darkModeButton).toBeTruthy();

    await user.click(darkModeButton);

    await waitFor(() => {
      expect(document.documentElement).toHaveAttribute("data-theme", "dark");
      expect(localStorage.getItem("admin_dark")).toBe("true");
    });

    expect(api.patch).not.toHaveBeenCalled();
    expect(api.put).not.toHaveBeenCalled();
  });

  test("CP-HU19-I-05 muestra acciones principales del perfil", async () => {
    renderPerfil();

    expect(await screen.findByRole("button", { name: /guardar/i })).toBeInTheDocument();
    expect(screen.getByRole("button", { name: /cambiar contraseña/i })).toBeInTheDocument();
    expect(screen.getByRole("button", { name: /copiar correo/i })).toBeInTheDocument();
  });
});