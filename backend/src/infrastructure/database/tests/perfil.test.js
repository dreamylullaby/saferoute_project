import { jest, describe, test, expect, beforeEach } from "@jest/globals";

const mockCompare = jest.fn();
const mockHash = jest.fn();
const mockFrom = jest.fn();
const mockRpc = jest.fn();

jest.unstable_mockModule("bcrypt", () => ({
  default: {
    compare: mockCompare,
    hash: mockHash,
  },
}));

jest.unstable_mockModule("../../database/dbScript/db.js", () => ({
  default: {
    from: mockFrom,
    rpc: mockRpc,
  },
}));

const { default: bcrypt } = await import("bcrypt");
const { default: db } = await import("../../database/dbScript/db.js");
const {
  getPerfil,
  actualizarPerfil,
  cambiarPassword,
  actualizarNotificaciones,
  eliminarCuenta,
} = await import("../../../interfaces/controllers/perfilController.js");

function mockRes() {
  return {
    status: jest.fn().mockReturnThis(),
    json: jest.fn().mockReturnThis(),
  };
}

describe("HU-19 backend perfilController", () => {
  beforeEach(() => {
    jest.clearAllMocks();
  });

  test("CP-HU19-B-01 obtiene perfil correctamente", async () => {
    const req = { user: { id: "u1" } };
    const res = mockRes();

    mockFrom
      .mockReturnValueOnce({
        select: () => ({
          eq: () => ({
            single: jest.fn().mockResolvedValue({
              data: {
                id: "u1",
                username: "Luna",
                correo: "luna@test.com",
                rol: "usuario",
                auth_provider: "local",
                foto_url: null,
                fecha_creacion: "2026-05-01",
                estado: "activo",
                fcm_token: null,
              },
              error: null,
            }),
          }),
        }),
      })
      .mockReturnValueOnce({
        select: () => ({
          eq: () => ({
            single: jest.fn().mockResolvedValue({
              data: { activo: true, radio_metros: 500 },
              error: null,
            }),
          }),
        }),
      });

    await getPerfil(req, res);

    expect(res.status).toHaveBeenCalledWith(200);
    expect(res.json).toHaveBeenCalledWith({
      data: expect.objectContaining({
        id: "u1",
        username: "Luna",
        notificaciones_activas: true,
        radio_metros: 500,
      }),
    });
  });

  test("CP-HU19-B-02 actualiza username válido", async () => {
    const req = { user: { id: "u1" }, body: { username: "LunaBeltran" } };
    const res = mockRes();

    mockFrom
      .mockReturnValueOnce({
        select: () => ({
          eq: () => ({
            neq: () => ({
              single: jest.fn().mockResolvedValue({ data: null }),
            }),
          }),
        }),
      })
      .mockReturnValueOnce({
        update: () => ({
          eq: () => ({
            select: () => ({
              single: jest.fn().mockResolvedValue({
                data: {
                  id: "u1",
                  username: "LunaBeltran",
                  correo: "luna@test.com",
                  foto_url: null,
                  rol: "usuario",
                },
                error: null,
              }),
            }),
          }),
        }),
      });

    await actualizarPerfil(req, res);

    expect(res.status).toHaveBeenCalledWith(200);
    expect(res.json).toHaveBeenCalledWith({
      success: true,
      data: expect.objectContaining({ username: "LunaBeltran" }),
    });
  });

  test("CP-HU19-B-03 rechaza username inválido", async () => {
    const req = { user: { id: "u1" }, body: { username: "ab" } };
    const res = mockRes();

    await actualizarPerfil(req, res);

    expect(res.status).toHaveBeenCalledWith(400);
    expect(res.json).toHaveBeenCalledWith({
      message: "El apodo debe tener al menos 3 caracteres",
    });
  });

  test("CP-HU19-B-04 cambia contraseña correctamente", async () => {
    const req = {
      user: { id: "u1" },
      body: { passwordActual: "actual123", nuevaPassword: "nueva12345" },
    };
    const res = mockRes();

    mockFrom
      .mockReturnValueOnce({
        select: () => ({
          eq: () => ({
            single: jest.fn().mockResolvedValue({
              data: {
                id: "u1",
                password_hash: "hash",
                auth_provider: "local",
              },
              error: null,
            }),
          }),
        }),
      })
      .mockReturnValueOnce({
        update: () => ({
          eq: jest.fn().mockResolvedValue({ error: null }),
        }),
      });

    mockCompare.mockResolvedValue(true);
    mockHash.mockResolvedValue("nuevo_hash");

    await cambiarPassword(req, res);

    expect(mockCompare).toHaveBeenCalledWith("actual123", "hash");
    expect(mockHash).toHaveBeenCalledWith("nueva12345", 12);
    expect(res.status).toHaveBeenCalledWith(200);
  });

  test("CP-HU19-B-05 rechaza contraseña actual incorrecta", async () => {
    const req = {
      user: { id: "u1" },
      body: { passwordActual: "mal", nuevaPassword: "nueva12345" },
    };
    const res = mockRes();

    mockFrom.mockReturnValueOnce({
      select: () => ({
        eq: () => ({
          single: jest.fn().mockResolvedValue({
            data: {
              id: "u1",
              password_hash: "hash",
              auth_provider: "local",
            },
            error: null,
          }),
        }),
      }),
    });

    mockCompare.mockResolvedValue(false);

    await cambiarPassword(req, res);

    expect(res.status).toHaveBeenCalledWith(401);
    expect(res.json).toHaveBeenCalledWith({
      message: "La contraseña actual es incorrecta",
    });
  });

  test("CP-HU19-B-06 actualiza notificaciones correctamente", async () => {
    const req = {
      user: { id: "u1" },
      body: { activo: false, radio_metros: 700 },
    };
    const res = mockRes();

    mockFrom.mockReturnValueOnce({
      upsert: () => ({
        select: () => ({
          single: jest.fn().mockResolvedValue({
            data: { usuario_id: "u1", activo: false, radio_metros: 700 },
            error: null,
          }),
        }),
      }),
    });

    await actualizarNotificaciones(req, res);

    expect(res.status).toHaveBeenCalledWith(200);
    expect(res.json).toHaveBeenCalledWith({
      success: true,
      data: expect.objectContaining({
        usuario_id: "u1",
        activo: false,
        radio_metros: 700,
      }),
    });
  });

  test("CP-HU19-B-07 elimina cuenta correctamente", async () => {
    const req = { user: { id: "u1" }, body: { password: "actual123" } };
    const res = mockRes();

    mockFrom.mockReturnValueOnce({
      select: () => ({
        eq: () => ({
          single: jest.fn().mockResolvedValue({
            data: {
              id: "u1",
              auth_provider: "local",
              password_hash: "hash",
              estado: "activo",
            },
            error: null,
          }),
        }),
      }),
    });

    mockCompare.mockResolvedValue(true);
    mockRpc.mockResolvedValue({ error: null });

    await eliminarCuenta(req, res);

    expect(mockRpc).toHaveBeenCalledWith("eliminar_cuenta_usuario", {
      p_usuario_id: "u1",
    });
    expect(res.status).toHaveBeenCalledWith(200);
  });

  test("CP-HU19-B-08 rechaza eliminar cuenta local sin password", async () => {
    const req = { user: { id: "u1" }, body: {} };
    const res = mockRes();

    mockFrom.mockReturnValueOnce({
      select: () => ({
        eq: () => ({
          single: jest.fn().mockResolvedValue({
            data: {
              id: "u1",
              auth_provider: "local",
              password_hash: "hash",
              estado: "activo",
            },
            error: null,
          }),
        }),
      }),
    });

    await eliminarCuenta(req, res);

    expect(res.status).toHaveBeenCalledWith(400);
    expect(res.json).toHaveBeenCalledWith({
      message: "Debes confirmar tu contraseña para eliminar la cuenta",
    });
  });
});