import React from "react";
import { describe, test, expect, vi, beforeEach, afterEach } from "vitest";
import "@testing-library/jest-dom/vitest";
import {
  render,
  screen,
  waitFor,
  within,
  fireEvent,
} from "@testing-library/react";
import userEvent from "@testing-library/user-event";
import TabUsuarios from "../page/tabs/TabUsuarios.jsx";
import api from "../services/api.js";

vi.mock("../services/api.js", () => ({
  default: {
    get: vi.fn(),
    patch: vi.fn(),
    delete: vi.fn(),
  },
}));

function deferred() {
  let resolve;
  let reject;
  const promise = new Promise((res, rej) => {
    resolve = res;
    reject = rej;
  });
  return { promise, resolve, reject };
}

const respuestaBase = {
  data: {
    success: true,
    data: [
      {
        id: "u1",
        username: "ana",
        correo: "ana@test.com",
        rol: "usuario",
        estado: "activo",
        fecha_creacion: "2026-05-01T10:00:00.000Z",
      },
      {
        id: "u2",
        username: "carlos",
        correo: "carlos@test.com",
        rol: "usuario",
        estado: "bloqueado",
        fecha_creacion: "2026-05-02T10:00:00.000Z",
      },
      {
        id: "u3",
        username: "root",
        correo: "admin@test.com",
        rol: "admin",
        estado: "activo",
        fecha_creacion: "2026-05-03T10:00:00.000Z",
      },
    ],
    total: 3,
    totalPages: 1,
  },
};

describe("HU-14 TabUsuarios frontend unitario", () => {
  beforeEach(() => {
    sessionStorage.clear();
    sessionStorage.setItem("token", "token-fake");
    api.get.mockReset();
    api.patch.mockReset();
    api.delete.mockReset();
  });

  afterEach(() => {
    vi.useRealTimers();
  });

  test("CP-HU14-F-01 carga inicial del listado", async () => {
    api.get.mockResolvedValueOnce(respuestaBase);

    render(<TabUsuarios />);

    await waitFor(() => {
      expect(api.get).toHaveBeenCalledWith("/api/admin/usuarios", {
        params: { page: 1, limit: 10 },
      });
    });

    expect(screen.getByText("ana")).toBeInTheDocument();
    expect(screen.getByText("carlos")).toBeInTheDocument();
    expect(screen.getByText("admin@test.com")).toBeInTheDocument();
    console.log("✓ CP-HU14-F-01 carga inicial del listado");
  });

  test("CP-HU14-F-02 muestra cargando mientras la API responde", async () => {
    const req = deferred();
    api.get.mockReturnValueOnce(req.promise);

    render(<TabUsuarios />);

    expect(screen.getByText("Cargando...")).toBeInTheDocument();

    req.resolve(respuestaBase);

    await waitFor(() => {
      expect(screen.queryByText("Cargando...")).not.toBeInTheDocument();
    });
    console.log("✓ CP-HU14-F-02 muestra cargando mientras la API responde");
  });

  test("CP-HU14-F-03 renderiza acciones correctas por estado", async () => {
    api.get.mockResolvedValueOnce(respuestaBase);

    render(<TabUsuarios />);

    await waitFor(() => {
      expect(screen.getByText("ana")).toBeInTheDocument();
    });

    expect(screen.getByRole("button", { name: "Bloquear" })).toBeInTheDocument();
    expect(screen.getByRole("button", { name: "Reactivar" })).toBeInTheDocument();
    console.log("✓ CP-HU14-F-03 renderiza acciones correctas por estado");
  });

  test("CP-HU14-F-04 usuario admin no muestra acciones destructivas", async () => {
    api.get.mockResolvedValueOnce(respuestaBase);

    render(<TabUsuarios />);

    await waitFor(() => {
      expect(screen.getByText("root")).toBeInTheDocument();
    });

    expect(screen.getAllByText("—").length).toBeGreaterThan(0);
    console.log("✓ CP-HU14-F-04 usuario admin no muestra acciones destructivas");
  });

  test("CP-HU14-F-05 búsqueda con debounce consulta con q", async () => {
    vi.useFakeTimers({ shouldAdvanceTime: true });
    api.get.mockResolvedValue(respuestaBase);

    render(<TabUsuarios />);

    expect(await screen.findByText("ana")).toBeInTheDocument();

    const input = screen.getByPlaceholderText("Buscar por nombre o correo...");
    fireEvent.change(input, { target: { value: "ana" } });

    expect(input).toHaveValue("ana");

    await vi.runAllTimersAsync();

    expect(api.get).toHaveBeenLastCalledWith("/api/admin/usuarios", {
      params: { page: 1, limit: 10, q: "ana" },
    });
    console.log("✓ CP-HU14-F-05 búsqueda con debounce consulta con q");
  }, 10000);

  test("CP-HU14-F-06 filtro por estado consulta con estado=bloqueado", async () => {
    api.get.mockResolvedValue(respuestaBase);
    const user = userEvent.setup();

    render(<TabUsuarios />);

    await waitFor(() => {
      expect(screen.getByText("ana")).toBeInTheDocument();
    });

    await user.click(screen.getByRole("button", { name: "Todos" }));

    const panel = document.querySelector(".cs-panel");
    expect(panel).toBeTruthy();

    const opcionBloqueado = within(panel).getByText("Bloqueado");
    await user.click(opcionBloqueado);

    await waitFor(() => {
      expect(api.get).toHaveBeenLastCalledWith("/api/admin/usuarios", {
        params: { page: 1, limit: 10, estado: "bloqueado" },
      });
    });
    console.log("✓ CP-HU14-F-06 filtro por estado consulta con estado=bloqueado");
  });

  test("CP-HU14-F-07 limpiar filtros reinicia búsqueda y estado", async () => {
    api.get.mockResolvedValue(respuestaBase);
    const user = userEvent.setup();

    render(<TabUsuarios />);

    await waitFor(() => {
      expect(screen.getByText("ana")).toBeInTheDocument();
    });

    const input = screen.getByPlaceholderText("Buscar por nombre o correo...");
    await user.type(input, "ana");

    expect(input).toHaveValue("ana");

    await user.click(screen.getByRole("button", { name: "Limpiar" }));

    await waitFor(() => {
      expect(input).toHaveValue("");
    });

    await waitFor(() => {
      expect(api.get).toHaveBeenLastCalledWith("/api/admin/usuarios", {
        params: { page: 1, limit: 10 },
      });
    });
    console.log("✓ CP-HU14-F-07 limpiar filtros reinicia búsqueda y estado");
  });

  test("CP-HU14-F-08 abrir modal de bloqueo", async () => {
    api.get.mockResolvedValueOnce(respuestaBase);
    const user = userEvent.setup();

    render(<TabUsuarios />);

    await waitFor(() => {
      expect(screen.getByText("ana")).toBeInTheDocument();
    });

    await user.click(screen.getByRole("button", { name: "Bloquear" }));

    expect(screen.getByText("Confirmar acción")).toBeInTheDocument();
    expect(screen.getByText(/¿Estás seguro de/i)).toBeInTheDocument();
    console.log("✓ CP-HU14-F-08 abrir modal de bloqueo");
  });

  test("CP-HU14-F-09 bloqueo exitoso muestra toast y recarga", async () => {
    api.get.mockResolvedValue(respuestaBase);
    api.patch.mockResolvedValueOnce({
      data: { success: true, message: "Usuario bloqueado correctamente" },
    });

    const user = userEvent.setup();
    render(<TabUsuarios />);

    await waitFor(() => {
      expect(screen.getByText("ana")).toBeInTheDocument();
    });

    const filaAna = screen.getByRole("row", {
      name: /AN ana ana@test\.com Usuario Activo .* Bloquear Ocultar/i,
    });

    const botonAbrir = within(filaAna).getByRole("button", { name: "Bloquear" });
    await user.click(botonAbrir);

    const tituloModal = await screen.findByText("Confirmar acción");
    const modal = tituloModal.parentElement;
    expect(modal).toBeTruthy();

    const botonConfirmar = within(modal).getByRole("button", { name: "Bloquear" });
    await user.click(botonConfirmar);

    await waitFor(() => {
      expect(api.patch).toHaveBeenCalledWith("/api/admin/usuarios/u1/bloquear");
    });

    expect(await screen.findByText("Usuario bloquear correctamente")).toBeInTheDocument();
    console.log("✓ CP-HU14-F-09 bloqueo exitoso muestra toast y recarga");
  });

  test("CP-HU14-F-10 reactivación exitosa muestra toast y recarga", async () => {
    api.get.mockResolvedValue(respuestaBase);
    api.patch.mockResolvedValueOnce({
      data: { success: true, message: "Usuario reactivado correctamente" },
    });

    const user = userEvent.setup();
    render(<TabUsuarios />);

    await waitFor(() => {
      expect(screen.getByText("carlos")).toBeInTheDocument();
    });

    const filaCarlos = screen.getByRole("row", {
      name: /CA carlos carlos@test\.com Usuario Bloqueado .* Reactivar Eliminar/i,
    });

    const botonAbrir = within(filaCarlos).getByRole("button", { name: "Reactivar" });
    await user.click(botonAbrir);

    const tituloModal = await screen.findByText("Confirmar acción");
    const modal = tituloModal.parentElement;
    expect(modal).toBeTruthy();

    const botonConfirmar = within(modal).getByRole("button", { name: "Reactivar" });
    await user.click(botonConfirmar);

    await waitFor(() => {
      expect(api.patch).toHaveBeenCalledWith("/api/admin/usuarios/u2/reactivar");
    });

    expect(await screen.findByText("Usuario reactivar correctamente")).toBeInTheDocument();
    console.log("✓ CP-HU14-F-10 reactivación exitosa muestra toast y recarga");
  });

  test("CP-HU14-F-11 error en acción muestra toast error", async () => {
    api.get.mockResolvedValue(respuestaBase);
    api.patch.mockRejectedValueOnce({
      response: { data: { message: "No se puede bloquear a un administrador" } },
    });

    const user = userEvent.setup();
    render(<TabUsuarios />);

    await waitFor(() => {
      expect(screen.getByText("ana")).toBeInTheDocument();
    });

    const filaAna = screen.getByRole("row", {
      name: /AN ana ana@test\.com Usuario Activo .* Bloquear Ocultar/i,
    });

    const botonAbrir = within(filaAna).getByRole("button", { name: "Bloquear" });
    await user.click(botonAbrir);

    const tituloModal = await screen.findByText("Confirmar acción");
    const modal = tituloModal.parentElement;
    expect(modal).toBeTruthy();

    const botonConfirmar = within(modal).getByRole("button", { name: "Bloquear" });
    await user.click(botonConfirmar);

    await waitFor(() => {
      expect(api.patch).toHaveBeenCalledWith("/api/admin/usuarios/u1/bloquear");
    });

    expect(await screen.findByText("No se puede bloquear a un administrador")).toBeInTheDocument();
    console.log("✓ CP-HU14-F-11 error en acción muestra toast error");
  });

  test("CP-HU14-F-12 paginación llama siguiente página", async () => {
    api.get
      .mockResolvedValueOnce({
        data: {
          success: true,
          data: respuestaBase.data.data,
          total: 25,
          totalPages: 3,
        },
      })
      .mockResolvedValueOnce({
        data: {
          success: true,
          data: respuestaBase.data.data,
          total: 25,
          totalPages: 3,
        },
      });

    const user = userEvent.setup();
    render(<TabUsuarios />);

    await waitFor(() => {
      expect(screen.getByText("ana")).toBeInTheDocument();
    });

    await user.click(screen.getByRole("button", { name: /Siguiente/i }));

    await waitFor(() => {
      expect(api.get).toHaveBeenLastCalledWith("/api/admin/usuarios", {
        params: { page: 2, limit: 10 },
      });
    });
    console.log("✓ CP-HU14-F-12 paginación llama siguiente página");
  });
});