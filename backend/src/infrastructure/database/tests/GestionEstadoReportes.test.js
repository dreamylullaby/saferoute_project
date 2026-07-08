import { jest, describe, test, expect, beforeEach } from "@jest/globals";

const fromMock = jest.fn();

jest.unstable_mockModule("../../database/dbScript/db.js", () => ({
  default: {
    from: fromMock,
  },
}));

const {
  cambiarEstadoReporte,
  hardDeleteReporte,
  editarTipoHurtoReporte,
} = await import("../../../interfaces/controllers/adminController.js");

function mockReq({ params = {}, body = {}, user = { id: "admin-1" }, query = {} } = {}) {
  return { params, body, user, query };
}

function mockRes() {
  const res = {};
  res.status = jest.fn(() => res);
  res.json = jest.fn(() => res);
  res.send = jest.fn(() => res);
  res.setHeader = jest.fn(() => res);
  res.end = jest.fn(() => res);
  return res;
}

function makeSelectSingleBuilder(result) {
  return {
    select: jest.fn().mockReturnThis(),
    eq: jest.fn().mockReturnThis(),
    single: jest.fn().mockResolvedValue(result),
  };
}

function makeUpdateBuilder() {
  return {
    update: jest.fn().mockReturnThis(),
    eq: jest.fn().mockResolvedValue({ error: null }),
  };
}

function makeDeleteBuilder() {
  return {
    delete: jest.fn().mockReturnThis(),
    eq: jest.fn().mockResolvedValue({ error: null }),
  };
}

function makeInsertBuilder() {
  return {
    insert: jest.fn().mockResolvedValue({ error: null }),
  };
}

describe("HU-16 backend - adminController reportes", () => {
  beforeEach(() => {
    jest.clearAllMocks();
  });

  test("CP-HU16-B-01 oculta un reporte válido", async () => {
    const req = mockReq({
      params: { id: "rep-1" },
      body: { estado: "oculto" },
    });
    const res = mockRes();

    const selectBuilder = makeSelectSingleBuilder({
      data: {
        id: "rep-1",
        estado: "activo",
        tipo_hurto: "atraco",
        barrio_ingresado: "Centro",
      },
      error: null,
    });
    const updateBuilder = makeUpdateBuilder();
    const auditBuilder = makeInsertBuilder();

    fromMock
      .mockReturnValueOnce(selectBuilder)
      .mockReturnValueOnce(updateBuilder)
      .mockReturnValueOnce(auditBuilder);

    await cambiarEstadoReporte(req, res);

    expect(fromMock).toHaveBeenNthCalledWith(1, "reportes");
    expect(fromMock).toHaveBeenNthCalledWith(2, "reportes");
    expect(fromMock).toHaveBeenNthCalledWith(3, "auditoria_reportes");

    expect(updateBuilder.update).toHaveBeenCalledWith(
      expect.objectContaining({
        estado: "oculto",
        actualizado_por: "admin-1",
        fecha_actualizacion: expect.any(String),
      })
    );

    expect(auditBuilder.insert).toHaveBeenCalledWith(
      expect.objectContaining({
        admin_id: "admin-1",
        reporte_id: "rep-1",
        accion: "ocultar",
      })
    );

    expect(res.status).toHaveBeenCalledWith(200);
    expect(res.json).toHaveBeenCalledWith({
      success: true,
      message: "Estado del reporte actualizado a 'oculto'",
      data: {
        id: "rep-1",
        estadoAnterior: "activo",
        estadoNuevo: "oculto",
      },
    });
  });

  test("CP-HU16-B-02 elimina lógicamente un reporte válido", async () => {
    const req = mockReq({
      params: { id: "rep-2" },
      body: { estado: "eliminado", motivo: "Contenido inválido" },
    });
    const res = mockRes();

    const selectBuilder = makeSelectSingleBuilder({
      data: {
        id: "rep-2",
        estado: "oculto",
        tipo_hurto: "fleteo",
        barrio_ingresado: "San Juan",
      },
      error: null,
    });
    const updateBuilder = makeUpdateBuilder();
    const auditBuilder = makeInsertBuilder();

    fromMock
      .mockReturnValueOnce(selectBuilder)
      .mockReturnValueOnce(updateBuilder)
      .mockReturnValueOnce(auditBuilder);

    await cambiarEstadoReporte(req, res);

    expect(updateBuilder.update).toHaveBeenCalledWith(
      expect.objectContaining({
        estado: "eliminado",
        actualizado_por: "admin-1",
        fecha_actualizacion: expect.any(String),
      })
    );

    expect(auditBuilder.insert).toHaveBeenCalledWith(
      expect.objectContaining({
        accion: "eliminar",
      })
    );

    expect(res.status).toHaveBeenCalledWith(200);
    expect(res.json).toHaveBeenCalledWith({
      success: true,
      message: "Estado del reporte actualizado a 'eliminado'",
      data: {
        id: "rep-2",
        estadoAnterior: "oculto",
        estadoNuevo: "eliminado",
      },
    });
  });

  test("CP-HU16-B-03 rechaza estado inválido", async () => {
    const req = mockReq({
      params: { id: "rep-3" },
      body: { estado: "pendiente" },
    });
    const res = mockRes();

    await cambiarEstadoReporte(req, res);

    expect(res.status).toHaveBeenCalledWith(400);
    expect(res.json).toHaveBeenCalledWith({
      success: false,
      message: "Estado inválido. Valores permitidos: activo, oculto, eliminado",
    });
  });

  test("CP-HU16-B-04 elimina permanentemente un reporte ya eliminado", async () => {
    const req = mockReq({
      params: { id: "rep-4" },
    });
    const res = mockRes();

    const selectBuilder = makeSelectSingleBuilder({
      data: {
        id: "rep-4",
        estado: "eliminado",
        tipo_hurto: "raponazo",
        barrio_ingresado: "La Rosa",
      },
      error: null,
    });
    const deleteBuilder = makeDeleteBuilder();
    const auditBuilder = {
      insert: jest.fn().mockReturnValue({
        catch: jest.fn(),
      }),
    };

    fromMock
      .mockReturnValueOnce(selectBuilder)
      .mockReturnValueOnce(deleteBuilder)
      .mockReturnValueOnce(auditBuilder);

    await hardDeleteReporte(req, res);

    expect(deleteBuilder.delete).toHaveBeenCalled();
    expect(auditBuilder.insert).toHaveBeenCalledWith(
      expect.objectContaining({
        admin_id: "admin-1",
        reporte_id: "rep-4",
        accion: "eliminar_permanente",
      })
    );

    expect(res.status).toHaveBeenCalledWith(200);
    expect(res.json).toHaveBeenCalledWith({
      success: true,
      message: "Reporte eliminado permanentemente",
    });
  });

  test("CP-HU16-B-05 impide hard delete si el reporte no está eliminado", async () => {
    const req = mockReq({
      params: { id: "rep-5" },
    });
    const res = mockRes();

    const selectBuilder = makeSelectSingleBuilder({
      data: {
        id: "rep-5",
        estado: "activo",
        tipo_hurto: "atraco",
        barrio_ingresado: "Centro",
      },
      error: null,
    });

    fromMock.mockReturnValueOnce(selectBuilder);

    await hardDeleteReporte(req, res);

    expect(res.status).toHaveBeenCalledWith(400);
    expect(res.json).toHaveBeenCalledWith({
      success: false,
      message: "Solo se pueden eliminar permanentemente reportes con estado 'eliminado'",
    });
  });

  test("CP-HU16-B-06 edita tipo de hurto con descripción válida", async () => {
    const req = mockReq({
      params: { id: "rep-6" },
      body: { tipo_hurto: "cosquilleo" },
    });
    const res = mockRes();

    const selectBuilder = makeSelectSingleBuilder({
      data: {
        id: "rep-6",
        tipo_hurto: "atraco",
        descripcion: "Le hurtaron el celular en la calle",
      },
      error: null,
    });
    const updateBuilder = makeUpdateBuilder();
    const auditBuilder = makeInsertBuilder();

    fromMock
      .mockReturnValueOnce(selectBuilder)
      .mockReturnValueOnce(updateBuilder)
      .mockReturnValueOnce(auditBuilder);

    await editarTipoHurtoReporte(req, res);

    expect(updateBuilder.update).toHaveBeenCalledWith(
      expect.objectContaining({
        tipo_hurto: "cosquilleo",
        actualizado_por: "admin-1",
        fecha_actualizacion: expect.any(String),
      })
    );

    expect(auditBuilder.insert).toHaveBeenCalledWith(
      expect.objectContaining({
        admin_id: "admin-1",
        reporte_id: "rep-6",
        campos_modificados: ["tipo_hurto"],
        valores_anteriores: { tipo_hurto: "atraco" },
      })
    );

    expect(res.status).toHaveBeenCalledWith(200);
    expect(res.json).toHaveBeenCalledWith({
      success: true,
      message: "Tipo de hurto actualizado correctamente",
      data: {
        id: "rep-6",
        tipoAnterior: "atraco",
        tipoNuevo: "cosquilleo",
      },
    });
  });
});