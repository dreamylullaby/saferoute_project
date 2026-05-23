// src/infrastructure/database/tests/EstadisticasAdminController.test.js
import { jest, describe, test, expect, beforeEach } from '@jest/globals';
import ReportController from "../../../interfaces/controllers/reportController.js";

function mockRes() {
  return {
    status: jest.fn().mockReturnThis(),
    json: jest.fn(),
  };
}

describe("HU-15 reportController getResumen unitario", () => {
  let repository;
  let controller;

  beforeEach(() => {
    repository = {
      getResumen: jest.fn(),
    };
    controller = new ReportController(repository);
  });

  test("CP-HU15-B-01 obtiene resumen admin sin zona_tipo", async () => {
    repository.getResumen.mockResolvedValue({
      porTipo: { atraco: 2 },
      porComuna: { 1: 1 },
      porFranja: { "18:00-23:59": 2 },
      porFecha: { "2026-05-01": 2 },
    });

    const req = { query: {} };
    const res = mockRes();

    await controller.getResumen(req, res);

    expect(repository.getResumen).toHaveBeenCalledWith(null);
    expect(res.status).toHaveBeenCalledWith(200);
    expect(res.json).toHaveBeenCalledWith({
      success: true,
      data: expect.objectContaining({
        porTipo: { atraco: 2 },
      }),
    });
  });

  test("CP-HU15-B-02 obtiene resumen admin con zona_tipo rural", async () => {
    repository.getResumen.mockResolvedValue({
      porTipo: { atraco: 1 },
      porCorregimiento: { Catambuco: 1 },
    });

    const req = { query: { zona_tipo: "rural" } };
    const res = mockRes();

    await controller.getResumen(req, res);

    expect(repository.getResumen).toHaveBeenCalledWith("rural");
    expect(res.status).toHaveBeenCalledWith(200);
    expect(res.json).toHaveBeenCalledWith({
      success: true,
      data: expect.objectContaining({
        porTipo: { atraco: 1 },
      }),
    });
  });

  test("CP-HU15-B-03 responde 500 si el repositorio falla", async () => {
    repository.getResumen.mockRejectedValue(new Error("db error"));

    const req = { query: { zona_tipo: "urbana" } };
    const res = mockRes();

    await controller.getResumen(req, res);

    expect(repository.getResumen).toHaveBeenCalledWith("urbana");
    expect(res.status).toHaveBeenCalledWith(500);
    expect(res.json).toHaveBeenCalledWith({
      success: false,
      message: "db error",
    });
  });
});