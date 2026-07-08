import { render, screen, waitFor, within } from "@testing-library/react";
import userEvent from "@testing-library/user-event";
import "@testing-library/jest-dom";
import { describe, test, expect, beforeEach, vi } from "vitest";
import RankingZonas from "../../page/RankingZonas.jsx";

const mocks = vi.hoisted(() => ({
  getRankingZonas: vi.fn(),
}));

vi.mock("../../services/reportService.js", () => ({
  getRankingZonas: mocks.getRankingZonas,
}));

const ok = (msg) => console.log(`✅ PASS: ${msg}`);

describe("HU-12 Integral Frontend - Ranking de zonas con más hurtos", () => {
  const rankingMes = [
    {
      zona: "Centro",
      total_hurtos: 10,
      porcentaje: 50,
    },
    {
      zona: "San Vicente",
      total_hurtos: 6,
      porcentaje: 30,
    },
    {
      zona: "La Rosa",
      total_hurtos: 4,
      porcentaje: 20,
    },
  ];

  const rankingAnio = [
    {
      zona: "San Vicente",
      total_hurtos: 15,
      porcentaje: 50,
    },
    {
      zona: "Centro",
      total_hurtos: 10,
      porcentaje: 33.3,
    },
    {
      zona: "La Rosa",
      total_hurtos: 5,
      porcentaje: 16.7,
    },
  ];

  const rankingAscendente = [
    {
      zona: "La Rosa",
      total_hurtos: 4,
      porcentaje: 20,
    },
    {
      zona: "San Vicente",
      total_hurtos: 6,
      porcentaje: 30,
    },
    {
      zona: "Centro",
      total_hurtos: 10,
      porcentaje: 50,
    },
  ];

  const rankingAlfabetico = [
    {
      zona: "Centro",
      total_hurtos: 10,
      porcentaje: 50,
    },
    {
      zona: "La Rosa",
      total_hurtos: 4,
      porcentaje: 20,
    },
    {
      zona: "San Vicente",
      total_hurtos: 6,
      porcentaje: 30,
    },
  ];

  beforeEach(() => {
    vi.clearAllMocks();
  });

  test("PI-HU12-01 consulta inicial de zonas con más hurtos", async () => {
    mocks.getRankingZonas.mockResolvedValue({
      data: rankingMes,
    });

    render(<RankingZonas />);

    await waitFor(() => {
      expect(mocks.getRankingZonas).toHaveBeenCalled();
      expect(screen.getByText("Centro")).toBeInTheDocument();
      expect(screen.getByText("San Vicente")).toBeInTheDocument();
      expect(screen.getByText("La Rosa")).toBeInTheDocument();
    });

    const rows = screen.getAllByTestId("ranking-row");
    expect(within(rows[0]).getByText("Centro")).toBeInTheDocument();
    expect(within(rows[1]).getByText("San Vicente")).toBeInTheDocument();
    expect(within(rows[2]).getByText("La Rosa")).toBeInTheDocument();

    ok("PI-HU12-01 consulta inicial de zonas con más hurtos");
  });

  test("PI-HU12-02 visualización completa de datos por zona", async () => {
    mocks.getRankingZonas.mockResolvedValue({
      data: rankingMes,
    });

    render(<RankingZonas />);

    await waitFor(() => {
      expect(screen.getByText("Centro")).toBeInTheDocument();
      expect(screen.getByText("10")).toBeInTheDocument();
      expect(screen.getByText("50%")).toBeInTheDocument();
    });

    const rows = screen.getAllByTestId("ranking-row");
    expect(within(rows[0]).getByText("Centro")).toBeInTheDocument();
    expect(within(rows[0]).getByText("10")).toBeInTheDocument();
    expect(within(rows[0]).getByText("50%")).toBeInTheDocument();

    ok("PI-HU12-02 visualización completa de datos por zona");
  });

  test("PI-HU12-03 cambio de periodo recalcula y reordena lista", async () => {
    const user = userEvent.setup();

    mocks.getRankingZonas
      .mockResolvedValueOnce({ data: rankingMes })
      .mockResolvedValueOnce({ data: rankingAnio })
      .mockResolvedValue({ data: rankingAnio });

    render(<RankingZonas />);

    await waitFor(() => {
      expect(screen.getByText("Centro")).toBeInTheDocument();
    });

    await user.selectOptions(
      screen.getByRole("combobox", { name: /periodo/i }),
      "anio-actual"
    );

    await waitFor(() => {
      expect(mocks.getRankingZonas).toHaveBeenLastCalledWith("anio-actual");
    });

    const rows = screen.getAllByTestId("ranking-row");
    expect(within(rows[0]).getByText("San Vicente")).toBeInTheDocument();
    expect(within(rows[1]).getByText("Centro")).toBeInTheDocument();
    expect(within(rows[2]).getByText("La Rosa")).toBeInTheDocument();

    ok("PI-HU12-03 cambio de periodo recalcula y reordena lista");
  });

  test("PI-HU12-04 periodo sin reportes", async () => {
    mocks.getRankingZonas.mockResolvedValue({
      data: [],
    });

    render(<RankingZonas />);

    await waitFor(() => {
      expect(
        screen.getByText(/no hay datos disponibles para este periodo/i)
      ).toBeInTheDocument();
    });

    expect(screen.queryByRole("table")).not.toBeInTheDocument();

    ok("PI-HU12-04 periodo sin reportes");
  });

  test("PI-HU12-05 cambio de criterio de orden", async () => {
    const user = userEvent.setup();

    mocks.getRankingZonas.mockResolvedValue({
      data: rankingMes,
    });

    render(<RankingZonas />);

    await waitFor(() => {
      expect(screen.getByText("Centro")).toBeInTheDocument();
    });

    await user.selectOptions(
      screen.getByRole("combobox", { name: /orden/i }),
      "alfabetico"
    );

    let rows = screen.getAllByTestId("ranking-row");
    expect(within(rows[0]).getByText("Centro")).toBeInTheDocument();
    expect(within(rows[1]).getByText("La Rosa")).toBeInTheDocument();
    expect(within(rows[2]).getByText("San Vicente")).toBeInTheDocument();

    await user.selectOptions(
      screen.getByRole("combobox", { name: /orden/i }),
      "menor-mayor"
    );

    rows = screen.getAllByTestId("ranking-row");
    expect(within(rows[0]).getByText("La Rosa")).toBeInTheDocument();
    expect(within(rows[1]).getByText("San Vicente")).toBeInTheDocument();
    expect(within(rows[2]).getByText("Centro")).toBeInTheDocument();

    ok("PI-HU12-05 cambio de criterio de orden");
  });
});