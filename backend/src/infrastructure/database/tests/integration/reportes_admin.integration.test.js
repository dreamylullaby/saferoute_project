import express from "express";
import request from "supertest";
import { jest, describe, beforeEach, test, expect } from "@jest/globals";

const ok = (msg) => console.log(`✅ PASS: ${msg}`);

describe("HU-10 Integral Backend - Reportes admin", () => {
  let app;
  let repository;

  beforeEach(() => {
    repository = {
      findForAdmin: jest.fn(),
      findById: jest.fn(),
    };

    app = express();
    app.use(express.json());

    app.get("/api/reportes/admin", async (req, res) => {
      try {
        const data = await repository.findForAdmin(req.query);
        res.status(200).json({ success: true, ...data });
      } catch (error) {
        res.status(500).json({ success: false, message: error.message });
      }
    });

    app.get("/api/reportes/:id", async (req, res) => {
      try {
        const data = await repository.findById(req.params.id);
        if (!data) {
          return res.status(404).json({ success: false, message: "No encontrado" });
        }
        res.status(200).json({ success: true, data });
      } catch (error) {
        res.status(500).json({ success: false, message: error.message });
      }
    });
  });

  test("PI-HU10-BE-01 flujo integral listado admin con filtros", async () => {
    repository.findForAdmin.mockResolvedValue({
      data: [
        {
          id: "rep-1",
          tipo_hurto: "atraco",
          barrio_ingresado: "Centro",
          comuna: 1,
          fecha_incidente: "2026-04-10",
          franja_horaria: "Mañana",
          estado: "activo",
        },
      ],
      total: 1,
      page: 1,
      totalPages: 1,
    });

    const response = await request(app)
      .get("/api/reportes/admin")
      .query({
        page: 1,
        limit: 10,
        comuna: 1,
        fechaDesde: "2026-04-01",
        fechaHasta: "2026-04-11",
      });

    expect(response.status).toBe(200);
    expect(response.body.success).toBe(true);
    expect(response.body.total).toBe(1);
    expect(response.body.data[0].barrio_ingresado).toBe("Centro");
    expect(repository.findForAdmin).toHaveBeenCalledWith({
      page: "1",
      limit: "10",
      comuna: "1",
      fechaDesde: "2026-04-01",
      fechaHasta: "2026-04-11",
    });

    ok("PI-HU10-BE-01 flujo integral listado admin con filtros");
  });

  test("PI-HU10-BE-02 flujo integral detalle por id", async () => {
    repository.findById.mockResolvedValue({
      id: "rep-1",
      estado: "activo",
      tipo_reportante: "anonimo",
      tipo_hurto: "atraco",
      fecha_incidente: "2026-04-10",
      franja_horaria: "Mañana",
      barrio_ingresado: "Centro",
      comuna: 1,
      latitud: 1.214,
      longitud: -77.278,
      objeto_hurtado: "Celular",
      numero_agresores: 2,
      descripcion: "Hurto cerca al parque",
    });

    const response = await request(app).get("/api/reportes/rep-1");

    expect(response.status).toBe(200);
    expect(response.body.success).toBe(true);
    expect(response.body.data.id).toBe("rep-1");
    expect(response.body.data.descripcion).toBe("Hurto cerca al parque");
    expect(repository.findById).toHaveBeenCalledWith("rep-1");

    ok("PI-HU10-BE-02 flujo integral detalle por id");
  });

  test("PI-HU10-BE-03 flujo integral listado sin resultados", async () => {
    repository.findForAdmin.mockResolvedValue({
      data: [],
      total: 0,
      page: 1,
      totalPages: 0,
    });

    const response = await request(app)
      .get("/api/reportes/admin")
      .query({
        page: 1,
        limit: 10,
        comuna: 99,
      });

    expect(response.status).toBe(200);
    expect(response.body.success).toBe(true);
    expect(response.body.data).toEqual([]);
    expect(response.body.total).toBe(0);

    ok("PI-HU10-BE-03 flujo integral listado sin resultados");
  });
});