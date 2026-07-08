import { render, screen, waitFor } from "@testing-library/react";
import userEvent from "@testing-library/user-event";
import "@testing-library/jest-dom";
import { describe, test, expect, beforeEach, vi } from "vitest";
import ReportesAdmin from "../../page/ReportesAdmin.jsx";

const mocks = vi.hoisted(() => ({
    getReportesAdmin: vi.fn(),
    getReporteById: vi.fn(),
}));

vi.mock("../../services/reportService.js", () => ({
    getReportesAdmin: mocks.getReportesAdmin,
    getReporteById: mocks.getReporteById,
}));

const ok = (msg) => console.log(`✅ PASS: ${msg}`);

describe("HU-10 Integral Frontend - ReportesAdmin", () => {
    const listaInicial = [
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

    const listaFiltrada = [
        {
            id: "rep-1",
            tipo_hurto: "atraco",
            barrio_ingresado: "Centro",
            comuna: 1,
            fecha_incidente: "2026-04-10",
            franja_horaria: "Mañana",
            estado: "activo",
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

    test("PI-HU10-FE-01 flujo integral: carga, filtra y abre detalle", async () => {
        const user = userEvent.setup();

        mocks.getReportesAdmin
            .mockResolvedValueOnce({
                data: listaInicial,
                total: 2,
                totalPages: 1,
            })
            .mockResolvedValueOnce({
                data: listaFiltrada,
                total: 1,
                totalPages: 1,
            })
            .mockResolvedValue({
                data: listaFiltrada,
                total: 1,
                totalPages: 1,
            });

        mocks.getReporteById.mockResolvedValue(detalleMock);

        const { container } = render(<ReportesAdmin />);

        await waitFor(() => {
            expect(mocks.getReportesAdmin).toHaveBeenCalledWith({ page: 1, limit: 10 });
            expect(screen.getByText("Centro")).toBeInTheDocument();
            expect(screen.getByText("San Vicente")).toBeInTheDocument();
        });

        await user.type(screen.getByPlaceholderText("Comuna (1-12)"), "1");

        const dateInputs = container.querySelectorAll('input[type="date"]');
        await user.type(dateInputs[0], "2026-04-01");
        await user.type(dateInputs[1], "2026-04-11");

        await user.click(screen.getByRole("button", { name: "Filtrar" }));

        await waitFor(() => {
            expect(mocks.getReportesAdmin).toHaveBeenLastCalledWith({
                page: 1,
                limit: 10,
                comuna: "1",
                fechaDesde: "2026-04-01",
                fechaHasta: "2026-04-11",
            });
            expect(screen.getByText("Centro")).toBeInTheDocument();
        });

        await user.click(screen.getAllByText("Centro")[0]);

        await waitFor(() => {
            expect(mocks.getReporteById).toHaveBeenCalledWith("rep-1");
            expect(screen.getByText("Detalle del reporte")).toBeInTheDocument();
            expect(screen.getByText("Descripción")).toBeInTheDocument();
            expect(screen.getByText("Coordenadas")).toBeInTheDocument();
        });

        ok("PI-HU10-FE-01 flujo integral: carga, filtra y abre detalle");
    });

    test("PI-HU10-FE-02 flujo integral sin coincidencias", async () => {
        const user = userEvent.setup();

        mocks.getReportesAdmin
            .mockResolvedValueOnce({
                data: listaInicial,
                total: 2,
                totalPages: 1,
            })
            .mockResolvedValueOnce({
                data: [],
                total: 0,
                totalPages: 1,
            })
            .mockResolvedValue({
                data: [],
                total: 0,
                totalPages: 1,
            });

        const { container } = render(<ReportesAdmin />);

        await waitFor(() => {
            expect(screen.getByText("Centro")).toBeInTheDocument();
        });

        await user.type(screen.getByPlaceholderText("Comuna (1-12)"), "9");

        const dateInputs = container.querySelectorAll('input[type="date"]');
        await user.type(dateInputs[0], "2027-01-01");
        await user.type(dateInputs[1], "2027-01-31");

        await user.click(screen.getByRole("button", { name: "Filtrar" }));

        await waitFor(() => {
            expect(screen.getByText("0 reporte(s) encontrado(s)")).toBeInTheDocument();
        });

        ok("PI-HU10-FE-02 flujo integral sin coincidencias");
    });
});