import { describe, test, expect, beforeEach, jest } from "@jest/globals";

const mockFrom = jest.fn();

await jest.unstable_mockModule("../dbScript/db.js", () => ({
    default: {
        from: mockFrom,
    },
}));

const {
    listarUsuarios,
    bloquearUsuario,
    reactivarUsuario,
} = await import("../../../interfaces/controllers/adminController.js");

function mockRes() {
    return {
        status: jest.fn().mockReturnThis(),
        json: jest.fn().mockReturnThis(),
        setHeader: jest.fn(),
        send: jest.fn(),
        end: jest.fn(),
    };
}

function makeListQuery(result = { data: [], error: null, count: 0 }) {
    return {
        select: jest.fn().mockReturnThis(),
        order: jest.fn().mockReturnThis(),
        range: jest.fn().mockResolvedValue(result),
        eq: jest.fn().mockReturnThis(),
        or: jest.fn().mockReturnThis(),
        ilike: jest.fn().mockReturnThis(),
        filter: jest.fn().mockReturnThis(),
        match: jest.fn().mockReturnThis(),
        is: jest.fn().mockReturnThis(),
        neq: jest.fn().mockReturnThis(),
        not: jest.fn().mockReturnThis(),
        in: jest.fn().mockReturnThis(),
        limit: jest.fn().mockReturnThis(),
    };
}
describe("HU-14 adminController backend unitario", () => {
    beforeEach(() => {
        jest.clearAllMocks();
    });

    test("CP-HU14-B-01 listar usuarios con paginación", async () => {
        const query = makeListQuery({
            data: [{ id: "u1", username: "ana" }],
            error: null,
            count: 1,
        });
        mockFrom.mockReturnValue(query);

        const req = { query: { page: 2, limit: 10 } };
        const res = mockRes();

        await listarUsuarios(req, res);

        expect(mockFrom).toHaveBeenCalledWith("usuarios");
        expect(query.select).toHaveBeenCalled();
        expect(query.order).toHaveBeenCalledWith("fecha_creacion", { ascending: false });
        expect(query.range).toHaveBeenCalledWith(10, 19);
        expect(res.status).toHaveBeenCalledWith(200);
        expect(res.json).toHaveBeenCalledWith({
            success: true,
            data: [{ id: "u1", username: "ana" }],
            total: 1,
            page: 2,
            totalPages: 1,
        });
    });

    test("CP-HU14-B-02 listar usuarios con filtro por estado y búsqueda", async () => {
        const query = makeListQuery({
            data: [],
            error: null,
            count: 0,
        });
        mockFrom.mockReturnValue(query);

        const consoleSpy = jest.spyOn(console, "error").mockImplementation(() => { });

        const req = { query: { page: 1, limit: 10, estado: "activo", q: "ana" } };
        const res = mockRes();

        await listarUsuarios(req, res);

        console.log("status calls:", res.status.mock.calls);
        console.log("json calls:", res.json.mock.calls);
        console.log("from calls:", mockFrom.mock.calls);
        console.log("select calls:", query.select.mock.calls);
        console.log("order calls:", query.order.mock.calls);
        console.log("range calls:", query.range.mock.calls);
        console.log("eq calls:", query.eq.mock.calls);
        console.log("or calls:", query.or.mock.calls);
        console.log("ilike calls:", query.ilike?.mock.calls);
        console.log("filter calls:", query.filter?.mock.calls);
        console.log("console.error calls:", consoleSpy.mock.calls);

        consoleSpy.mockRestore();
    });

    test("CP-HU14-B-03 bloquear usuario válido", async () => {
        const selectQuery = {
            select: jest.fn().mockReturnThis(),
            eq: jest.fn().mockReturnThis(),
            single: jest.fn().mockResolvedValue({
                data: { id: "u1", rol: "usuario", estado: "activo", username: "ana" },
                error: null,
            }),
        };

        const updateQuery = {
            update: jest.fn().mockReturnThis(),
            eq: jest.fn().mockResolvedValue({ error: null }),
        };

        const auditQuery = {
            insert: jest.fn().mockResolvedValue({ error: null }),
        };

        mockFrom
            .mockReturnValueOnce(selectQuery)
            .mockReturnValueOnce(updateQuery)
            .mockReturnValueOnce(auditQuery);

        const req = { params: { id: "u1" }, user: { id: "admin-1" } };
        const res = mockRes();

        await bloquearUsuario(req, res);

        expect(updateQuery.update).toHaveBeenCalledWith({ estado: "bloqueado" });
        expect(auditQuery.insert).toHaveBeenCalledWith({
            admin_id: "admin-1",
            usuario_id: "u1",
            accion: "bloquear",
            detalle: "Usuario ana bloqueado",
        });
        expect(res.status).toHaveBeenCalledWith(200);
        expect(res.json).toHaveBeenCalledWith({
            success: true,
            message: "Usuario bloqueado correctamente",
        });
    });

    test("CP-HU14-B-04 no puede bloquearse a sí mismo", async () => {
        const req = { params: { id: "admin-1" }, user: { id: "admin-1" } };
        const res = mockRes();

        await bloquearUsuario(req, res);

        expect(res.status).toHaveBeenCalledWith(400);
        expect(res.json).toHaveBeenCalledWith({
            success: false,
            message: "No puedes bloquearte a ti mismo",
        });
    });

    test("CP-HU14-B-05 no bloquea a un administrador", async () => {
        const selectQuery = {
            select: jest.fn().mockReturnThis(),
            eq: jest.fn().mockReturnThis(),
            single: jest.fn().mockResolvedValue({
                data: { id: "u-admin", rol: "admin", estado: "activo", username: "root" },
                error: null,
            }),
        };

        mockFrom.mockReturnValueOnce(selectQuery);

        const req = { params: { id: "u-admin" }, user: { id: "admin-1" } };
        const res = mockRes();

        await bloquearUsuario(req, res);

        expect(res.status).toHaveBeenCalledWith(403);
        expect(res.json).toHaveBeenCalledWith({
            success: false,
            message: "No se puede bloquear a un administrador",
        });
    });

    test("CP-HU14-B-06 no bloquea usuario ya bloqueado", async () => {
        const selectQuery = {
            select: jest.fn().mockReturnThis(),
            eq: jest.fn().mockReturnThis(),
            single: jest.fn().mockResolvedValue({
                data: { id: "u1", rol: "usuario", estado: "bloqueado", username: "ana" },
                error: null,
            }),
        };

        mockFrom.mockReturnValueOnce(selectQuery);

        const req = { params: { id: "u1" }, user: { id: "admin-1" } };
        const res = mockRes();

        await bloquearUsuario(req, res);

        expect(res.status).toHaveBeenCalledWith(400);
        expect(res.json).toHaveBeenCalledWith({
            success: false,
            message: "El usuario ya está bloqueado",
        });
    });

    test("CP-HU14-B-07 reactivar usuario bloqueado", async () => {
        const selectQuery = {
            select: jest.fn().mockReturnThis(),
            eq: jest.fn().mockReturnThis(),
            single: jest.fn().mockResolvedValue({
                data: { id: "u2", rol: "usuario", estado: "bloqueado", username: "carlos" },
                error: null,
            }),
        };

        const updateQuery = {
            update: jest.fn().mockReturnThis(),
            eq: jest.fn().mockResolvedValue({ error: null }),
        };

        const auditQuery = {
            insert: jest.fn().mockResolvedValue({ error: null }),
        };

        mockFrom
            .mockReturnValueOnce(selectQuery)
            .mockReturnValueOnce(updateQuery)
            .mockReturnValueOnce(auditQuery);

        const req = { params: { id: "u2" }, user: { id: "admin-1" } };
        const res = mockRes();

        await reactivarUsuario(req, res);

        expect(updateQuery.update).toHaveBeenCalledWith({ estado: "activo" });
        expect(auditQuery.insert).toHaveBeenCalledWith({
            admin_id: "admin-1",
            usuario_id: "u2",
            accion: "reactivar",
            detalle: "Usuario carlos reactivado",
        });
        expect(res.status).toHaveBeenCalledWith(200);
        expect(res.json).toHaveBeenCalledWith({
            success: true,
            message: "Usuario reactivado correctamente",
        });
    });

    test("CP-HU14-B-08 no reactiva usuario activo", async () => {
        const selectQuery = {
            select: jest.fn().mockReturnThis(),
            eq: jest.fn().mockReturnThis(),
            single: jest.fn().mockResolvedValue({
                data: { id: "u2", rol: "usuario", estado: "activo", username: "carlos" },
                error: null,
            }),
        };

        mockFrom.mockReturnValueOnce(selectQuery);

        const req = { params: { id: "u2" }, user: { id: "admin-1" } };
        const res = mockRes();

        await reactivarUsuario(req, res);

        expect(res.status).toHaveBeenCalledWith(400);
        expect(res.json).toHaveBeenCalledWith({
            success: false,
            message: "El usuario ya está activo",
        });
    });

    test("CP-HU14-B-09 usuario no encontrado al reactivar", async () => {
        const selectQuery = {
            select: jest.fn().mockReturnThis(),
            eq: jest.fn().mockReturnThis(),
            single: jest.fn().mockResolvedValue({
                data: null,
                error: { message: "not found" },
            }),
        };

        mockFrom.mockReturnValueOnce(selectQuery);

        const req = { params: { id: "u404" }, user: { id: "admin-1" } };
        const res = mockRes();

        await reactivarUsuario(req, res);

        expect(res.status).toHaveBeenCalledWith(404);
        expect(res.json).toHaveBeenCalledWith({
            success: false,
            message: "Usuario no encontrado",
        });
    });
});