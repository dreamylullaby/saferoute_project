// src/tests/integration/EstadisticasAdmin.integration.test.jsx
import React from "react";
import { describe, test, expect, vi, beforeEach } from "vitest";
import "@testing-library/jest-dom/vitest";
import { render, screen, waitFor } from "@testing-library/react";
import userEvent from "@testing-library/user-event";

const apiMock = vi.hoisted(() => ({
  get: vi.fn(),
}));

vi.mock("../../services/api.js", () => ({
  default: apiMock,
}));

vi.mock("../../services/reportService.js", async () => {
  const actual = await vi.importActual("../../services/reportService.js");
  return {
    ...actual,
    getResumen: vi.fn(),
    getReportesMapa: vi.fn(),
  };
});

vi.mock("react-chartjs-2", () => ({
  Bar: () => <div>BarChart</div>,
  Doughnut: () => <div>DoughnutChart</div>,
  Line: () => <div>LineChart</div>,
}));

vi.mock("mapbox-gl", () => ({
  default: {
    accessToken: "",
    Map: function () {
      return {
        addControl: vi.fn(),
        on: vi.fn((event, cb) => {
          if (event === "load") cb();
        }),
        remove: vi.fn(),
        isStyleLoaded: vi.fn(() => true),
        getSource: vi.fn(() => null),
        addSource: vi.fn(),
        addLayer: vi.fn(),
      };
    },
    NavigationControl: function () {
      return {};
    },
  },
}));

import * as reportService from "../../services/reportService.js";
import TabEstadisticas from "../../page/tabs/TabEstadisticas.jsx";

const resumenMock = {
  porTipo: { atraco: 4, raponazo: 2, fleteo: 1, cosquilleo: 1 },
  porComuna: { 1: 2, 2: 5, 3: 1 },
  porFranja: {
    "06:00-11:59": 1,
    "12:00-17:59": 2,
    "18:00-23:59": 4,
    "00:00-05:59": 1,
  },
  porFecha: {
    "2026-04-01": 2,
    "2026-05-01": 3,
  },
  porCorregimiento: { Catambuco: 1 },
};

const resumenRuralMock = {
  porTipo: { atraco: 1, raponazo: 1 },
  porComuna: {},
  porFranja: {
    "06:00-11:59": 0,
    "12:00-17:59": 1,
    "18:00-23:59": 1,
    "00:00-05:59": 0,
  },
  porFecha: {
    "2026-05-01": 1,
  },
  porCorregimiento: { Catambuco: 1, Genoy: 1 },
};

describe("HU-15 TabEstadisticas frontend integral", () => {
  beforeEach(() => {
    vi.clearAllMocks();

    reportService.getResumen.mockResolvedValue(resumenMock);
    reportService.getReportesMapa.mockResolvedValue([
      { latitud: "1.21", longitud: "-77.28", tipo_hurto: "atraco" },
    ]);

    apiMock.get.mockImplementation((url, config) => {
      if (url === "/api/reportes/corregimientos") {
        return Promise.resolve({
          data: {
            data: [
              { id: 1, nombre: "Catambuco" },
              { id: 2, nombre: "Genoy" },
            ],
          },
        });
      }

      if (url === "/api/reportes/admin/resumen" && config?.params?.zona_tipo === "rural") {
        return Promise.resolve({ data: { data: resumenRuralMock } });
      }

      if (url === "/api/reportes/admin/resumen" && config?.params?.zona_tipo === "urbana") {
        return Promise.resolve({ data: { data: resumenMock } });
      }

      return Promise.resolve({ data: { data: resumenMock } });
    });
  });

  test("CP-HU15-I-01 carga dashboard y muestra bloques principales", async () => {
    render(<TabEstadisticas />);

    expect(await screen.findByText(/Mostrando estadísticas urbanas/i)).toBeInTheDocument();
    expect(screen.getByText(/Mapa de Calor por Comuna/i)).toBeInTheDocument();
    expect(screen.getByText(/Distribución de Tipos de Hurto/i)).toBeInTheDocument();
    expect(screen.getByText(/Análisis por Franja Horaria/i)).toBeInTheDocument();
  });

  test("CP-HU15-I-02 alterna urbano\/rural y actualiza resumen", async () => {
    const user = userEvent.setup();
    render(<TabEstadisticas />);

    await screen.findByText(/Mostrando estadísticas urbanas/i);
    await user.click(screen.getByRole("button", { name: /Rural/i }));

    await waitFor(() => {
      expect(apiMock.get).toHaveBeenCalledWith("/api/reportes/admin/resumen", {
        params: { zona_tipo: "rural" },
      });
    });

    expect(await screen.findByText(/Mostrando estadísticas rurales/i)).toBeInTheDocument();
    expect(screen.getByText(/Mapa de Calor Rural/i)).toBeInTheDocument();
  });

  test("CP-HU15-I-03 filtra por rango y permite limpiar", async () => {
    const user = userEvent.setup();
    render(<TabEstadisticas />);

    const inputs = await screen.findAllByDisplayValue("");
    await user.type(inputs[0], "2026-05-01");
    await user.type(inputs[1], "2026-05-31");

    const limpiar = await screen.findByRole("button", { name: /Limpiar/i });
    expect(limpiar).toBeInTheDocument();

    await user.click(limpiar);

    await waitFor(() => {
      const vacios = screen.getAllByDisplayValue("");
      expect(vacios.length).toBeGreaterThanOrEqual(2);
    });
  });

  test("CP-HU15-I-04 error al cargar estadísticas", async () => {
    reportService.getResumen.mockRejectedValueOnce(new Error("fallo"));
    render(<TabEstadisticas />);

    expect(await screen.findByText(/Error al cargar estadísticas/i)).toBeInTheDocument();
  });
});