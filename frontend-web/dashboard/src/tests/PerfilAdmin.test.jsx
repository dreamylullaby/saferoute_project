import React from "react";
import { render, screen, waitFor } from "@testing-library/react";
import userEvent from "@testing-library/user-event";
import { describe, test, expect, beforeEach, vi } from "vitest";
import TabPerfil from "../page/tabs/TabPerfil.jsx";
import api from "../services/api.js";

vi.mock("../services/api.js", () => ({
    default: {
        get: vi.fn(),
        patch: vi.fn(),
        put: vi.fn(),
        delete: vi.fn(),
    },
}));

const perfilLocalMock = {
    id: "admin-1",
    correo: "admin@saferoute.com",
    username: "Admin Luna",
    rol: "admin",
    auth_provider: "local",
    foto_url: null,
    fecha_creacion: "2026-05-01T10:00:00.000Z",
    notificaciones_activas: true,
};

const perfilGoogleMock = {
    ...perfilLocalMock,
    auth_provider: "google",
};

describe("HU-19 TabPerfil unitario Frontend React", () => {
    beforeEach(() => {
        vi.clearAllMocks();
        localStorage.clear();
        sessionStorage.clear();
        sessionStorage.setItem("admin", JSON.stringify({ id: "admin-1", username: "Admin Luna" }));

        Object.defineProperty(navigator, "clipboard", {
            value: { writeText: vi.fn() },
            configurable: true,
        });
    });

    test("CP-HU19-F-01 renderiza información principal del perfil", async () => {
        api.get.mockResolvedValueOnce({
            data: {
                data: {
                    username: "Admin Luna",
                    correo: "admin@saferoute.com",
                    rol: "Administrador",
                    auth_provider: "local",
                    fecha_creacion: "2026-05-01",
                    idioma: "es",
                    tema: "light",
                },
            },
        });

        render(<TabPerfil />);

        expect(await screen.findByText("Admin Luna")).toBeInTheDocument();
        expect(screen.getAllByText("admin@saferoute.com").length).toBeGreaterThan(0);
        expect(screen.getByText(/Miembro desde/i)).toBeInTheDocument();
        expect(screen.getByRole("button", { name: /Guardar/i })).toBeInTheDocument();
    });

    test("CP-HU19-F-02 muestra error si falla la carga del perfil", async () => {
        api.get.mockRejectedValueOnce(new Error("fallo"));

        render(<TabPerfil />);

        expect(await screen.findByText(/Error al cargar perfil/i)).toBeInTheDocument();
    });

    test("CP-HU19-F-03 guarda username válido", async () => {
        const user = userEvent.setup();
        api.get.mockResolvedValueOnce({ data: { data: perfilLocalMock } });
        api.patch.mockResolvedValueOnce({ data: { data: { username: "LunaAdmin" } } });

        render(<TabPerfil />);

        const input = await screen.findByDisplayValue("Admin Luna");
        await user.clear(input);
        await user.type(input, "LunaAdmin");
        await user.click(screen.getByRole("button", { name: /Guardar/i }));

        await waitFor(() => {
            expect(api.patch).toHaveBeenCalledWith("/api/perfil", { username: "LunaAdmin" });
        });

        expect(await screen.findByText(/Guardado correctamente/i)).toBeInTheDocument();
        expect(JSON.parse(sessionStorage.getItem("admin")).username).toBe("LunaAdmin");
    });

    test("CP-HU19-F-04 valida username inválido", async () => {
        const user = userEvent.setup();
        api.get.mockResolvedValueOnce({ data: { data: perfilLocalMock } });

        render(<TabPerfil />);

        const input = await screen.findByDisplayValue("Admin Luna");
        await user.clear(input);
        await user.type(input, "ab");
        await user.click(screen.getByRole("button", { name: /Guardar/i }));

        expect(screen.getByText(/Mínimo 3 caracteres/i)).toBeInTheDocument();
        expect(api.patch).not.toHaveBeenCalled();
    });

    test("CP-HU19-F-05 muestra error backend al guardar", async () => {
        const user = userEvent.setup();
        api.get.mockResolvedValueOnce({ data: { data: perfilLocalMock } });
        api.patch.mockRejectedValueOnce({
            response: { data: { message: "Ese apodo ya está en uso, elige otro" } },
        });

        render(<TabPerfil />);

        const input = await screen.findByDisplayValue("Admin Luna");
        await user.clear(input);
        await user.type(input, "admin2");
        await user.click(screen.getByRole("button", { name: /Guardar/i }));

        expect(await screen.findByText(/Ese apodo ya está en uso/i)).toBeInTheDocument();
    });

    test("CP-HU19-F-06 cambia idioma a inglés", async () => {
        const user = userEvent.setup();
        api.get.mockResolvedValueOnce({ data: { data: perfilLocalMock } });

        render(<TabPerfil />);

        await screen.findByText("Información de la cuenta");
        await user.click(screen.getByRole("button", { name: "EN" }));

        expect(await screen.findByText("Account Information")).toBeInTheDocument();
        expect(screen.getByText("Security")).toBeInTheDocument();
    });

    test("CP-HU19-F-07 activa dark mode", async () => {
        const user = userEvent.setup();
        api.get.mockResolvedValueOnce({ data: { data: perfilLocalMock } });

        render(<TabPerfil />);

        await screen.findByText("Modo oscuro");
        const darkButton = screen.getAllByRole("button").find((b) =>
            b.parentElement?.textContent?.includes("Modo oscuro")
        );

        await user.click(darkButton);

        expect(document.documentElement.getAttribute("data-theme")).toBe("dark");
        expect(localStorage.getItem("admin_dark")).toBe("true");
    });

    test("CP-HU19-F-08 bloquea cambio de contraseña para Google", async () => {
        api.get.mockResolvedValueOnce({ data: { data: perfilGoogleMock } });

        render(<TabPerfil />);

        expect(await screen.findByText(/No disponible para cuentas de Google/i)).toBeInTheDocument();
    });

    test("CP-HU19-F-09 valida campos vacíos en cambio de contraseña", async () => {
        const user = userEvent.setup();
        api.get.mockResolvedValueOnce({ data: { data: perfilLocalMock } });

        render(<TabPerfil />);

        await screen.findByRole("button", { name: /Cambiar contraseña/i });
        await user.click(screen.getByRole("button", { name: /Cambiar contraseña/i }));

        expect(screen.getByText(/Todos los campos son obligatorios/i)).toBeInTheDocument();
        expect(api.put).not.toHaveBeenCalled();
    });

    test("CP-HU19-F-10 cambia contraseña correctamente", async () => {
        const user = userEvent.setup();
        api.get.mockResolvedValueOnce({ data: { data: perfilLocalMock } });
        api.put.mockResolvedValueOnce({ data: { success: true } });

        render(<TabPerfil />);

        const passwordInputs = (await screen.findAllByDisplayValue("")).filter((i) => i.type === "password");

        await user.type(passwordInputs[0], "actual123");
        await user.type(passwordInputs[1], "nueva123");
        await user.type(passwordInputs[2], "nueva123");
        await user.click(screen.getByRole("button", { name: /Cambiar contraseña/i }));

        await waitFor(() => {
            expect(api.put).toHaveBeenCalledWith("/api/perfil/password", {
                passwordActual: "actual123",
                nuevaPassword: "nueva123",
            });
        });

        expect(await screen.findByText(/Contraseña actualizada/i)).toBeInTheDocument();
    });
});