import { jest, describe, test, expect, beforeEach } from "@jest/globals";

const fromMock = jest.fn();

jest.unstable_mockModule("../dbScript/db.js", () => ({
  default: {
    from: fromMock,
  },
}));

const {
  listarSolicitudesEliminacion,
  detalleSolicitudEliminacion,
  aprobarSolicitud,
  rechazarSolicitud,
} = await import("../../../interfaces/controllers/adminController.js");

function mockReq({ params = {}, body = {}, user = { id: "admin-1" }, query = {} } = {}) {
  return { params, body, user, query };
}

function mockRes() {
  const res = {};
  res.status = jest.fn(() => res);
  res.json = jest.fn(() => res);
  return res;
}

function makeSelectBuilder({ data, error = null, single = false }) {
  const builder = {
    select: jest.fn().mockReturnThis(),
    eq: jest.fn().mockReturnThis(),
    order: jest.fn().mockResolvedValue(single ? undefined : { data, error }),
    single: jest.fn().mockResolvedValue({ data, error }),
    update: jest.fn().mockReturnThis(),
  };

  if (!single) {
    builder.order = jest.fn().mockResolvedValue({ data, error });
  }

  return builder;
}

function makeUpdateSelectSingleBuilder(updatedData) {
  return {
    update: jest.fn().mockReturnThis(),
    eq: jest.fn().mockReturnThis(),
    select: jest.fn().mockReturnThis(),
    single: jest.fn().mockResolvedValue({ data: updatedData, error: null }),
  };
}

function makeUpdateEqBuilder() {
  return {
    update: jest.fn().mockReturnThis(),
    eq: jest.fn().mockResolvedValue({ error: null }),
  };
}

describe("HU-20 backend - solicitudes eliminación", () => {
  beforeEach(() => {
    jest.clearAllMocks();
  });

  test("CP-HU20-B-01 lista solicitudes pendientes", async () => {
    const req = mockReq({ query: { estado: "pendiente" } });
    const res = mockRes();

    const listBuilder = {
      select: jest.fn().mockReturnThis(),
      eq: jest.fn().mockReturnThis(),
      order: jest.fn().mockResolvedValue({
        data: [{ id: "sol-1", estado_solicitud: "pendiente" }],
        error: null,
      }),
    };

    fromMock.mockReturnValueOnce(listBuilder);

    await listarSolicitudesEliminacion(req, res);

    expect(fromMock).toHaveBeenCalledWith("solicitudes_eliminacion");
    expect(listBuilder.eq).toHaveBeenCalledWith("estado_solicitud", "pendiente");
    expect(res.status).toHaveBeenCalledWith(200);
    expect(res.json).toHaveBeenCalledWith({
      success: true,
      data: [{ id: "sol-1", estado_solicitud: "pendiente" }],
    });
  });

  test("CP-HU20-B-02 muestra detalle de solicitud existente", async () => {
    const req = mockReq({ params: { id: "sol-1" } });
    const res = mockRes();

    const detailBuilder = {
      select: jest.fn().mockReturnThis(),
      eq: jest.fn().mockReturnThis(),
      single: jest.fn().mockResolvedValue({
        data: {
          id: "sol-1",
          estado_solicitud: "pendiente",
          reportes: { id: "rep-1", estado: "oculto" },
          usuarios: { id: "usr-1", username: "luna" },
        },
        error: null,
      }),
    };

    fromMock.mockReturnValueOnce(detailBuilder);

    await detalleSolicitudEliminacion(req, res);

    expect(res.status).toHaveBeenCalledWith(200);
    expect(res.json).toHaveBeenCalledWith({
      success: true,
      data: expect.objectContaining({
        id: "sol-1",
        estado_solicitud: "pendiente",
      }),
    });
  });

  test("CP-HU20-B-03 aprueba solicitud pendiente", async () => {
    const req = mockReq({ params: { id: "sol-1" } });
    const res = mockRes();

    const fetchBuilder = {
      select: jest.fn().mockReturnThis(),
      eq: jest.fn().mockReturnThis(),
      single: jest.fn().mockResolvedValue({
        data: {
          id: "sol-1",
          reporte_id: "rep-1",
          estado_solicitud: "pendiente",
          reportes: { id: "rep-1", estado: "oculto" },
        },
        error: null,
      }),
    };

    const updateReporteBuilder = makeUpdateEqBuilder();

    const updateSolicitudBuilder = {
      update: jest.fn().mockReturnThis(),
      eq: jest.fn().mockReturnThis(),
      select: jest.fn().mockReturnThis(),
      single: jest.fn().mockResolvedValue({
        data: {
          id: "sol-1",
          estado_solicitud: "aprobada",
          admin_id: "admin-1",
        },
        error: null,
      }),
    };

    fromMock
      .mockReturnValueOnce(fetchBuilder)
      .mockReturnValueOnce(updateReporteBuilder)
      .mockReturnValueOnce(updateSolicitudBuilder);

    await aprobarSolicitud(req, res);

    expect(updateReporteBuilder.update).toHaveBeenCalledWith(
      expect.objectContaining({
        estado: "eliminado",
        actualizado_por: "admin-1",
        fecha_actualizacion: expect.any(String),
      })
    );

    expect(updateSolicitudBuilder.update).toHaveBeenCalledWith(
      expect.objectContaining({
        estado_solicitud: "aprobada",
        admin_id: "admin-1",
        fecha_resolucion: expect.any(String),
      })
    );

    expect(res.status).toHaveBeenCalledWith(200);
    expect(res.json).toHaveBeenCalledWith({
      success: true,
      message: "Solicitud aprobada. Reporte eliminado.",
      data: expect.objectContaining({
        id: "sol-1",
        estado_solicitud: "aprobada",
      }),
    });
  });

  test("CP-HU20-B-04 rechaza solicitud pendiente", async () => {
    const req = mockReq({ params: { id: "sol-1" } });
    const res = mockRes();

    const fetchBuilder = {
      select: jest.fn().mockReturnThis(),
      eq: jest.fn().mockReturnThis(),
      single: jest.fn().mockResolvedValue({
        data: {
          id: "sol-1",
          estado_solicitud: "pendiente",
        },
        error: null,
      }),
    };

    const updateSolicitudBuilder = {
      update: jest.fn().mockReturnThis(),
      eq: jest.fn().mockReturnThis(),
      select: jest.fn().mockReturnThis(),
      single: jest.fn().mockResolvedValue({
        data: {
          id: "sol-1",
          estado_solicitud: "rechazada",
          admin_id: "admin-1",
        },
        error: null,
      }),
    };

    fromMock
      .mockReturnValueOnce(fetchBuilder)
      .mockReturnValueOnce(updateSolicitudBuilder);

    await rechazarSolicitud(req, res);

    expect(updateSolicitudBuilder.update).toHaveBeenCalledWith(
      expect.objectContaining({
        estado_solicitud: "rechazada",
        admin_id: "admin-1",
        fecha_resolucion: expect.any(String),
      })
    );

    expect(res.status).toHaveBeenCalledWith(200);
    expect(res.json).toHaveBeenCalledWith({
      success: true,
      message: "Solicitud rechazada.",
      data: expect.objectContaining({
        id: "sol-1",
        estado_solicitud: "rechazada",
      }),
    });
  });

  test("CP-HU20-B-05 rechaza estado inválido en listado", async () => {
    const req = mockReq({ query: { estado: "otro" } });
    const res = mockRes();

    await listarSolicitudesEliminacion(req, res);

    expect(res.status).toHaveBeenCalledWith(400);
    expect(res.json).toHaveBeenCalledWith({
      success: false,
      message: "estado inválido. Valores: pendiente, aprobada, rechazada",
    });
  });

  test("CP-HU20-B-06 impide aprobar solicitud ya resuelta", async () => {
    const req = mockReq({ params: { id: "sol-1" } });
    const res = mockRes();

    const fetchBuilder = {
      select: jest.fn().mockReturnThis(),
      eq: jest.fn().mockReturnThis(),
      single: jest.fn().mockResolvedValue({
        data: {
          id: "sol-1",
          estado_solicitud: "aprobada",
          reportes: { id: "rep-1", estado: "eliminado" },
        },
        error: null,
      }),
    };

    fromMock.mockReturnValueOnce(fetchBuilder);

    await aprobarSolicitud(req, res);

    expect(res.status).toHaveBeenCalledWith(400);
    expect(res.json).toHaveBeenCalledWith({
      success: false,
      message: "La solicitud ya fue aprobada",
    });
  });
});
