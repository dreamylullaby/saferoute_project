import React from "react";
import { describe, test, expect, vi, beforeEach } from "vitest";
import "@testing-library/jest-dom/vitest";
import { render, screen, waitFor } from "@testing-library/react";
import userEvent from "@testing-library/user-event";

const reportServiceMock = vi.hoisted(() => ({
    getReportesAdmin: vi.fn(),
    getReporteById: vi.fn(),
    cambiarEstadoReporte: vi.fn(),
    editarTipoHurtoReporte: vi.fn(),
}));

const apiMock = vi.hoisted(() => ({
    get: vi.fn(),
    delete: vi.fn(),
}));

vi.mock("../services/reportService.js", () => reportServiceMock);
vi.mock("../services/api.js", () => ({ default: apiMock }));

vi.mock("../components/CustomSelect.jsx", () => ({
    default: ({ value, onChange, options, placeholder }) => (
        <select
            aria-label={placeholder || "select"}
            value={value}
            onChange={(e) => onChange(e.target.value)}
        >
            {options.map((o) => (
                <option key={o.value} value={o.value}>
                    {o.label}
                </option>
            ))}
        </select>
    ),
}));

vi.mock("../components/CustomDatePicker.jsx", () => ({
    default: ({ value, onChange, placeholder }) => (
        <input
            aria-label={placeholder}
            placeholder={placeholder}
            value={value}
            onChange={(e) => onChange(e.target.value)}
        />
    ),
}));

import TabIncidentes from "../page/tabs/TabIncidentes.jsx";

describe("HU-16 TabIncidentes unitario", () => {
    beforeEach(() => {
        vi.clearAllMocks();

        apiMock.get.mockResolvedValue({
            data: { data: [{ id: 1, nombre: "Catambuco" }] },
        });

        reportServiceMock.getReporteById.mockResolvedValue({
            id: "rep-1",
            tipo_hurto: "atraco",
            fecha_incidente: "2026-05-10",
            estado: "activo",
            descripcion: "Descripción de prueba",
        });
    });

    test("CP-HU16-F-01 renderiza listado inicial de reportes", async () => {
        reportServiceMock.getReportesAdmin.mockResolvedValue({
            data: [
                {
                    id: "rep-1",
                    fecha_incidente: "2026-05-10",
                    username: "luna",
                    comuna: 5,
                    tipo_hurto: "atraco",
                    estado: "activo",
                },
            ],
            total: 1,
            totalPages: 1,
        });

        render(<TabIncidentes />);

        expect(await screen.findByText("luna")).toBeInTheDocument();
        expect(screen.getByText("Comuna 5")).toBeInTheDocument();
        expect(screen.getAllByText("Activo")[0]).toBeInTheDocument();
    });

    test("CP-HU16-F-02 muestra acciones ocultar y eliminar para reporte activo", async () => {
        reportServiceMock.getReportesAdmin.mockResolvedValue({
            data: [
                {
                    id: "rep-1",
                    fecha_incidente: "2026-05-10",
                    username: "luna",
                    comuna: 5,
                    tipo_hurto: "atraco",
                    estado: "activo",
                },
            ],
            total: 1,
            totalPages: 1,
        });

        render(<TabIncidentes />);

        await screen.findByText("luna");
        expect(screen.getByTitle("Ocultar")).toBeInTheDocument();
        expect(screen.getByTitle("Eliminar")).toBeInTheDocument();
    });

    test("CP-HU16-F-03 muestra acción mostrar para reporte oculto", async () => {
        reportServiceMock.getReportesAdmin.mockResolvedValue({
            data: [
                {
                    id: "rep-2",
                    fecha_incidente: "2026-05-10",
                    username: "luna",
                    comuna: 5,
                    tipo_hurto: "raponazo",
                    estado: "oculto",
                },
            ],
            total: 1,
            totalPages: 1,
        });

        render(<TabIncidentes />);

        await screen.findByText("luna");
        expect(screen.getByTitle("Mostrar")).toBeInTheDocument();
        expect(screen.getByTitle("Eliminar")).toBeInTheDocument();
    });

    test("CP-HU16-F-04 muestra restaurar y borrar para reporte eliminado", async () => {
        reportServiceMock.getReportesAdmin.mockResolvedValue({
            data: [
                {
                    id: "rep-3",
                    fecha_incidente: "2026-05-10",
                    username: "luna",
                    comuna: 5,
                    tipo_hurto: "fleteo",
                    estado: "eliminado",
                },
            ],
            total: 1,
            totalPages: 1,
        });

        render(<TabIncidentes />);

        await screen.findByText("luna");
        expect(screen.getByTitle("Restaurar")).toBeInTheDocument();
        expect(screen.getByTitle("Borrar")).toBeInTheDocument();
    });

    test("CP-HU16-F-05 abre modal de confirmación al ocultar", async () => {
        const user = userEvent.setup();

        reportServiceMock.getReportesAdmin.mockResolvedValue({
            data: [
                {
                    id: "rep-1",
                    fecha_incidente: "2026-05-10",
                    username: "luna",
                    comuna: 5,
                    tipo_hurto: "atraco",
                    estado: "activo",
                },
            ],
            total: 1,
            totalPages: 1,
        });

        render(<TabIncidentes />);

        await screen.findByText("luna");
        await user.click(screen.getByTitle("Ocultar"));

        expect(screen.getByText(/Confirmar acción/i)).toBeInTheDocument();
        expect(
            screen.getByText((_, element) =>
                element?.tagName === "P" &&
                element.textContent?.includes("¿Estás seguro de ocultar este reporte?")
            )
        ).toBeInTheDocument();
    });

    test("CP-HU16-F-06 confirma cambio de estado y refresca tabla", async () => {
        const user = userEvent.setup();

        reportServiceMock.getReportesAdmin
            .mockResolvedValueOnce({
                data: [
                    {
                        id: "rep-1",
                        fecha_incidente: "2026-05-10",
                        username: "luna",
                        comuna: 5,
                        tipo_hurto: "atraco",
                        estado: "activo",
                    },
                ],
                total: 1,
                totalPages: 1,
            })
            .mockResolvedValueOnce({
                data: [
                    {
                        id: "rep-1",
                        fecha_incidente: "2026-05-10",
                        username: "luna",
                        comuna: 5,
                        tipo_hurto: "atraco",
                        estado: "oculto",
                    },
                ],
                total: 1,
                totalPages: 1,
            });

        reportServiceMock.cambiarEstadoReporte.mockResolvedValue({ success: true });

        render(<TabIncidentes />);

        await screen.findByText("luna");
        await user.click(screen.getByTitle("Ocultar"));
        await user.click(screen.getByRole("button", { name: /Confirmar/i }));

        await waitFor(() => {
            expect(reportServiceMock.cambiarEstadoReporte).toHaveBeenCalledWith("rep-1", "oculto");
        });

        expect(await screen.findByText(/Reporte cambiado a "oculto" correctamente/i)).toBeInTheDocument();
    });

    test("CP-HU16-F-07 cancela cambio de estado", async () => {
        const user = userEvent.setup();

        reportServiceMock.getReportesAdmin.mockResolvedValue({
            data: [
                {
                    id: "rep-1",
                    fecha_incidente: "2026-05-10",
                    username: "luna",
                    comuna: 5,
                    tipo_hurto: "atraco",
                    estado: "activo",
                },
            ],
            total: 1,
            totalPages: 1,
        });

        render(<TabIncidentes />);

        await screen.findByText("luna");
        await user.click(screen.getByTitle("Ocultar"));
        await user.click(screen.getByRole("button", { name: /Cancelar/i }));

        expect(reportServiceMock.cambiarEstadoReporte).not.toHaveBeenCalled();
    });

    test("CP-HU16-F-08 muestra error si falla cambio de estado", async () => {
        const user = userEvent.setup();

        reportServiceMock.getReportesAdmin.mockResolvedValue({
            data: [
                {
                    id: "rep-1",
                    fecha_incidente: "2026-05-10",
                    username: "luna",
                    comuna: 5,
                    tipo_hurto: "atraco",
                    estado: "activo",
                },
            ],
            total: 1,
            totalPages: 1,
        });

        reportServiceMock.cambiarEstadoReporte.mockRejectedValue({
            response: { data: { message: "No autorizado" } },
        });

        render(<TabIncidentes />);

        await screen.findByText("luna");
        await user.click(screen.getByTitle("Ocultar"));
        await user.click(screen.getByRole("button", { name: /Confirmar/i }));

        expect(await screen.findByText(/No autorizado/i)).toBeInTheDocument();
    });
});