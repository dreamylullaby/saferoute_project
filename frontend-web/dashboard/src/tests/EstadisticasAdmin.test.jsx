// src/tests/EstadisticasAdmin.test.jsx
import React from "react";
import { describe, test, expect, vi, beforeEach } from "vitest";
import "@testing-library/jest-dom/vitest";
import { render, screen, waitFor, fireEvent } from "@testing-library/react";
import userEvent from "@testing-library/user-event";

const reportServiceMock = vi.hoisted(() => ({
  getResumen: vi.fn(),
  getReportesMapa: vi.fn(),
}));

const apiMock = vi.hoisted(() => ({
  get: vi.fn(),
}));

vi.mock("../services/reportService.js", () => reportServiceMock);
vi.mock("../services/api.js", () => ({
  default: apiMock,
}));

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

import TabEstadisticas from "../page/tabs/TabEstadisticas.jsx";

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
    "2026-04-10": 1,
    "2026-05-01": 3,
    "2026-05-04": 2,
  },
  porCorregimiento: {
    Catambuco: 3,
    Genoy: 1,
  },
};

const resumenRuralMock = {
  porTipo: { atraco: 1, raponazo: 1, fleteo: 0, cosquilleo: 0 },
  porComuna: {},
  porFranja: {
    "06:00-11:59": 0,
    "12:00-17:59": 1,
    "18:00-23:59": 1,
    "00:00-05:59": 0,
  },
  porFecha: {
    "2026-05-01": 1,
    "2026-05-02": 1,
  },
  porCorregimiento: {
    Catambuco: 1,
    Genoy: 1,
  },
};

describe("HU-15 TabEstadisticas unitario", () => {
  beforeEach(() => {
    vi.clearAllMocks();

    reportServiceMock.getResumen.mockResolvedValue(resumenMock);
    reportServiceMock.getReportesMapa.mockResolvedValue([
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

  test("CP-HU15-F-01 renderiza estadísticas iniciales al cargar", async () => {
    render(<TabEstadisticas />);

    expect(await screen.findByText(/Mostrando estadísticas urbanas/i)).toBeInTheDocument();
    expect(screen.getByText(/Distribución de Tipos de Hurto/i)).toBeInTheDocument();
    expect(screen.getByText(/Análisis por Franja Horaria/i)).toBeInTheDocument();
    expect(screen.getByText(/Comparativa Mensual|Tendencia Semanal/i)).toBeInTheDocument();
    expect(screen.getByText("LineChart")).toBeInTheDocument();
    expect(screen.getByText("DoughnutChart")).toBeInTheDocument();
  });

  test("CP-HU15-F-02 cambia a modo rural y consulta resumen rural", async () => {
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

  test("CP-HU15-F-03 vuelve a urbano y consulta resumen urbana", async () => {
    const user = userEvent.setup();
    render(<TabEstadisticas />);

    await screen.findByText(/Mostrando estadísticas urbanas/i);
    await user.click(screen.getByRole("button", { name: /Rural/i }));
    await screen.findByText(/Mostrando estadísticas rurales/i);

    await user.click(screen.getByRole("button", { name: /Urbano/i }));

    await waitFor(() => {
      expect(apiMock.get).toHaveBeenCalledWith("/api/reportes/admin/resumen", {
        params: { zona_tipo: "urbana" },
      });
    });

    expect(await screen.findByText(/Mostrando estadísticas urbanas/i)).toBeInTheDocument();
  });

 test("CP-HU15-F-04 aplica filtro de fechas en comparativa", async () => {
  render(<TabEstadisticas />);

const desde = await screen.findByPlaceholderText("Desde");
const hasta = await screen.findByPlaceholderText("Hasta");

  fireEvent.change(desde, { target: { value: "2026-05-01" } });
  fireEvent.change(hasta, { target: { value: "2026-05-31" } });

  await waitFor(() => {
    expect(desde).toHaveValue("2026-05-01");
    expect(hasta).toHaveValue("2026-05-31");
  });

  expect(await screen.findByRole("button", { name: /Limpiar/i })).toBeInTheDocument();
});

  test("CP-HU15-F-05 limpia filtro de fechas", async () => {
  const user = userEvent.setup();
  render(<TabEstadisticas />);

const desde = await screen.findByPlaceholderText("Desde");
const hasta = await screen.findByPlaceholderText("Hasta");

  fireEvent.change(desde, { target: { value: "2026-05-01" } });
  fireEvent.change(hasta, { target: { value: "2026-05-31" } });

  const limpiar = await screen.findByRole("button", { name: /Limpiar/i });
  await user.click(limpiar);

  await waitFor(() => {
    expect(screen.getByPlaceholderText("Desde")).toHaveValue("");
    expect(screen.getByPlaceholderText("Hasta")).toHaveValue("");
  });
});

  test("CP-HU15-F-06 muestra error cuando falla getResumen", async () => {
    reportServiceMock.getResumen.mockRejectedValueOnce(new Error("fallo"));
    render(<TabEstadisticas />);

    expect(await screen.findByText(/Error al cargar estadísticas/i)).toBeInTheDocument();
  });
});