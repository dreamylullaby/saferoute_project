import React from "react";
import { describe, test, expect, vi, beforeEach, afterEach } from "vitest";
import "@testing-library/jest-dom/vitest";
import { render, screen, waitFor, within } from "@testing-library/react";
import userEvent from "@testing-library/user-event";

const apiMock = vi.hoisted(() => ({
    get: vi.fn(),
    patch: vi.fn(),
    delete: vi.fn(),
}));

vi.mock("../../services/api.js", () => ({
    default: apiMock,
}));

import TabUsuarios from "../../page/tabs/TabUsuarios.jsx";

describe("HU-14 TabUsuarios frontend integral", () => {
    beforeEach(() => {
        vi.clearAllMocks();
        sessionStorage.clear();
        sessionStorage.setItem("token", "token-fake");
    });

    afterEach(() => {
        vi.restoreAllMocks();
    });

    test("CP-HU14-I-01 flujo completo de bloqueo", async () => {
        apiMock.get
            .mockResolvedValueOnce({
                data: {
                    data: [
                        {
                            id: "u1",
                            username: "ana",
                            correo: "ana@test.com",
                            rol: "usuario",
                            estado: "activo",
                            fecha_creacion: "2026-05-01T10:00:00.000Z",
                        },
                    ],
                    total: 1,
                    totalPages: 1,
                },
            })
            .mockResolvedValueOnce({
                data: {
                    data: [
                        {
                            id: "u1",
                            username: "ana",
                            correo: "ana@test.com",
                            rol: "usuario",
                            estado: "bloqueado",
                            fecha_creacion: "2026-05-01T10:00:00.000Z",
                        },
                    ],
                    total: 1,
                    totalPages: 1,
                },
            });

        apiMock.patch.mockResolvedValueOnce({
            data: { success: true, message: "Usuario bloqueado correctamente" },
        });

        const user = userEvent.setup();
        render(<TabUsuarios />);

        expect(await screen.findByText("ana")).toBeInTheDocument();

        await user.click(screen.getByRole("button", { name: /bloquear/i }));

        const modal = await screen.findByText(/confirmar acción/i);
        const dialog = modal.closest("div[style]");
        const scope = dialog ? within(dialog) : within(modal.parentElement);

        await user.click(scope.getByRole("button", { name: /^Bloquear$/i }));

        await waitFor(() => {
            expect(apiMock.patch).toHaveBeenCalledTimes(1);
        });

        expect(await screen.findByText(/Usuario bloquear correctamente/i)).toBeInTheDocument();

        await waitFor(() => {
            expect(apiMock.get).toHaveBeenCalledTimes(2);
        });
    });

    test("CP-HU14-I-02 flujo completo de reactivación", async () => {
        apiMock.get
            .mockResolvedValueOnce({
                data: {
                    data: [
                        {
                            id: "u2",
                            username: "carlos",
                            correo: "carlos@test.com",
                            rol: "usuario",
                            estado: "bloqueado",
                            fecha_creacion: "2026-05-02T10:00:00.000Z",
                        },
                    ],
                    total: 1,
                    totalPages: 1,
                },
            })
            .mockResolvedValueOnce({
                data: {
                    data: [
                        {
                            id: "u2",
                            username: "carlos",
                            correo: "carlos@test.com",
                            rol: "usuario",
                            estado: "activo",
                            fecha_creacion: "2026-05-02T10:00:00.000Z",
                        },
                    ],
                    total: 1,
                    totalPages: 1,
                },
            });

        apiMock.patch.mockResolvedValueOnce({
            data: { success: true, message: "Usuario reactivado correctamente" },
        });

        const user = userEvent.setup();
        render(<TabUsuarios />);

        expect(await screen.findByRole("button", { name: /reactivar/i })).toBeInTheDocument();

        await user.click(screen.getByRole("button", { name: /reactivar/i }));

        const modal = await screen.findByText(/confirmar acción/i);
        const dialog = modal.closest("div[style]");
        const scope = dialog ? within(dialog) : within(modal.parentElement);

        await user.click(scope.getByRole("button", { name: /^Reactivar$/i }));

        await waitFor(() => {
            expect(apiMock.patch).toHaveBeenCalledTimes(1);
        });

        expect(await screen.findByText(/Usuario reactivar correctamente/i)).toBeInTheDocument();

        await waitFor(() => {
            expect(apiMock.get).toHaveBeenCalledTimes(2);
        });
    });

    test("CP-HU14-I-03 búsqueda y filtro integrados", async () => {
        apiMock.get.mockResolvedValue({
            data: {
                data: [
                    {
                        id: "u1",
                        username: "ana",
                        correo: "ana@test.com",
                        rol: "usuario",
                        estado: "activo",
                        fecha_creacion: "2026-05-01T10:00:00.000Z",
                    },
                ],
                total: 1,
                totalPages: 1,
            },
        });

        const user = userEvent.setup();
        render(<TabUsuarios />);

        const input = await screen.findByPlaceholderText(/buscar por nombre o correo/i);
        await user.type(input, "ana");

        await waitFor(() => {
            expect(apiMock.get).toHaveBeenLastCalledWith("/api/admin/usuarios", {
                params: { page: 1, limit: 10, q: "ana" },
            });
        });

        await user.click(screen.getByRole("button", { name: /^Todos$/i }));

        const activos = await screen.findAllByText(/^Activo$/i);
        await user.click(activos[0]);

        await waitFor(() => {
            expect(apiMock.get).toHaveBeenLastCalledWith("/api/admin/usuarios", {
                params: { page: 1, limit: 10, q: "ana", estado: "activo" },
            });
        });
    });

    test("CP-HU14-I-04 paginación integral", async () => {
        apiMock.get
            .mockResolvedValueOnce({
                data: {
                    data: [
                        {
                            id: "u1",
                            username: "ana",
                            correo: "ana@test.com",
                            rol: "usuario",
                            estado: "activo",
                            fecha_creacion: "2026-05-01T10:00:00.000Z",
                        },
                    ],
                    total: 25,
                    totalPages: 3,
                },
            })
            .mockResolvedValueOnce({
                data: {
                    data: [
                        {
                            id: "u11",
                            username: "maria",
                            correo: "maria@test.com",
                            rol: "usuario",
                            estado: "activo",
                            fecha_creacion: "2026-05-11T10:00:00.000Z",
                        },
                    ],
                    total: 25,
                    totalPages: 3,
                },
            });

        const user = userEvent.setup();
        render(<TabUsuarios />);

        expect(await screen.findByText("ana")).toBeInTheDocument();

        await user.click(screen.getByRole("button", { name: /siguiente/i }));

        await waitFor(() => {
            expect(apiMock.get).toHaveBeenLastCalledWith("/api/admin/usuarios", {
                params: { page: 2, limit: 10 },
            });
        });

        expect(await screen.findByText("maria")).toBeInTheDocument();
    });
});