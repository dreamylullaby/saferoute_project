import React from "react";
import { render, screen, waitFor, fireEvent, within } from "@testing-library/react";
import userEvent from "@testing-library/user-event";
import { describe, test, expect, beforeEach, vi } from "vitest";
import TabSolicitudes from "../page/tabs/TabSolicitudes.jsx";
import api from "../services/api.js";

vi.mock("../services/api.js", () => ({
  default: {
    get: vi.fn(),
    post: vi.fn(),
  },
}));

vi.mock("../components/CustomSelect.jsx", () => ({
  default: function MockCustomSelect({ value, onChange, options }) {
    return (
      <select
        data-testid="estado-filter"
        value={value}
        onChange={(e) => onChange(e.target.value)}
      >
        {options.map((o) => (
          <option key={o.value} value={o.value}>
            {o.label}
          </option>
        ))}
      </select>
    );
  },
}));

const solicitudesMock = [
  {
    id: "sol-1",
    reporte_id: "rep-11111111",
    usuario_id: "usr-1",
    motivo: "Información sensible",
    estado_solicitud: "pendiente",
    fecha_solicitud: "2026-05-18T10:00:00.000Z",
    usuarios: { username: "luna", correo: "luna@test.com" },
  },
  {
    id: "sol-2",
    reporte_id: "rep-22222222",
    usuario_id: "usr-2",
    motivo: "Duplicado",
    estado_solicitud: "pendiente",
    fecha_solicitud: "2026-05-17T10:00:00.000Z",
    usuarios: { username: "juan", correo: "juan@test.com" },
  },
];

const detalleMock = {
  id: "sol-1",
  estado_solicitud: "pendiente",
  fecha_solicitud: "2026-05-18T10:00:00.000Z",
  motivo: "Información sensible",
  reportes: {
    id: "rep-11111111",
    tipo_hurto: "atraco",
    fecha_incidente: "2026-05-10",
    barrio_ingresado: "Centro",
    estado: "oculto",
  },
  usuarios: {
    username: "luna",
    correo: "luna@test.com",
  },
};

describe("HU-20 TabSolicitudes unitario", () => {
  beforeEach(() => {
  vi.clearAllMocks();
});

  test("CP-HU20-F-01 carga listado inicial de solicitudes pendientes", async () => {
    const onCountChange = vi.fn();

    api.get.mockResolvedValueOnce({
      data: { data: solicitudesMock },
    });

    render(<TabSolicitudes onCountChange={onCountChange} />);

    expect(screen.getByText(/Cargando/i)).toBeInTheDocument();

    expect(await screen.findByText("luna")).toBeInTheDocument();
    expect(screen.getByText("juan")).toBeInTheDocument();
    expect(screen.getByText(/2 solicitudes/i)).toBeInTheDocument();

    expect(api.get).toHaveBeenCalledWith("/api/admin/solicitudes-eliminacion", {
      params: { estado: "pendiente" },
    });
    expect(onCountChange).toHaveBeenCalledWith(2);
  });

  test("CP-HU20-F-02 abre detalle de solicitud", async () => {
  api.get
    .mockResolvedValueOnce({ data: { data: solicitudesMock } })
    .mockResolvedValueOnce({ data: { data: detalleMock } });

  render(<TabSolicitudes />);

  await screen.findByText("luna");

  await userEvent.click(screen.getAllByTitle("Ver detalle")[0]);

  expect(await screen.findByText(/Detalle de solicitud/i)).toBeInTheDocument();

  const modalTitle = screen.getByText(/Detalle de solicitud/i);
  const modal = modalTitle.closest("div").parentElement;

  expect(within(modal).getByText(/ID Solicitud/i)).toBeInTheDocument();
  expect(within(modal).getByText(/Tipo hurto/i)).toBeInTheDocument();
  expect(within(modal).getByText(/^Solicitante$/i)).toBeInTheDocument();
});

  test("CP-HU20-F-03 aprueba solicitud desde detalle y recarga listado", async () => {
    api.get
      .mockResolvedValueOnce({ data: { data: solicitudesMock } })
      .mockResolvedValueOnce({ data: { data: detalleMock } })
      .mockResolvedValueOnce({ data: { data: [solicitudesMock[1]] } });

    api.post.mockResolvedValueOnce({ data: { success: true } });

    render(<TabSolicitudes />);

    await screen.findByText("luna");
    await userEvent.click(screen.getAllByTitle("Ver detalle")[0]);

    expect(await screen.findByText(/Detalle de solicitud/i)).toBeInTheDocument();

    await userEvent.click(screen.getByRole("button", { name: /Aprobar eliminación/i }));

    expect(screen.getByText(/Confirmar acción/i)).toBeInTheDocument();
    expect(
      screen.getByText((_, el) =>
        el?.tagName === "P" &&
        el.textContent?.includes("¿Estás seguro de aprobar esta solicitud?")
      )
    ).toBeInTheDocument();

    await userEvent.click(screen.getByRole("button", { name: /^Aprobar$/i }));

    await waitFor(() => {
      expect(api.post).toHaveBeenCalledWith("/api/admin/solicitudes-eliminacion/sol-1/aprobar");
    });

    expect(await screen.findByText(/Solicitud aprobada correctamente/i)).toBeInTheDocument();

    await waitFor(() => {
      expect(api.get).toHaveBeenLastCalledWith("/api/admin/solicitudes-eliminacion", {
        params: { estado: "pendiente" },
      });
    });
  });

  test("CP-HU20-F-04 rechaza solicitud desde detalle y recarga listado", async () => {
    api.get
      .mockResolvedValueOnce({ data: { data: solicitudesMock } })
      .mockResolvedValueOnce({ data: { data: detalleMock } })
      .mockResolvedValueOnce({ data: { data: [solicitudesMock[1]] } });

    api.post.mockResolvedValueOnce({ data: { success: true } });

    render(<TabSolicitudes />);

    await screen.findByText("luna");
    await userEvent.click(screen.getAllByTitle("Ver detalle")[0]);
    await screen.findByText(/Detalle de solicitud/i);

    await userEvent.click(screen.getByRole("button", { name: /Rechazar/i }));
    expect(screen.getByText(/Confirmar acción/i)).toBeInTheDocument();

    await userEvent.click(screen.getByRole("button", { name: /^Rechazar$/i }));

    await waitFor(() => {
      expect(api.post).toHaveBeenCalledWith("/api/admin/solicitudes-eliminacion/sol-1/rechazar");
    });

    expect(await screen.findByText(/Solicitud rechazada correctamente/i)).toBeInTheDocument();
  });

  test("CP-HU20-F-05 muestra error si falla cargar detalle", async () => {
    api.get
      .mockResolvedValueOnce({ data: { data: solicitudesMock } })
      .mockRejectedValueOnce(new Error("fail"));

    render(<TabSolicitudes />);

    await screen.findByText("luna");
    fireEvent.click(screen.getAllByTitle("Ver detalle")[0]);

    expect(await screen.findByText(/Error al cargar detalle/i)).toBeInTheDocument();
  });
});