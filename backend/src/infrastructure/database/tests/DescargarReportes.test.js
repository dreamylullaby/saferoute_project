import { jest, describe, test, expect, beforeEach } from "@jest/globals";

const fromMock = jest.fn();
const writeMock = jest.fn(() => Promise.resolve());

jest.unstable_mockModule("../dbScript/db.js", () => ({
  default: {
    from: fromMock,
  },
}));

jest.unstable_mockModule("exceljs", () => ({
  default: {
    Workbook: jest.fn().mockImplementation(() => ({
      addWorksheet: jest.fn(() => ({
        columns: [],
        getRow: jest.fn(() => ({
          eachCell: jest.fn((cb) => {
            cb({});
          }),
        })),
        addRow: jest.fn(),
      })),
      xlsx: {
        write: writeMock,
      },
    })),
  },
}));

const { exportarReportes } = await import("../../../interfaces/controllers/adminController.js");

function mockReq({ query = {}, user = { id: "admin-1", rol: "admin" } } = {}) {
  return { query, user };
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

function makeAwaitableQuery(result) {
  const builder = {
    select: jest.fn(() => builder),
    limit: jest.fn(() => builder),
    gte: jest.fn(() => builder),
    lte: jest.fn(() => builder),
    eq: jest.fn(() => builder),
    then: (resolve, reject) => Promise.resolve(result).then(resolve, reject),
  };
  return builder;
}

describe("HU-22 backend - exportar reportes", () => {
  beforeEach(() => {
    jest.clearAllMocks();
  });

  test("CP-HU22-B-01 exporta CSV con filtros válidos", async () => {
    const req = mockReq({
      query: {
        fechaDesde: "2026-05-01",
        fechaHasta: "2026-05-31",
        zona: "5",
        estado: "activo",
        formato: "csv",
      },
    });
    const res = mockRes();

    const builder = makeAwaitableQuery({
      data: [
        {
          reporte_id: "rep-1",
          fecha_incidente: "2026-05-10",
          franja_horaria: "06:00-11:59",
          tipo_hurto: "atraco",
          tipo_reportante: "ciudadano",
          objeto_hurtado: "celular",
          numero_agresores: 2,
          descripcion: "robo simple",
          direccion: "calle 1",
          barrio_ingresado: "Centro",
          barrio_normalizado: "Centro",
          comuna: 5,
          latitud: "1.1",
          longitud: "2.2",
          estado: "activo",
          fecha_creacion: "2026-05-10T10:00:00Z",
        },
      ],
      error: null,
    });

    fromMock.mockReturnValueOnce(builder);

    await exportarReportes(req, res);

    expect(fromMock).toHaveBeenCalledWith("vw_export_reportes_admin");
    expect(builder.select).toHaveBeenCalledWith("*");
    expect(builder.limit).toHaveBeenCalledWith(5001);
    expect(builder.gte).toHaveBeenCalledWith("fecha_incidente", "2026-05-01");
    expect(builder.lte).toHaveBeenCalledWith("fecha_incidente", "2026-05-31");
    expect(builder.eq).toHaveBeenCalledWith("estado", "activo");
    expect(builder.eq).toHaveBeenCalledWith("comuna", 5);
    expect(res.setHeader).toHaveBeenCalledWith("Content-Type", "text/csv; charset=utf-8");
    expect(res.setHeader).toHaveBeenCalledWith(
      "Content-Disposition",
      expect.stringMatching(/^attachment; filename="reportes_\d+\.csv"$/)
    );
    expect(res.send).toHaveBeenCalledWith(expect.stringContaining("reporte_id,fecha_incidente"));
  });

  test("CP-HU22-B-02 exporta Excel con filtros válidos", async () => {
    const req = mockReq({
      query: { formato: "excel" },
    });
    const res = mockRes();

    const builder = makeAwaitableQuery({
      data: [
        {
          reporte_id: "rep-1",
          fecha_incidente: "2026-05-10",
          franja_horaria: "06:00-11:59",
          tipo_hurto: "atraco",
          tipo_reportante: "ciudadano",
          objeto_hurtado: "celular",
          numero_agresores: 2,
          descripcion: "robo simple",
          direccion: "calle 1",
          barrio_ingresado: "Centro",
          barrio_normalizado: "Centro",
          comuna: 5,
          latitud: "1.1",
          longitud: "2.2",
          estado: "activo",
          fecha_creacion: "2026-05-10T10:00:00Z",
        },
      ],
      error: null,
    });

    fromMock.mockReturnValueOnce(builder);

    await exportarReportes(req, res);

    expect(res.setHeader).toHaveBeenCalledWith(
      "Content-Type",
      "application/vnd.openxmlformats-officedocument.spreadsheetml.sheet"
    );
    expect(res.setHeader).toHaveBeenCalledWith(
      "Content-Disposition",
      expect.stringMatching(/^attachment; filename="reportes_\d+\.xlsx"$/)
    );
    expect(writeMock).toHaveBeenCalledWith(res);
    expect(res.end).toHaveBeenCalled();
  });

  test("CP-HU22-B-03 rechaza formato inválido", async () => {
    const req = mockReq({
      query: { formato: "pdf" },
    });
    const res = mockRes();

    await exportarReportes(req, res);

    expect(res.status).toHaveBeenCalledWith(400);
    expect(res.json).toHaveBeenCalledWith({
      success: false,
      message: "formato debe ser 'csv' o 'excel'",
    });
  });

  test("CP-HU22-B-04 responde mensaje cuando no hay datos", async () => {
    const req = mockReq({
      query: { formato: "csv" },
    });
    const res = mockRes();

    const builder = makeAwaitableQuery({
      data: [],
      error: null,
    });

    fromMock.mockReturnValueOnce(builder);

    await exportarReportes(req, res);

    expect(res.status).toHaveBeenCalledWith(200);
    expect(res.json).toHaveBeenCalledWith({
      success: true,
      message: "No hay registros para exportar con los filtros aplicados.",
    });
  });

  test("CP-HU22-B-05 rechaza exportación si excede límite", async () => {
    const req = mockReq({
      query: { formato: "csv" },
    });
    const res = mockRes();

    const data = Array.from({ length: 5001 }, (_, i) => ({
      reporte_id: `rep-${i}`,
    }));

    const builder = makeAwaitableQuery({
      data,
      error: null,
    });

    fromMock.mockReturnValueOnce(builder);

    await exportarReportes(req, res);

    expect(res.status).toHaveBeenCalledWith(400);
    expect(res.json).toHaveBeenCalledWith({
      success: false,
      message: "La consulta excede el límite de 5000 registros. Aplica más filtros para reducir los resultados.",
    });
  });
});