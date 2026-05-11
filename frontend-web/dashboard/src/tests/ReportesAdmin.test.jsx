import { render, screen, waitFor, fireEvent } from "@testing-library/react";
import userEvent from "@testing-library/user-event";
import "@testing-library/jest-dom";
import { describe, test, expect, beforeEach, vi } from "vitest";
import ReportesAdmin from "../page/ReportesAdmin.jsx";
import { getReportesAdmin, getReporteById } from "../services/reportService.js";

vi.mock("../services/reportService.js", () => ({
  getReportesAdmin: vi.fn(),
  getReporteById: vi.fn(),
}));

const ok = (msg) => console.log(`✅ PASS: ${msg}`);

describe("HU-10 Frontend - ReportesAdmin", () => {
  const reportesMock = [
    {
      id: "rep-1",
      tipo_hurto: "atraco",
      barrio_ingresado: "Centro",
      comuna: 1,
      fecha_incidente: "2026-04-10",
      franja_horaria: "Mañana",
      estado: "activo",
    },
    {
      id: "rep-2",
      tipo_hurto: "raponazo",
      barrio_ingresado: "San Vicente",
      comuna: 2,
      fecha_incidente: "2026-04-12",
      franja_horaria: "Tarde",
      estado: "oculto",
    },
  ];

  const detalleMock = {
    id: "rep-1",
    estado: "activo",
    tipo_reportante: "anonimo",
    tipo_hurto: "atraco",
    fecha_incidente: "2026-04-10",
    franja_horaria: "Mañana",
    barrio_ingresado: "Centro",
    comuna: 1,
    latitud: 1.214,
    longitud: -77.278,
    objeto_hurtado: "Celular",
    numero_agresores: 2,
    descripcion: "Hurto cerca al parque",
    fecha_creacion: "2026-04-10T10:00:00.000Z",
  };

  beforeEach(() => {
    vi.clearAllMocks();
  });

  test("CP-HU10-FE-01 visualización inicial de tabla admin", async () => {
    getReportesAdmin.mockResolvedValue({
      data: reportesMock,
      total: 2,
      totalPages: 1,
    });

    render(<ReportesAdmin />);

    expect(screen.getByText("Cargando...")).toBeInTheDocument();

    await waitFor(() => {
      expect(screen.getByText("Tipo")).toBeInTheDocument();
      expect(screen.getByText("Barrio")).toBeInTheDocument();
      expect(screen.getByText("Comuna")).toBeInTheDocument();
      expect(screen.getByText("Fecha")).toBeInTheDocument();
      expect(screen.getByText("Franja")).toBeInTheDocument();
      expect(screen.getByText("Estado")).toBeInTheDocument();
    });

    ok("CP-HU10-FE-01 visualización inicial de tabla admin");
  });

  test("CP-HU10-FE-02 carga reportes desde servicio", async () => {
    getReportesAdmin.mockResolvedValue({
      data: reportesMock,
      total: 2,
      totalPages: 1,
    });

    render(<ReportesAdmin />);

    await waitFor(() => {
      expect(getReportesAdmin).toHaveBeenCalledWith({ page: 1, limit: 10 });
      expect(screen.getByText("Centro")).toBeInTheDocument();
      expect(screen.getByText("San Vicente")).toBeInTheDocument();
    });

    ok("CP-HU10-FE-02 carga reportes desde servicio");
  });

  test("CP-HU10-FE-03 filtra por rango de fechas", async () => {
    const user = userEvent.setup();

    getReportesAdmin.mockResolvedValue({
      data: [reportesMock[0]],
      total: 1,
      totalPages: 1,
    });

    const { container } = render(<ReportesAdmin />);

    await waitFor(() => expect(getReportesAdmin).toHaveBeenCalled());

    const dateInputs = container.querySelectorAll('input[type="date"]');
    await user.type(dateInputs[0], "2026-04-01");
    await user.type(dateInputs[1], "2026-04-11");

    await user.click(screen.getByRole("button", { name: "Filtrar" }));

    await waitFor(() => {
      expect(getReportesAdmin).toHaveBeenLastCalledWith({
        page: 1,
        limit: 10,
        fechaDesde: "2026-04-01",
        fechaHasta: "2026-04-11",
      });
    });

    ok("CP-HU10-FE-03 filtra por rango de fechas");
  });

  test("CP-HU10-FE-04 filtra por comuna", async () => {
    getReportesAdmin.mockResolvedValue({
      data: [reportesMock[0]],
      total: 1,
      totalPages: 1,
    });

    render(<ReportesAdmin />);

    await waitFor(() => expect(getReportesAdmin).toHaveBeenCalled());

    fireEvent.change(screen.getByPlaceholderText("Comuna (1-12)"), {
      target: { value: "1" },
    });

    fireEvent.click(screen.getByRole("button", { name: "Filtrar" }));

    await waitFor(() => {
      expect(getReportesAdmin).toHaveBeenLastCalledWith({
        page: 1,
        limit: 10,
        comuna: "1",
      });
    });

    ok("CP-HU10-FE-04 filtra por comuna");
  });

  test("CP-HU10-FE-05 filtra por fecha y comuna combinadas", async () => {
    const user = userEvent.setup();

    getReportesAdmin.mockResolvedValue({
      data: [reportesMock[0]],
      total: 1,
      totalPages: 1,
    });

    const { container } = render(<ReportesAdmin />);

    await waitFor(() => expect(getReportesAdmin).toHaveBeenCalled());

    await user.type(screen.getByPlaceholderText("Comuna (1-12)"), "1");

    const dateInputs = container.querySelectorAll('input[type="date"]');
    await user.type(dateInputs[0], "2026-04-01");
    await user.type(dateInputs[1], "2026-04-30");

    await user.click(screen.getByRole("button", { name: "Filtrar" }));

    await waitFor(() => {
      expect(getReportesAdmin).toHaveBeenLastCalledWith({
        page: 1,
        limit: 10,
        comuna: "1",
        fechaDesde: "2026-04-01",
        fechaHasta: "2026-04-30",
      });
    });

    ok("CP-HU10-FE-05 filtra por fecha y comuna combinadas");
  });

  test("CP-HU10-FE-06 filtros sin coincidencias", async () => {
    getReportesAdmin.mockResolvedValue({
      data: [],
      total: 0,
      totalPages: 1,
    });

    render(<ReportesAdmin />);

    await waitFor(() => {
      expect(screen.getByText("0 reporte(s) encontrado(s)")).toBeInTheDocument();
    });

    ok("CP-HU10-FE-06 filtros sin coincidencias");
  });

  test("CP-HU10-FE-07 selección de reporte abre modal", async () => {
    getReportesAdmin.mockResolvedValue({
      data: reportesMock,
      total: 2,
      totalPages: 1,
    });
    getReporteById.mockResolvedValue(detalleMock);

    render(<ReportesAdmin />);

    await waitFor(() => expect(screen.getByText("Centro")).toBeInTheDocument());

    fireEvent.click(screen.getAllByText("Centro")[0]);

    await waitFor(() => {
      expect(getReporteById).toHaveBeenCalledWith("rep-1");
      expect(screen.getByText("Detalle del reporte")).toBeInTheDocument();
    });

    ok("CP-HU10-FE-07 selección de reporte abre modal");
  });

  test("CP-HU10-FE-08 visualización del detalle completo", async () => {
    getReportesAdmin.mockResolvedValue({
      data: reportesMock,
      total: 2,
      totalPages: 1,
    });
    getReporteById.mockResolvedValue(detalleMock);

    render(<ReportesAdmin />);

    await waitFor(() => screen.getByText("Centro"));
    fireEvent.click(screen.getAllByText("Centro")[0]);

    await waitFor(() => {
      expect(screen.getByText("ID")).toBeInTheDocument();
      expect(screen.getByText("Tipo reportante")).toBeInTheDocument();
      expect(screen.getByText("Coordenadas")).toBeInTheDocument();
      expect(screen.getByText("Descripción")).toBeInTheDocument();
    });

    ok("CP-HU10-FE-08 visualización del detalle completo");
  });

  test("CP-HU10-FE-09 consistencia entre fila y detalle", async () => {
    const user = userEvent.setup();

    getReportesAdmin.mockResolvedValue({
      data: reportesMock,
      total: 2,
      totalPages: 1,
    });
    getReporteById.mockResolvedValue(detalleMock);

    render(<ReportesAdmin />);

    await waitFor(() => expect(screen.getByText("Centro")).toBeInTheDocument());

    const row = screen.getAllByText("Centro")[0].closest("tr");
    await user.click(row);

    await waitFor(() => {
      expect(screen.getByText("Detalle del reporte")).toBeInTheDocument();
      expect(screen.getByText("Comuna 1")).toBeInTheDocument();
    });

    ok("CP-HU10-FE-09 consistencia entre fila y detalle");
  });

  test("CP-HU10-FE-10 manejo de error al cargar reportes", async () => {
    const spy = vi.spyOn(console, "error").mockImplementation(() => {});
    getReportesAdmin.mockRejectedValue(new Error("falló api"));

    render(<ReportesAdmin />);

    await waitFor(() => {
      expect(spy).toHaveBeenCalled();
    });

    spy.mockRestore();

    ok("CP-HU10-FE-10 manejo de error al cargar reportes");
  });
});