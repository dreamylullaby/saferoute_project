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

vi.mock("../../services/reportService.js", () => reportServiceMock);
vi.mock("../../services/api.js", () => ({ default: apiMock }));

vi.mock("../../components/CustomSelect.jsx", () => ({
    default: ({ value, onChange, options, placeholder }) => (
        <select aria-label={placeholder || "select"} value={value} onChange={(e) => onChange(e.target.value)}>
            {options.map((o) => <option key={o.value} value={o.value}>{o.label}</option>)}
        </select>
    ),
}));

vi.mock("../../components/CustomDatePicker.jsx", () => ({
    default: ({ value, onChange, placeholder }) => (
        <input aria-label={placeholder} placeholder={placeholder} value={value} onChange={(e) => onChange(e.target.value)} />
    ),
}));

import TabIncidentes from "../../page/tabs/TabIncidentes.jsx";

describe("HU-16 TabIncidentes integral frontend", () => {
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
            descripcion: "Descripción válida",
        });
    });

    test("CP-HU16-I-01 flujo ocultar reporte", async () => {
        const user = userEvent.setup();

        reportServiceMock.getReportesAdmin
            .mockResolvedValueOnce({
                data: [
                    {
                        id: "rep-1",
                        fecha_incidente: "2026-05-10",
                        username: "luna",
                        comuna: 1,
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
                        comuna: 1,
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

        expect(
            await screen.findByText(/Reporte cambiado a "oculto" correctamente/i)
        ).toBeInTheDocument();
    });

    test("CP-HU16-I-02 flujo eliminar reporte", async () => {
        const user = userEvent.setup();

        reportServiceMock.getReportesAdmin
            .mockResolvedValueOnce({
                data: [{ id: "rep-2", fecha_incidente: "2026-05-10", username: "ana", comuna: 2, tipo_hurto: "raponazo", estado: "activo" }],
                total: 1,
                totalPages: 1,
            })
            .mockResolvedValueOnce({
                data: [{ id: "rep-2", fecha_incidente: "2026-05-10", username: "ana", comuna: 2, tipo_hurto: "raponazo", estado: "eliminado" }],
                total: 1,
                totalPages: 1,
            });

        reportServiceMock.cambiarEstadoReporte.mockResolvedValue({ success: true });

        render(<TabIncidentes />);

        await screen.findByText("ana");
        await user.click(screen.getByTitle("Eliminar"));
        await user.click(screen.getByRole("button", { name: /Confirmar/i }));

        await waitFor(() => {
            expect(reportServiceMock.cambiarEstadoReporte).toHaveBeenCalledWith("rep-2", "eliminado");
        });
    });

    test("CP-HU16-I-03 flujo mostrar reporte oculto", async () => {
        const user = userEvent.setup();

        reportServiceMock.getReportesAdmin
            .mockResolvedValueOnce({
                data: [{ id: "rep-3", fecha_incidente: "2026-05-10", username: "mario", comuna: 3, tipo_hurto: "fleteo", estado: "oculto" }],
                total: 1,
                totalPages: 1,
            })
            .mockResolvedValueOnce({
                data: [{ id: "rep-3", fecha_incidente: "2026-05-10", username: "mario", comuna: 3, tipo_hurto: "fleteo", estado: "activo" }],
                total: 1,
                totalPages: 1,
            });

        reportServiceMock.cambiarEstadoReporte.mockResolvedValue({ success: true });

        render(<TabIncidentes />);

        await screen.findByText("mario");
        await user.click(screen.getByTitle("Mostrar"));
        await user.click(screen.getByRole("button", { name: /Confirmar/i }));

        await waitFor(() => {
            expect(reportServiceMock.cambiarEstadoReporte).toHaveBeenCalledWith("rep-3", "activo");
        });
    });

    test("CP-HU16-I-04 flujo borrar permanentemente un reporte eliminado", async () => {
        const user = userEvent.setup();

        reportServiceMock.getReportesAdmin
            .mockResolvedValueOnce({
                data: [{ id: "rep-4", fecha_incidente: "2026-05-10", username: "sofia", comuna: 4, tipo_hurto: "cosquilleo", estado: "eliminado" }],
                total: 1,
                totalPages: 1,
            })
            .mockResolvedValueOnce({
                data: [],
                total: 0,
                totalPages: 1,
            });

        apiMock.delete.mockResolvedValue({ data: { success: true } });

        render(<TabIncidentes />);

        await screen.findByText("sofia");
        await user.click(screen.getByTitle("Borrar"));
        await user.click(screen.getByRole("button", { name: /Eliminar permanentemente/i }));

        await waitFor(() => {
            expect(apiMock.delete).toHaveBeenCalledWith("/api/admin/reportes/rep-4/permanente");
        });

        expect(await screen.findByText(/Reporte eliminado permanentemente/i)).toBeInTheDocument();
    });
});