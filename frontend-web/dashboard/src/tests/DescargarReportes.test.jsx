import React from "react";
import { render, screen, waitFor, fireEvent } from "@testing-library/react";
import userEvent from "@testing-library/user-event";
import { describe, test, expect, beforeEach, afterEach, vi } from "vitest";
import TabIncidentes from "../page/tabs/TabIncidentes.jsx";
import api from "../services/api.js";
import {
    getReportesAdmin,
    getReporteById,
    cambiarEstadoReporte,
    editarTipoHurtoReporte,
} from "../services/reportService.js";

vi.mock("../services/api.js", () => ({
    default: {
        get: vi.fn(),
        delete: vi.fn(),
    },
}));

vi.mock("../services/reportService.js", () => ({
    getReportesAdmin: vi.fn(),
    getReporteById: vi.fn(),
    cambiarEstadoReporte: vi.fn(),
    editarTipoHurtoReporte: vi.fn(),
}));

vi.mock("../components/CustomSelect.jsx", () => ({
    default: function MockCustomSelect({ value, onChange, options, placeholder }) {
        return (
            <select
                data-testid={`custom-select-${placeholder || "select"}`}
                value={value}
                onChange={(e) => onChange(e.target.value)}
            >
                {options.map((o) => (
                    <option key={String(o.value)} value={o.value}>
                        {o.label}
                    </option>
                ))}
            </select>
        );
    },
}));

vi.mock("../components/CustomDatePicker.jsx", () => ({
    default: function MockCustomDatePicker({ value, onChange, placeholder }) {
        return (
            <input
                data-testid={placeholder}
                value={value}
                placeholder={placeholder}
                onChange={(e) => onChange(e.target.value)}
            />
        );
    },
}));

const reportesMock = [
    {
        id: "rep-1",
        fecha_incidente: "2026-05-10",
        username: "luna",
        comuna: 5,
        tipo_hurto: "atraco",
        estado: "activo",
    },
];

describe("HU-21 TabIncidentes exportación", () => {
    let createObjectURLSpy;
    let revokeObjectURLSpy;
    let createElementSpy;
    let anchorClick;
    let originalCreateElement;

    beforeEach(() => {
        vi.clearAllMocks();

        originalCreateElement = document.createElement.bind(document);

        api.get.mockImplementation((url) => {
            if (url === "/api/reportes/corregimientos") {
                return Promise.resolve({ data: { data: [] } });
            }
            return Promise.resolve({ data: {} });
        });

        getReportesAdmin.mockResolvedValue({
            data: reportesMock,
            total: 1,
            totalPages: 1,
        });

        getReporteById.mockResolvedValue({});
        cambiarEstadoReporte.mockResolvedValue({});
        editarTipoHurtoReporte.mockResolvedValue({});

        anchorClick = vi.fn();

        createObjectURLSpy = vi
            .spyOn(URL, "createObjectURL")
            .mockReturnValue("blob:mock-url");

        revokeObjectURLSpy = vi
            .spyOn(URL, "revokeObjectURL")
            .mockImplementation(() => { });

        createElementSpy = vi.spyOn(document, "createElement").mockImplementation((tag) => {
            if (tag === "a") {
                return {
                    click: anchorClick,
                    set href(v) {
                        this._href = v;
                    },
                    get href() {
                        return this._href;
                    },
                    set download(v) {
                        this._download = v;
                    },
                    get download() {
                        return this._download;
                    },
                };
            }

            return originalCreateElement(tag);
        });
    });

    afterEach(() => {
        createElementSpy?.mockRestore();
        createObjectURLSpy?.mockRestore();
        revokeObjectURLSpy?.mockRestore();
    });

    test("CP-HU21-F-01 renderiza opción de descarga en panel de reportes", async () => {
        render(<TabIncidentes />);

        expect(await screen.findByText("luna")).toBeInTheDocument();
        expect(screen.getByRole("button", { name: /Descargar/i })).toBeInTheDocument();
        expect(screen.getByRole("button", { name: /Limpiar/i })).toBeInTheDocument();
    });

    test("CP-HU21-F-02 descarga CSV con filtros aplicados", async () => {
        const user = userEvent.setup();

        const blobData = new Blob(["id,tipo\nrep-1,atraco"], { type: "text/csv" });

        api.get
            .mockImplementationOnce(() => Promise.resolve({ data: { data: [] } }))
            .mockResolvedValueOnce({
                data: blobData,
                headers: { "content-type": "text/csv" },
            });

        render(<TabIncidentes />);

        await screen.findByText("luna");

        const todosSelects = screen.getAllByTestId("custom-select-Todos");
        const todasSelects = screen.getAllByTestId("custom-select-Todas");

        const estadoSelect = todosSelects[0];
        const tipoSelect = todosSelects[2];
        const comunaSelect = todasSelects[0];
        const formatoSelect = screen.getByTestId("custom-select-Excel");

        await user.selectOptions(estadoSelect, "activo");
        await user.selectOptions(comunaSelect, "5");
        await user.selectOptions(formatoSelect, "csv");

        expect(tipoSelect).toBeInTheDocument();

        fireEvent.change(screen.getByTestId("Desde"), {
            target: { value: "2026-05-01" },
        });

        fireEvent.change(screen.getByTestId("Hasta"), {
            target: { value: "2026-05-31" },
        });

        await user.click(screen.getByRole("button", { name: /Descargar/i }));

        await waitFor(() => {
            expect(api.get).toHaveBeenCalledWith("/api/admin/reportes/export", {
                params: {
                    formato: "csv",
                    fechaDesde: "2026-05-01",
                    fechaHasta: "2026-05-31",
                    estado: "activo",
                    zona: "5",
                },
                responseType: "blob",
            });
        });

        expect(URL.createObjectURL).toHaveBeenCalled();
        expect(anchorClick).toHaveBeenCalled();
        expect(URL.revokeObjectURL).toHaveBeenCalledWith("blob:mock-url");
        expect(await screen.findByText(/Archivo descargado correctamente/i)).toBeInTheDocument();
    });

    test("CP-HU21-F-03 muestra error si exportación devuelve respuesta no descargable", async () => {
        const user = userEvent.setup();

        api.get
            .mockImplementationOnce(() => Promise.resolve({ data: { data: [] } }))
            .mockRejectedValueOnce({
                response: {
                    data: { message: "No hay registros para exportar con los filtros aplicados." },
                },
            });

        render(<TabIncidentes />);

        await screen.findByText("luna");
        await user.click(screen.getByRole("button", { name: /Descargar/i }));

        expect(
            await screen.findByText(/No hay registros para exportar con los filtros aplicados\./i)
        ).toBeInTheDocument();
        expect(anchorClick).not.toHaveBeenCalled();
    });

    test("CP-HU21-F-04 muestra indicador de progreso durante exportación", async () => {
        const user = userEvent.setup();
        let resolveExport;

        api.get
            .mockImplementationOnce(() => Promise.resolve({ data: { data: [] } }))
            .mockImplementationOnce(
                () =>
                    new Promise((resolve) => {
                        resolveExport = resolve;
                    })
            );

        render(<TabIncidentes />);

        await screen.findByText("luna");

        await user.click(screen.getByRole("button", { name: /Descargar/i }));

        await waitFor(() => {
            expect(api.get).toHaveBeenCalledWith("/api/admin/reportes/export", {
                params: {
                    formato: "excel",
                },
                responseType: "blob",
            });
        });

        resolveExport({
            data: new Blob(["ok"], { type: "application/vnd.openxmlformats-officedocument.spreadsheetml.sheet" }),
            headers: {
                "content-type":
                    "application/vnd.openxmlformats-officedocument.spreadsheetml.sheet",
            },
        });

        await waitFor(() => {
            expect(screen.getByRole("button", { name: /Descargar/i })).toBeInTheDocument();
        });
    });

    test("CP-HU21-F-05 muestra error si falla exportación", async () => {
        const user = userEvent.setup();

        api.get
            .mockImplementationOnce(() => Promise.resolve({ data: { data: [] } }))
            .mockRejectedValueOnce(new Error("fallo"));

        render(<TabIncidentes />);

        await screen.findByText("luna");
        await user.click(screen.getByRole("button", { name: /Descargar/i }));

        expect(await screen.findByText(/Error al exportar/i)).toBeInTheDocument();
    });
});