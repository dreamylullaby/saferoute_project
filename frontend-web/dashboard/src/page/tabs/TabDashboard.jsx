import React, { useState, useEffect } from "react";
import ChartDataLabels from "chartjs-plugin-datalabels";
import { Chart as ChartJS, CategoryScale, LinearScale, PointElement, LineElement, BarElement, ArcElement, Tooltip, Legend, Filler } from "chart.js";
import { Line, Bar, Doughnut } from "react-chartjs-2";
import { getResumen } from "../../services/reportService.js";
import api from "../../services/api.js";
import CustomSelect from "../../components/CustomSelect.jsx";
import CustomDatePicker from "../../components/CustomDatePicker.jsx";

ChartJS.register(CategoryScale, LinearScale, PointElement, LineElement, BarElement, ArcElement, Tooltip, Legend, Filler, ChartDataLabels);

var CT = { atraco: "#B91C1C", raponazo: "#0891B2", fleteo: "#D946EF", cosquilleo: "#8A2BE2" };
var CF = { "06:00-11:59": "#FBBF24", "12:00-17:59": "#F97316", "18:00-23:59": "#BE185D", "00:00-05:59": "#D946EF" };
var NF = { "06:00-11:59": "Mañana (06:00-11:59)", "12:00-17:59": "Tarde (12:00-17:59)", "18:00-23:59": "Noche (18:00-23:59)", "00:00-05:59": "Madrugada (00:00-05:59)" };

function getNivelColor(v) { if (v === 0) return "#22C55E"; if (v <= 2) return "#FACC15"; if (v <= 5) return "#F97316"; return "#BE185D"; }
function cap(s) { return s ? s.charAt(0).toUpperCase() + s.slice(1) : ""; }

function agruparSemana(pf) { var s = {}; Object.entries(pf).forEach(function (e) { var d = new Date(e[0] + "T00:00:00"); var i = new Date(d); i.setDate(d.getDate() - d.getDay()); var k = i.toISOString().split("T")[0]; s[k] = (s[k] || 0) + e[1]; }); return s; }
function agruparMes(pf) { var m = {}; Object.entries(pf).forEach(function (e) { var k = e[0].substring(0, 7); m[k] = (m[k] || 0) + e[1]; }); return m; }

function getResumenZona(zonaTipo) {
  return api.get("/api/reportes/admin/resumen", { params: { zona_tipo: zonaTipo } }).then(function (r) { return r.data.data; });
}

function filtrarDatos(resumen, desde, hasta, comuna, tipo, franja, corregimiento, zonaTipo, setFiltrado, setCargFiltro) {
  if (!desde && !hasta && !comuna && !tipo && !franja && !corregimiento) { setFiltrado(null); return; }
  setCargFiltro(true);
  import("../../services/reportService.js").then(function (mod) {
    var params = { page: 1, limit: 500 };
    if (tipo) params.tipo_hurto = tipo;
    if (comuna) params.comuna = comuna;
    if (desde) params.fechaDesde = desde;
    if (hasta) params.fechaHasta = hasta;
    if (corregimiento) params.corregimiento_id = corregimiento;
    if (zonaTipo) params.zona_tipo = zonaTipo;
    mod.getReportesAdmin(params).then(function (res) {
      var data = res.data || [];
      if (franja) { data = data.filter(function (r) { return r.franja_horaria === franja; }); }
      var r = { total: data.length, porTipo: {}, porEstado: {}, porComuna: {}, porFranja: {}, porFecha: {}, porCorregimiento: {} };
      data.forEach(function (rep) {
        if (rep.tipo_hurto) r.porTipo[rep.tipo_hurto] = (r.porTipo[rep.tipo_hurto] || 0) + 1;
        if (rep.estado) r.porEstado[rep.estado] = (r.porEstado[rep.estado] || 0) + 1;
        if (rep.comuna) r.porComuna[rep.comuna] = (r.porComuna[rep.comuna] || 0) + 1;
        if (rep.franja_horaria) r.porFranja[rep.franja_horaria] = (r.porFranja[rep.franja_horaria] || 0) + 1;
        if (rep.fecha_incidente) r.porFecha[rep.fecha_incidente] = (r.porFecha[rep.fecha_incidente] || 0) + 1;
        if (rep.corregimiento_nombre) r.porCorregimiento[rep.corregimiento_nombre] = (r.porCorregimiento[rep.corregimiento_nombre] || 0) + 1;
      });
      setFiltrado(r);
    }).catch(console.error).finally(function () { setCargFiltro(false); });
  });
}

function TabDashboard() {
  var [resumen, setResumen] = useState(null);
  var [resumenZona, setResumenZona] = useState(null);
  var [cargando, setCargando] = useState(true);
  var [agrupacion, setAgrupacion] = useState("semana");
  var [fDesde, setFDesde] = useState("");
  var [fHasta, setFHasta] = useState("");
  var [fComuna, setFComuna] = useState("");
  var [fCorregimiento, setFCorregimiento] = useState("");
  var [fTipo, setFTipo] = useState("");
  var [fFranja, setFFranja] = useState("");
  var [filtrado, setFiltrado] = useState(null);
  var [cargFiltro, setCargFiltro] = useState(false);
  var [modoRural, setModoRural] = useState(false);
  var [corregimientos, setCorregimientos] = useState([]);
  var [topBarrios, setTopBarrios] = useState([]);

  useEffect(function () {
    getResumen().then(setResumen).catch(console.error).finally(function () { setCargando(false); });
    api.get("/api/reportes/corregimientos").then(function (r) { setCorregimientos(r.data.data || []); }).catch(function () {});
    api.get("/api/reportes/zonas/top", { params: { top: 5 } }).then(function (r) { setTopBarrios(r.data.data || []); }).catch(function () {});
  }, []);

  // Recargar datos de gráficas al cambiar el chip urbano/rural
  useEffect(function () {
    var cancelled = false;
    setResumenZona(null);
    var zona = modoRural ? "rural" : "urbana";
    getResumenZona(zona).then(function (data) { if (!cancelled) setResumenZona(data); }).catch(console.error);
    return function () { cancelled = true; };
  }, [modoRural]);

  if (cargando) return React.createElement("p", { style: { color: "#64748b", textAlign: "center", padding: 60, fontWeight: 300 } }, "Cargando dashboard...");
  if (!resumen) return React.createElement("p", { style: { color: "#64748b", textAlign: "center" } }, "Error al cargar datos");

  // KPIs siempre globales
  var globalTotal = resumen.total || 0;
  var globalTipo = resumen.porTipo || {};
  var globalComuna = resumen.porComuna || {};
  var globalCorregimiento = resumen.porCorregimiento || {};
  var gTipoE = Object.entries(globalTipo).sort(function (a, b) { return b[1] - a[1]; });
  var gTMax = gTipoE[0];
  var gComunaE = Object.entries(globalComuna).sort(function (a, b) { return b[1] - a[1]; });
  var gCMax = gComunaE[0];
  var gCorrE = Object.entries(globalCorregimiento).sort(function (a, b) { return b[1] - a[1]; });
  var gCorrMax = gCorrE[0];

  // Gráficas: usan datos filtrados por zona (o filtrado manual si se aplicó)
  // Si resumenZona es null (cargando), mostrar datos vacíos para evitar flash
  var datosVacios = { total: 0, porTipo: {}, porEstado: {}, porComuna: {}, porFranja: {}, porFecha: {}, porCorregimiento: {} };
  var d = filtrado || resumenZona || datosVacios;
  var total = d.total || 0;
  var porTipo = d.porTipo || {};
  var porComuna = d.porComuna || {};
  var porFranja = d.porFranja || {};
  var porFecha = d.porFecha || {};
  var totalTipos = Object.values(porTipo).reduce(function (a, b) { return a + b; }, 0);

  var cE = Object.entries(porComuna).sort(function (a, b) { return b[1] - a[1]; });
  var cMax = cE[0];
  var tE = Object.entries(porTipo).sort(function (a, b) { return b[1] - a[1]; });
  var tMax = tE[0];
  var franjaEntries = Object.entries(porFranja).sort(function (a, b) { return b[1] - a[1]; });
  var franjaMax = franjaEntries[0];

  var porCorregimiento = d.porCorregimiento || {};
  var corrE = Object.entries(porCorregimiento).sort(function (a, b) { return b[1] - a[1]; });
  var corrMax = corrE[0];

  // Barras por comuna
  var cLabels = [], cValues = [], cColors = [], mx = 0;
  for (var i = 1; i <= 12; i++) { var v = porComuna[String(i)] || porComuna[i] || 0; cLabels.push("C" + i); cValues.push(v); if (v > mx) mx = v; }
  cValues.forEach(function (v) { cColors.push(getNivelColor(v)); });
  var comunasCon = cValues.filter(function (v) { return v > 0; }).length;

  // Barras por corregimiento
  var corrLabels = corregimientos.map(function (c) { return c.nombre.length > 8 ? c.nombre.substring(0, 8) + "." : c.nombre; });
  var corrValues = corregimientos.map(function (c) { return porCorregimiento[c.nombre] || 0; });
  var corrMx = Math.max.apply(null, corrValues.length ? corrValues : [0]);
  var corrColors = corrValues.map(function (v) { return getNivelColor(v); });
  var corrCon = corrValues.filter(function (v) { return v > 0; }).length;

  // Top 5 corregimientos
  var topCorregimientos = corrE.slice(0, 5);

  var ag = agrupacion === "mes" ? agruparMes(porFecha) : agrupacion === "todo" ? porFecha : agruparSemana(porFecha);
  var fE = Object.entries(ag).sort(function (a, b) { return a[0].localeCompare(b[0]); });
  var fLabels = fE.map(function (e) { var dd = new Date(e[0] + "T00:00:00"); return agrupacion === "mes" ? dd.toLocaleDateString("es-CO", { month: "short", year: "2-digit" }) : dd.toLocaleDateString("es-CO", { day: "2-digit", month: "short" }); });
  var fValues = fE.map(function (e) { return e[1]; });
  var fMax = Math.max.apply(null, fValues.length ? fValues : [1]);
  var fMin = Math.min.apply(null, fValues.length ? fValues : [0]);

  var tendMsg = "";
  var picoIdx = 0;
  for (var pi = 1; pi < fValues.length; pi++) { if (fValues[pi] > fValues[picoIdx]) picoIdx = pi; }
  var picoMsg = fValues.length > 0 ? "Pico más alto: " + fValues[picoIdx] + " reportes (" + fLabels[picoIdx] + ")." : "";
  if (fValues.length >= 2) {
    var last = fValues[fValues.length - 1]; var prev = fValues[fValues.length - 2];
    if (last > prev) tendMsg = "Tendencia al alza: el último período registró " + last + " reportes vs " + prev + " del anterior. " + picoMsg;
    else if (last < prev) tendMsg = "Tendencia a la baja: el último período bajó a " + last + " reportes desde " + prev + ". " + picoMsg;
    else tendMsg = "Sin variación: ambos períodos registraron " + last + " reportes. " + picoMsg;
  } else if (picoMsg) { tendMsg = picoMsg; }

  function aplicar() { filtrarDatos(resumen, fDesde, fHasta, modoRural ? "" : fComuna, fTipo, fFranja, modoRural ? fCorregimiento : "", modoRural ? "rural" : "urbana", setFiltrado, setCargFiltro); }
  function limpiar() { setFDesde(""); setFHasta(""); setFComuna(""); setFCorregimiento(""); setFTipo(""); setFFranja(""); setFiltrado(null); }
  function toggleModo(rural) { if (rural === modoRural) return; setResumenZona(null); setModoRural(rural); setFComuna(""); setFCorregimiento(""); setFiltrado(null); }

  return (
    <div style={{ display: "flex", flexDirection: "column", gap: 20 }}>
      <style>{`@keyframes fadeIn { from { opacity: 0; transform: translateY(6px); } to { opacity: 1; transform: translateY(0); } }`}</style>
      {/* KPIs */}
      <div style={{ display: "grid", gridTemplateColumns: "repeat(4, 1fr)", gap: 16 }}>
        <Kpi icon={<svg width="22" height="22" viewBox="0 0 24 24" fill="none" stroke="#2563EB" strokeWidth="2"><path d="M14 2H6a2 2 0 0 0-2 2v16a2 2 0 0 0 2 2h12a2 2 0 0 0 2-2V8z"/><polyline points="14 2 14 8 20 8"/><line x1="16" y1="13" x2="8" y2="13"/><line x1="16" y1="17" x2="8" y2="17"/></svg>} color="#2563EB" value={globalTotal} label="Total Reportes" />
        <Kpi icon={<svg width="22" height="22" viewBox="0 0 24 24" fill="none" stroke={gTMax ? CT[gTMax[0]] || "#64748B" : "#64748B"} strokeWidth="2"><path d="M10.29 3.86L1.82 18a2 2 0 0 0 1.71 3h16.94a2 2 0 0 0 1.71-3L13.71 3.86a2 2 0 0 0-3.42 0z"/><line x1="12" y1="9" x2="12" y2="13"/><line x1="12" y1="17" x2="12.01" y2="17"/></svg>} color={gTMax ? CT[gTMax[0]] || "#64748B" : "#64748B"} value={gTMax ? cap(gTMax[0]) : "—"} label={"Tipo más frecuente (" + (gTMax ? gTMax[1] : 0) + ")"} />
        <Kpi icon={<svg width="22" height="22" viewBox="0 0 24 24" fill="none" stroke={gCMax ? getNivelColor(gCMax[1]) : "#64748B"} strokeWidth="2"><path d="M21 10c0 7-9 13-9 13s-9-6-9-13a9 9 0 0 1 18 0z"/><circle cx="12" cy="10" r="3"/></svg>} color={gCMax ? getNivelColor(gCMax[1]) : "#64748B"} value={gCMax ? "Comuna " + gCMax[0] : "—"} label={"Comuna más afectada (" + (gCMax ? gCMax[1] : 0) + ")"} />
        <Kpi icon={<svg width="22" height="22" viewBox="0 0 24 24" fill="none" stroke="#16A34A" strokeWidth="2"><path d="M12 22s8-4 8-10V5l-8-3-8 3v7c0 6 8 10 8 10z"/></svg>} color="#16A34A" value={gCorrMax ? gCorrMax[0] : "—"} label={"Corregimiento más afectado (" + (gCorrMax ? gCorrMax[1] : 0) + ")"} />
      </div>

      {/* Filtros */}
      <div style={CARD}>
        <div style={{ display: "flex", gap: 12, alignItems: "flex-end", flexWrap: "wrap" }}>
          {/* Toggle Urbano/Rural — chip deslizante */}
          <div style={{ display: "flex", flexDirection: "column", gap: 4, minWidth: 170 }}>
            <label style={{ fontSize: 11, color: "#64748B", fontWeight: 300 }}>Zona</label>
            <div style={{ display: "flex", background: "#F1F5F9", borderRadius: 8, padding: 3, height: 38, boxSizing: "border-box", position: "relative", overflow: "hidden" }}>
              {/* Indicador deslizante */}
              <div style={{ position: "absolute", top: 3, left: modoRural ? "50%" : 3, width: "calc(50% - 3px)", height: "calc(100% - 6px)", borderRadius: 6, backgroundColor: modoRural ? "#16A34A" : "#2563EB", transition: "left 0.3s cubic-bezier(0.4, 0, 0.2, 1), background-color 0.3s ease", zIndex: 0 }} />
              <button type="button" onClick={function () { toggleModo(false); }} style={{ ...TOGGLE_BTN, color: modoRural ? "#64748B" : "#fff", position: "relative", zIndex: 1 }}>
                <svg width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2"><path d="M3 21h18"/><path d="M5 21V7l8-4v18"/><path d="M19 21V11l-6-4"/></svg>
                <span>Urbano</span>
              </button>
              <button type="button" onClick={function () { toggleModo(true); }} style={{ ...TOGGLE_BTN, color: modoRural ? "#fff" : "#64748B", position: "relative", zIndex: 1 }}>
                <svg width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2"><path d="M12 22c-4 0-7-2-7-5 0-2 1-3 2-4l5-6 5 6c1 1 2 2 2 4 0 3-3 5-7 5z"/><path d="M12 22v-6"/></svg>
                <span>Rural</span>
              </button>
            </div>
          </div>
          <Fld label="Desde"><CustomDatePicker value={fDesde} onChange={function (v) { setFDesde(v); }} placeholder="Desde" maxDate={fHasta || undefined} /></Fld>
          <Fld label="Hasta"><CustomDatePicker value={fHasta} onChange={function (v) { setFHasta(v); }} placeholder="Hasta" minDate={fDesde || undefined} /></Fld>
          {!modoRural ? (
            <Fld label="Comuna"><CustomSelect value={fComuna} onChange={function (v) { setFComuna(v); }} placeholder="Todas" options={[{ label: "Todas", value: "" }].concat(Array.from({ length: 12 }, function (_, i) { return { label: "C" + (i + 1), value: String(i + 1) }; }))} /></Fld>
          ) : (
            <Fld label="Corregimiento" minW={180}><CustomSelect value={fCorregimiento} onChange={function (v) { setFCorregimiento(v); }} placeholder={corregimientos.length === 0 ? "Sin datos" : "Todos"} options={[{ label: "Todos", value: "" }].concat(corregimientos.map(function (c) { return { label: c.nombre, value: String(c.id) }; }))} /></Fld>
          )}
          <Fld label="Tipo"><CustomSelect value={fTipo} onChange={function (v) { setFTipo(v); }} placeholder="Todos" options={[{ label: "Todos", value: "" }, { label: "Atraco", value: "atraco" }, { label: "Raponazo", value: "raponazo" }, { label: "Fleteo", value: "fleteo" }, { label: "Cosquilleo", value: "cosquilleo" }]} /></Fld>
          <Fld label="Franja"><CustomSelect value={fFranja} onChange={function (v) { setFFranja(v); }} placeholder="Todas" options={[{ label: "Todas", value: "" }, { label: "00:00-05:59", value: "00:00-05:59" }, { label: "06:00-11:59", value: "06:00-11:59" }, { label: "12:00-17:59", value: "12:00-17:59" }, { label: "18:00-23:59", value: "18:00-23:59" }]} /></Fld>
          <button onClick={aplicar} style={BTN_P}>Aplicar</button>
          <button onClick={limpiar} style={BTN_S}>Limpiar</button>
        </div>
      </div>
      <p style={{ margin: 0, fontSize: 12, color: "#64748B", fontWeight: 300 }}>{"Mostrando datos " + (modoRural ? "rurales" : "urbanos") + (fDesde || fHasta ? " del " + (fDesde || "inicio") + " al " + (fHasta || "hoy") : "") + " — " + total + " reportes"}</p>
      <div style={{ display: "flex", alignItems: "flex-start", gap: 8, padding: "10px 14px", backgroundColor: "#EFF6FF", borderRadius: 8, border: "1px solid #BFDBFE" }}>
        <svg width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="#2563EB" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round" style={{ flexShrink: 0, marginTop: 1 }}><circle cx="12" cy="12" r="10"/><line x1="12" y1="16" x2="12" y2="12"/><line x1="12" y1="8" x2="12.01" y2="8"/></svg>
        <span style={{ fontSize: 12, color: "#1E40AF", fontWeight: 400, lineHeight: 1.5 }}>Las tarjetas superiores muestran datos globales (urbano + rural). Todas las gráficas se filtran según la zona seleccionada ({modoRural ? "Rural" : "Urbano"}). Los filtros adicionales (fecha, tipo, franja) se aplican sobre la zona activa.</span>
      </div>

      {/* Donut + Barras (cambia según modo) */}
      <div style={{ display: "grid", gridTemplateColumns: "1fr 1fr", gap: 16 }}>
        <div style={{ ...CARD, padding: 20, maxHeight: 380, display: "flex", flexDirection: "column" }}>
          <h3 style={CT_T}>Distribución por Tipo de Hurto</h3>
          <div style={{ position: "relative", maxWidth: 260, margin: "0 auto", flex: 1, display: "flex", alignItems: "center" }}>
            <Doughnut data={{ labels: Object.keys(porTipo).map(cap), datasets: [{ data: Object.values(porTipo), backgroundColor: Object.keys(porTipo).map(function (t) { return CT[t] || "#64748B"; }), borderWidth: 0, cutout: "68%" }] }} options={{ responsive: true, plugins: { legend: { display: false }, datalabels: { display: true, color: "#fff", font: { size: 13, weight: 700 }, formatter: function (value) { return value > 0 ? value : ""; } } } }} />
            <div style={{ position: "absolute", top: "50%", left: "50%", transform: "translate(-50%,-50%)", textAlign: "center" }}>
              <div style={{ fontSize: 26, fontWeight: 600, color: "#1E293B" }}>{totalTipos || ""}</div>
              <div style={{ fontSize: 11, color: "#64748B", fontWeight: 300 }}>{totalTipos ? "Total" : ""}</div>
            </div>
          </div>
          <div style={{ display: "flex", justifyContent: "center", gap: 16, marginTop: 14, flexWrap: "wrap" }}>
            {Object.entries(porTipo).map(function (e) { return (<div key={e[0]} style={{ display: "flex", alignItems: "center", gap: 5 }}><div style={{ width: 8, height: 8, borderRadius: "50%", backgroundColor: CT[e[0]] || "#64748B" }} /><span style={{ fontSize: 13, color: "#1E293B" }}>{cap(e[0])}</span><span style={{ fontSize: 13, fontWeight: 700, color: CT[e[0]] || "#1E293B" }}>{e[1]}</span></div>); })}
          </div>
        </div>

        {/* Barras: Comuna (urbano) o Corregimiento (rural) */}
        <div style={{ ...CARD, padding: 20, maxHeight: 380, display: "flex", flexDirection: "column" }}>
          <h3 style={CT_T}>{modoRural ? "Incidentes por Corregimiento" : "Incidentes por Comuna"}</h3>
          <p style={{ margin: "-8px 0 12px", fontSize: 12, color: "#64748B", fontWeight: 300 }}>
            {modoRural
              ? (corrCon + " de " + corregimientos.length + " corregimientos con incidentes" + (corrMax ? ". Mayor: " + corrMax[0] + " (" + corrMax[1] + ")" : ""))
              : (comunasCon + " de 12 comunas con incidentes" + (cMax ? ". Mayor: C" + cMax[0] + " (" + cMax[1] + ")" : ""))
            }
          </p>
          <div style={{ flex: 1 }}>
            <Bar
              data={{ labels: modoRural ? corrLabels : cLabels, datasets: [{ label: "Incidentes", data: modoRural ? corrValues : cValues, backgroundColor: modoRural ? corrColors : cColors, borderRadius: 4, borderSkipped: false, barPercentage: 0.7, categoryPercentage: 0.8 }] }}
              options={{ responsive: true, maintainAspectRatio: false, layout: { padding: { top: 20 } }, plugins: { legend: { display: false }, tooltip: { enabled: true }, datalabels: { anchor: "end", align: "top", font: { size: 11, weight: 600 }, color: "#1E293B", display: function (ctx) { return ctx.dataset.data[ctx.dataIndex] > 0; } } }, scales: { y: { display: false }, x: { ticks: { font: { size: modoRural ? 9 : 11 }, maxRotation: modoRural ? 45 : 0 }, grid: { display: false } } } }}
            />
          </div>
          <div style={{ display: "flex", justifyContent: "center", gap: 14, marginTop: 10, flexWrap: "wrap" }}>
            <div style={{ display: "flex", alignItems: "center", gap: 5 }}><div style={{ width: 10, height: 10, borderRadius: 2, backgroundColor: "#22C55E" }} /><span style={{ fontSize: 11, color: "#64748B" }}>Seguro</span></div>
            <div style={{ display: "flex", alignItems: "center", gap: 5 }}><div style={{ width: 10, height: 10, borderRadius: 2, backgroundColor: "#FACC15" }} /><span style={{ fontSize: 11, color: "#64748B" }}>Bajo riesgo</span></div>
            <div style={{ display: "flex", alignItems: "center", gap: 5 }}><div style={{ width: 10, height: 10, borderRadius: 2, backgroundColor: "#F97316" }} /><span style={{ fontSize: 11, color: "#64748B" }}>Riesgo medio</span></div>
            <div style={{ display: "flex", alignItems: "center", gap: 5 }}><div style={{ width: 10, height: 10, borderRadius: 2, backgroundColor: "#BE185D" }} /><span style={{ fontSize: 11, color: "#64748B" }}>Alto riesgo</span></div>
          </div>
        </div>
      </div>

      {/* Tendencia */}
      <div style={CARD}>
        <div style={{ display: "flex", justifyContent: "space-between", alignItems: "center", marginBottom: 8 }}>
          <h3 style={{ ...CT_T, marginBottom: 0 }}>Tendencia de Reportes</h3>
          <div style={{ display: "flex", gap: 4 }}>{["semana", "mes", "todo"].map(function (op) { var a = agrupacion === op; return <button key={op} onClick={function () { setAgrupacion(op); }} style={{ padding: "6px 14px", borderRadius: 6, border: a ? "none" : "1px solid #CBD5E1", backgroundColor: a ? "#2563EB" : "transparent", color: a ? "#fff" : "#64748B", fontSize: 12, cursor: "pointer", fontWeight: a ? 600 : 400 }}>{cap(op)}</button>; })}</div>
        </div>
        {tendMsg && <p style={{ margin: "0 0 12px", fontSize: 12, color: "#64748B", fontWeight: 300 }}>{tendMsg}</p>}
        <div style={{ maxHeight: 280, width: "100%" }}>
          <Line data={{ labels: fLabels, datasets: [{ label: "Reportes", data: fValues, borderColor: "#2563EB", backgroundColor: "rgba(37,99,235,0.1)", fill: true, tension: 0.4, pointBackgroundColor: "#2563EB", pointRadius: 4 }] }} options={{ responsive: true, maintainAspectRatio: false, plugins: { legend: { display: false }, datalabels: { display: false } }, scales: { y: { min: Math.max(0, fMin - 1), max: fMax + Math.ceil(fMax * 0.2) || 5, ticks: { stepSize: 1, font: { size: 11 } }, grid: { color: "#F1F5F9" } }, x: { ticks: { font: { size: 10 }, maxRotation: 45 }, grid: { display: false } } } }} />
        </div>
      </div>

      {/* Franja + Top 5 (Barrios o Corregimientos según modo) */}
      <div style={{ display: "grid", gridTemplateColumns: "1fr 1fr", gap: 16 }}>
        <div style={{ ...CARD, padding: 20, maxHeight: 380, display: "flex", flexDirection: "column" }}>
          <h3 style={{ ...CT_T, marginBottom: 4 }}>Por Franja Horaria</h3>
          {franjaMax && <p style={{ margin: "0 0 12px", fontSize: 12, color: "#64748B", fontWeight: 300 }}>{"La franja " + (NF[franjaMax[0]] || franjaMax[0]) + " concentra el mayor número de incidentes (" + franjaMax[1] + ")"}</p>}
          <div style={{ maxWidth: 260, margin: "0 auto", flex: 1, display: "flex", alignItems: "center" }}>
            <Doughnut data={{ labels: Object.keys(porFranja).map(function (f) { return NF[f] || f; }), datasets: [{ data: Object.values(porFranja), backgroundColor: Object.keys(porFranja).map(function (f) { return CF[f] || "#64748B"; }), borderWidth: 0, cutout: "60%" }] }} options={{ responsive: true, plugins: { legend: { display: false }, datalabels: { display: true, color: "#fff", font: { size: 13, weight: 700 }, formatter: function (value) { return value > 0 ? value : ""; } } } }} />
          </div>
          <div style={{ display: "flex", justifyContent: "center", gap: 14, marginTop: 14, flexWrap: "wrap" }}>
            {Object.entries(porFranja).map(function (e) { return (<div key={e[0]} style={{ display: "flex", alignItems: "center", gap: 5 }}><div style={{ width: 8, height: 8, borderRadius: "50%", backgroundColor: CF[e[0]] || "#64748B" }} /><span style={{ fontSize: 13, color: "#1E293B" }}>{NF[e[0]] || e[0]}</span><span style={{ fontSize: 13, fontWeight: 700, color: CF[e[0]] || "#1E293B" }}>{e[1]}</span></div>); })}
          </div>
        </div>

        {/* Top 5 — cambia según modo */}
        <div style={{ ...CARD, padding: 20, maxHeight: 380, display: "flex", flexDirection: "column" }}>
          <h3 style={{ ...CT_T, marginBottom: 8 }}>{modoRural ? "Top 5 Corregimientos" : "Top 5 Barrios"}</h3>
          {(() => {
            var items = modoRural ? topCorregimientos : topBarrios;
            var loading = !resumenZona && !filtrado;
            if (loading) return (
              <div style={{ flex: 1, display: "flex", alignItems: "center", justifyContent: "center", opacity: 0.5, transition: "opacity 0.3s ease" }}>
                <p style={{ margin: 0, fontSize: 13, color: "#64748B", fontWeight: 300 }}>Cargando...</p>
              </div>
            );
            if (!items || items.length === 0) return (
              <div style={{ flex: 1, display: "flex", flexDirection: "column", alignItems: "center", justifyContent: "center" }}>
                <svg width="40" height="40" viewBox="0 0 24 24" fill="none" stroke="#CBD5E1" strokeWidth="1.5"><path d="M21 10c0 7-9 13-9 13s-9-6-9-13a9 9 0 0 1 18 0z"/><circle cx="12" cy="10" r="3"/></svg>
                <p style={{ margin: "8px 0 0", fontSize: 13, color: "#64748B" }}>Sin datos disponibles</p>
              </div>
            );
            var maxT = items[0].total || items[0][1] || 1;
            return (
              <div style={{ flex: 1, display: "flex", flexDirection: "column", gap: 10, justifyContent: "flex-start", paddingTop: 4, animation: "fadeIn 0.4s ease" }}>
                {items.map(function (z, idx) {
                  var nombre = z.barrio || z[0] || "—";
                  var cantidad = z.total || z[1] || 0;
                  var pct = maxT > 0 ? (cantidad / maxT) * 100 : 0;
                  var barColor = idx === 0 ? "#B91C1C" : idx === 1 ? "#F97316" : idx === 2 ? "#FACC15" : "#3B82F6";
                  return (
                    <div key={idx} style={{ display: "flex", alignItems: "center", gap: 10 }}>
                      <span style={{ width: 22, height: 22, borderRadius: "50%", backgroundColor: barColor, color: "#fff", fontSize: 11, fontWeight: 700, display: "flex", alignItems: "center", justifyContent: "center", flexShrink: 0 }}>{idx + 1}</span>
                      <div style={{ flex: 1 }}>
                        <div style={{ display: "flex", justifyContent: "space-between", marginBottom: 3 }}>
                          <span style={{ fontSize: 13, fontWeight: 500, color: "#1E293B" }}>{nombre}</span>
                          <span style={{ fontSize: 14, fontWeight: 700, color: barColor }}>{cantidad}</span>
                        </div>
                        <div style={{ height: 10, borderRadius: 5, backgroundColor: "#F1F5F9", overflow: "hidden" }}>
                          <div style={{ height: "100%", width: pct + "%", backgroundColor: barColor, borderRadius: 5, transition: "width 0.4s ease" }} />
                        </div>
                      </div>
                    </div>
                  );
                })}
              </div>
            );
          })()}
        </div>
      </div>
    </div>
  );
}

function Kpi(p) { return (<div style={CARD}><div style={{ display: "flex", alignItems: "center", gap: 14 }}><div style={{ width: 48, height: 48, borderRadius: "50%", backgroundColor: p.color + "26", display: "flex", alignItems: "center", justifyContent: "center" }}>{p.icon}</div><div><div style={{ fontSize: 28, fontWeight: 600, color: "#1E293B", lineHeight: 1 }}>{p.value}</div><div style={{ fontSize: 12, color: "#64748B", fontWeight: 300, marginTop: 2 }}>{p.label}</div></div></div></div>); }
function Fld(p) { return (<div style={{ display: "flex", flexDirection: "column", gap: 4, flex: 1, minWidth: p.minW || 120 }}><label style={{ fontSize: 11, color: "#64748B", fontWeight: 300 }}>{p.label}</label>{p.children}</div>); }

export default TabDashboard;

var CARD = { backgroundColor: "#fff", borderRadius: 12, padding: 24, border: "0.5px solid #CBD5E1", boxShadow: "0 1px 4px rgba(0,0,0,0.06)" };
var CT_T = { margin: "0 0 16px", fontSize: 15, fontWeight: 600, color: "#1E293B" };
var INP = { height: 38, padding: "0 12px", borderRadius: 10, border: "1px solid #E2E8F0", fontSize: 13, color: "#1E293B", fontFamily: "'Inter',sans-serif", backgroundColor: "#F8FAFC", boxSizing: "border-box", width: "100%", transition: "border-color 0.2s ease" };
var BTN_P = { padding: "10px 20px", borderRadius: 8, border: "none", backgroundColor: "#2563EB", color: "#fff", fontFamily: "'Montserrat',sans-serif", fontWeight: 500, fontSize: 13, cursor: "pointer" };
var BTN_S = { padding: "10px 20px", borderRadius: 8, border: "1px solid #CBD5E1", backgroundColor: "transparent", color: "#64748B", fontSize: 13, cursor: "pointer" };
var TOGGLE_BTN = { display: "flex", alignItems: "center", gap: 5, padding: "0 14px", border: "none", borderRadius: 6, fontSize: 13, fontFamily: "'Inter',sans-serif", fontWeight: 500, cursor: "pointer", height: "100%", backgroundColor: "transparent", transition: "color 0.25s ease", flex: 1, justifyContent: "center" };
