import React, { useState, useEffect } from "react";
import { Chart as ChartJS, CategoryScale, LinearScale, PointElement, LineElement, BarElement, ArcElement, Tooltip, Legend, Filler } from "chart.js";
import { Line, Bar, Doughnut } from "react-chartjs-2";
import { getResumen } from "../../services/reportService.js";

ChartJS.register(CategoryScale, LinearScale, PointElement, LineElement, BarElement, ArcElement, Tooltip, Legend, Filler);

var CT = { atraco: "#B91C1C", raponazo: "#9D174D", fleteo: "#D946EF", cosquilleo: "#8A2BE2" };
var CF = { "06:00-11:59": "#FBBF24", "12:00-17:59": "#F97316", "18:00-23:59": "#BE185D", "00:00-05:59": "#D946EF" };
var NF = { "06:00-11:59": "Mañana (06:00-11:59)", "12:00-17:59": "Tarde (12:00-17:59)", "18:00-23:59": "Noche (18:00-23:59)", "00:00-05:59": "Madrugada (00:00-05:59)" };

function getNivelColor(v) { if (v === 0) return "#22C55E"; if (v <= 2) return "#FACC15"; if (v <= 5) return "#F97316"; return "#BE185D"; }
function cap(s) { return s ? s.charAt(0).toUpperCase() + s.slice(1) : ""; }

function agruparSemana(pf) { var s = {}; Object.entries(pf).forEach(function (e) { var d = new Date(e[0] + "T00:00:00"); var i = new Date(d); i.setDate(d.getDate() - d.getDay()); var k = i.toISOString().split("T")[0]; s[k] = (s[k] || 0) + e[1]; }); return s; }
function agruparMes(pf) { var m = {}; Object.entries(pf).forEach(function (e) { var k = e[0].substring(0, 7); m[k] = (m[k] || 0) + e[1]; }); return m; }

/* Client-side filter — rebuilds all aggregates from the admin endpoint */
function filtrarDatos(resumen, desde, hasta, comuna, tipo, franja, setFiltrado, setCargFiltro) {
  /* If no filters active, clear */
  if (!desde && !hasta && !comuna && !tipo && !franja) { setFiltrado(null); return; }

  setCargFiltro(true);
  /* Use the admin list endpoint with filters to get raw data */
  import("../../services/reportService.js").then(function (mod) {
    var params = { page: 1, limit: 500 };
    if (tipo) params.tipo_hurto = tipo;
    if (comuna) params.comuna = comuna;
    if (desde) params.fechaDesde = desde;
    if (hasta) params.fechaHasta = hasta;

    mod.getReportesAdmin(params).then(function (res) {
      var data = res.data || [];
      /* Apply franja filter client-side (not supported by endpoint) */
      if (franja) { data = data.filter(function (r) { return r.franja_horaria === franja; }); }

      var r = { total: data.length, porTipo: {}, porEstado: {}, porComuna: {}, porFranja: {}, porFecha: {} };
      data.forEach(function (rep) {
        if (rep.tipo_hurto) r.porTipo[rep.tipo_hurto] = (r.porTipo[rep.tipo_hurto] || 0) + 1;
        if (rep.estado) r.porEstado[rep.estado] = (r.porEstado[rep.estado] || 0) + 1;
        if (rep.comuna) r.porComuna[rep.comuna] = (r.porComuna[rep.comuna] || 0) + 1;
        if (rep.franja_horaria) r.porFranja[rep.franja_horaria] = (r.porFranja[rep.franja_horaria] || 0) + 1;
        if (rep.fecha_incidente) r.porFecha[rep.fecha_incidente] = (r.porFecha[rep.fecha_incidente] || 0) + 1;
      });
      setFiltrado(r);
    }).catch(console.error).finally(function () { setCargFiltro(false); });
  });
}

function TabDashboard() {
  var [resumen, setResumen] = useState(null);
  var [cargando, setCargando] = useState(true);
  var [agrupacion, setAgrupacion] = useState("semana");
  var [fDesde, setFDesde] = useState("");
  var [fHasta, setFHasta] = useState("");
  var [fComuna, setFComuna] = useState("");
  var [fTipo, setFTipo] = useState("");
  var [fFranja, setFFranja] = useState("");
  var [filtrado, setFiltrado] = useState(null);
  var [cargFiltro, setCargFiltro] = useState(false);

  useEffect(function () { getResumen().then(setResumen).catch(console.error).finally(function () { setCargando(false); }); }, []);

  if (cargando) return React.createElement("p", { style: { color: "#64748b", textAlign: "center", padding: 60, fontWeight: 300 } }, "Cargando dashboard...");
  if (!resumen) return React.createElement("p", { style: { color: "#64748b", textAlign: "center" } }, "Error al cargar datos");

  var d = filtrado || resumen;
  var total = d.total || 0;
  var porTipo = d.porTipo || {};
  var porEstado = d.porEstado || {};
  var porComuna = d.porComuna || {};
  var porFranja = d.porFranja || {};
  var porFecha = d.porFecha || {};
  var activos = porEstado.activo || 0;
  var totalTipos = Object.values(porTipo).reduce(function (a, b) { return a + b; }, 0) || 1;

  var cE = Object.entries(porComuna).sort(function (a, b) { return b[1] - a[1]; });
  var cMax = cE[0];
  var tE = Object.entries(porTipo).sort(function (a, b) { return b[1] - a[1]; });
  var tMax = tE[0];
  var franjaEntries = Object.entries(porFranja).sort(function (a, b) { return b[1] - a[1]; });
  var franjaMax = franjaEntries[0];

  var cLabels = [], cValues = [], cColors = [], mx = 0;
  for (var i = 1; i <= 12; i++) { var v = porComuna[String(i)] || porComuna[i] || 0; cLabels.push("C" + i); cValues.push(v); if (v > mx) mx = v; }
  cValues.forEach(function (v) { cColors.push(v === mx && mx > 0 ? "#B91C1C" : "#3B82F6"); });

  /* Comunas sin incidentes vs con */
  var comunasSin = cValues.filter(function (v) { return v === 0; }).length;
  var comunasCon = 12 - comunasSin;

  var ag = agrupacion === "mes" ? agruparMes(porFecha) : agrupacion === "todo" ? porFecha : agruparSemana(porFecha);
  var fE = Object.entries(ag).sort(function (a, b) { return a[0].localeCompare(b[0]); });
  var fLabels = fE.map(function (e) { var dd = new Date(e[0] + "T00:00:00"); return agrupacion === "mes" ? dd.toLocaleDateString("es-CO", { month: "short", year: "2-digit" }) : dd.toLocaleDateString("es-CO", { day: "2-digit", month: "short" }); });
  var fValues = fE.map(function (e) { return e[1]; });
  var fMax = Math.max.apply(null, fValues.length ? fValues : [1]);
  var fMin = Math.min.apply(null, fValues.length ? fValues : [0]);

  /* Tendencia insight */
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

  function aplicar() { filtrarDatos(resumen, fDesde, fHasta, fComuna, fTipo, fFranja, setFiltrado, setCargFiltro); }
  function limpiar() { setFDesde(""); setFHasta(""); setFComuna(""); setFTipo(""); setFFranja(""); setFiltrado(null); }

  return (
    <div style={{ display: "flex", flexDirection: "column", gap: 20 }}>
      {/* KPIs */}
      <div style={{ display: "grid", gridTemplateColumns: "repeat(4, 1fr)", gap: 16 }}>
        <Kpi icon={<svg width="22" height="22" viewBox="0 0 24 24" fill="none" stroke="#2563EB" strokeWidth="2"><path d="M14 2H6a2 2 0 0 0-2 2v16a2 2 0 0 0 2 2h12a2 2 0 0 0 2-2V8z"/><polyline points="14 2 14 8 20 8"/><line x1="16" y1="13" x2="8" y2="13"/><line x1="16" y1="17" x2="8" y2="17"/></svg>} color="#2563EB" value={total} label="Total Reportes" />
        <Kpi icon={<svg width="22" height="22" viewBox="0 0 24 24" fill="none" stroke="#10B981" strokeWidth="2"><path d="M22 11.08V12a10 10 0 1 1-5.93-9.14"/><polyline points="22 4 12 14.01 9 11.01"/></svg>} color="#10B981" value={activos} label="Reportes Activos" />
        <Kpi icon={<svg width="22" height="22" viewBox="0 0 24 24" fill="none" stroke={tMax ? CT[tMax[0]] || "#64748B" : "#64748B"} strokeWidth="2"><path d="M10.29 3.86L1.82 18a2 2 0 0 0 1.71 3h16.94a2 2 0 0 0 1.71-3L13.71 3.86a2 2 0 0 0-3.42 0z"/><line x1="12" y1="9" x2="12" y2="13"/><line x1="12" y1="17" x2="12.01" y2="17"/></svg>} color={tMax ? CT[tMax[0]] || "#64748B" : "#64748B"} value={tMax ? cap(tMax[0]) : "—"} label={"Tipo más frecuente (" + (tMax ? tMax[1] : 0) + ")"} />
        <Kpi icon={<svg width="22" height="22" viewBox="0 0 24 24" fill="none" stroke={cMax ? getNivelColor(cMax[1]) : "#64748B"} strokeWidth="2"><path d="M21 10c0 7-9 13-9 13s-9-6-9-13a9 9 0 0 1 18 0z"/><circle cx="12" cy="10" r="3"/></svg>} color={cMax ? getNivelColor(cMax[1]) : "#64748B"} value={cMax ? "Comuna " + cMax[0] : "—"} label={"Zona más afectada (" + (cMax ? cMax[1] : 0) + ")"} />
      </div>

      {/* Filtros */}
      <div style={CARD}>
        <div style={{ display: "flex", gap: 12, alignItems: "flex-end", flexWrap: "wrap" }}>
          <Fld label="Desde"><input type="date" value={fDesde} onChange={function (e) { setFDesde(e.target.value); }} style={INP} /></Fld>
          <Fld label="Hasta"><input type="date" value={fHasta} onChange={function (e) { setFHasta(e.target.value); }} style={INP} /></Fld>
          <Fld label="Comuna"><select value={fComuna} onChange={function (e) { setFComuna(e.target.value); }} style={INP}><option value="">Todas</option>{Array.from({ length: 12 }, function (_, i) { return <option key={i + 1} value={i + 1}>{"C" + (i + 1)}</option>; })}</select></Fld>
          <Fld label="Tipo"><select value={fTipo} onChange={function (e) { setFTipo(e.target.value); }} style={INP}><option value="">Todos</option><option value="atraco">Atraco</option><option value="raponazo">Raponazo</option><option value="fleteo">Fleteo</option><option value="cosquilleo">Cosquilleo</option></select></Fld>
          <Fld label="Franja"><select value={fFranja} onChange={function (e) { setFFranja(e.target.value); }} style={INP}><option value="">Todas</option><option value="00:00-05:59">00:00-05:59</option><option value="06:00-11:59">06:00-11:59</option><option value="12:00-17:59">12:00-17:59</option><option value="18:00-23:59">18:00-23:59</option></select></Fld>
          <button onClick={aplicar} style={BTN_P}>Aplicar</button>
          <button onClick={limpiar} style={BTN_S}>Limpiar</button>
        </div>
      </div>
      <p style={{ margin: 0, fontSize: 12, color: "#64748B", fontWeight: 300 }}>{fDesde || fHasta ? "Mostrando datos del " + (fDesde || "inicio") + " al " + (fHasta || "hoy") + " — " + total + " reportes" : "Mostrando todos los datos disponibles — " + total + " reportes"}</p>

      {/* Donut + Barras */}
      <div style={{ display: "grid", gridTemplateColumns: "1fr 1fr", gap: 16 }}>
        <div style={{ ...CARD, padding: 20, maxHeight: 380, display: "flex", flexDirection: "column" }}>
          <h3 style={CT_T}>Distribución por Tipo de Hurto</h3>
          <div style={{ position: "relative", maxWidth: 260, margin: "0 auto", flex: 1, display: "flex", alignItems: "center" }}>
            <Doughnut data={{ labels: Object.keys(porTipo).map(cap), datasets: [{ data: Object.values(porTipo), backgroundColor: Object.keys(porTipo).map(function (t) { return CT[t] || "#64748B"; }), borderWidth: 0, cutout: "68%" }] }} options={{ responsive: true, plugins: { legend: { display: false } } }} />
            <div style={{ position: "absolute", top: "50%", left: "50%", transform: "translate(-50%,-50%)", textAlign: "center" }}>
              <div style={{ fontSize: 26, fontWeight: 600, color: "#1E293B" }}>{totalTipos}</div>
              <div style={{ fontSize: 11, color: "#64748B", fontWeight: 300 }}>Total</div>
            </div>
          </div>
          <div style={{ display: "flex", justifyContent: "center", gap: 16, marginTop: 14, flexWrap: "wrap" }}>
            {Object.entries(porTipo).map(function (e) { return (<div key={e[0]} style={{ display: "flex", alignItems: "center", gap: 5 }}><div style={{ width: 8, height: 8, borderRadius: "50%", backgroundColor: CT[e[0]] || "#64748B" }} /><span style={{ fontSize: 13, color: "#1E293B" }}>{cap(e[0])}</span><span style={{ fontSize: 13, fontWeight: 700, color: CT[e[0]] || "#1E293B" }}>{e[1]}</span></div>); })}
          </div>
        </div>
        <div style={{ ...CARD, padding: 20, maxHeight: 380, display: "flex", flexDirection: "column" }}>
          <h3 style={CT_T}>Incidentes por Comuna</h3>
          <p style={{ margin: "-8px 0 12px", fontSize: 12, color: "#64748B", fontWeight: 300 }}>{comunasCon + " de 12 comunas con incidentes" + (cMax ? ". Mayor: C" + cMax[0] + " (" + cMax[1] + ")" : "")}</p>
          <div style={{ flex: 1 }}>
            <Bar data={{ labels: cLabels, datasets: [{ label: "Incidentes", data: cValues, backgroundColor: cColors, borderRadius: 6, borderSkipped: false }] }} options={{ responsive: true, maintainAspectRatio: false, plugins: { legend: { display: false } }, scales: { y: { beginAtZero: true, ticks: { stepSize: 1, font: { size: 11 } }, grid: { color: "#F1F5F9" } }, x: { ticks: { font: { size: 11 } }, grid: { display: false } } } }} />
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
          <Line data={{ labels: fLabels, datasets: [{ label: "Reportes", data: fValues, borderColor: "#2563EB", backgroundColor: "rgba(37,99,235,0.1)", fill: true, tension: 0.4, pointBackgroundColor: "#2563EB", pointRadius: 4 }] }} options={{ responsive: true, maintainAspectRatio: false, plugins: { legend: { display: false } }, scales: { y: { min: Math.max(0, fMin - 1), max: fMax + Math.ceil(fMax * 0.2) || 5, ticks: { stepSize: 1, font: { size: 11 } }, grid: { color: "#F1F5F9" } }, x: { ticks: { font: { size: 10 }, maxRotation: 45 }, grid: { display: false } } } }} />
        </div>
      </div>

      {/* Franja + Top barrios */}
      <div style={{ display: "grid", gridTemplateColumns: "1fr 1fr", gap: 16 }}>
        <div style={{ ...CARD, padding: 20, maxHeight: 380, display: "flex", flexDirection: "column" }}>
          <h3 style={{ ...CT_T, marginBottom: 4 }}>Por Franja Horaria</h3>
          {franjaMax && <p style={{ margin: "0 0 12px", fontSize: 12, color: "#64748B", fontWeight: 300 }}>{"La franja " + (NF[franjaMax[0]] || franjaMax[0]) + " concentra el mayor número de incidentes (" + franjaMax[1] + ")"}</p>}
          <div style={{ maxWidth: 260, margin: "0 auto", flex: 1, display: "flex", alignItems: "center" }}>
            <Doughnut data={{ labels: Object.keys(porFranja).map(function (f) { return NF[f] || f; }), datasets: [{ data: Object.values(porFranja), backgroundColor: Object.keys(porFranja).map(function (f) { return CF[f] || "#64748B"; }), borderWidth: 0, cutout: "60%" }] }} options={{ responsive: true, plugins: { legend: { display: false } } }} />
          </div>
          <div style={{ display: "flex", justifyContent: "center", gap: 14, marginTop: 14, flexWrap: "wrap" }}>
            {Object.entries(porFranja).map(function (e) { return (<div key={e[0]} style={{ display: "flex", alignItems: "center", gap: 5 }}><div style={{ width: 8, height: 8, borderRadius: "50%", backgroundColor: CF[e[0]] || "#64748B" }} /><span style={{ fontSize: 13, color: "#1E293B" }}>{NF[e[0]] || e[0]}</span><span style={{ fontSize: 13, fontWeight: 700, color: CF[e[0]] || "#1E293B" }}>{e[1]}</span></div>); })}
          </div>
        </div>
        <div style={{ ...CARD, maxHeight: 380, display: "flex", flexDirection: "column", alignItems: "center", justifyContent: "center" }}>
          <svg width="48" height="48" viewBox="0 0 24 24" fill="none" stroke="#CBD5E1" strokeWidth="1.5" strokeLinecap="round" strokeLinejoin="round"><path d="M21 10c0 7-9 13-9 13s-9-6-9-13a9 9 0 0 1 18 0z"/><circle cx="12" cy="10" r="3"/></svg>
          <h3 style={{ margin: "12px 0 4px", fontSize: 15, fontWeight: 600, color: "#1E293B" }}>Top 5 Barrios</h3>
          <p style={{ margin: "0 0 12px", fontSize: 13, color: "#64748B", fontWeight: 400, textAlign: "center" }}>Esta sección se conectará próximamente</p>
          <span style={{ backgroundColor: "#EFF6FF", color: "#2563EB", padding: "4px 14px", borderRadius: 99, fontSize: 11, fontWeight: 500, fontFamily: "'Montserrat',sans-serif" }}>Próximamente</span>
        </div>
      </div>
    </div>
  );
}

function Kpi(p) { return (<div style={CARD}><div style={{ display: "flex", alignItems: "center", gap: 14 }}><div style={{ width: 48, height: 48, borderRadius: "50%", backgroundColor: p.color + "26", display: "flex", alignItems: "center", justifyContent: "center" }}>{p.icon}</div><div><div style={{ fontSize: 28, fontWeight: 600, color: "#1E293B", lineHeight: 1 }}>{p.value}</div><div style={{ fontSize: 12, color: "#64748B", fontWeight: 300, marginTop: 2 }}>{p.label}</div></div></div></div>); }
function Fld(p) { return (<div style={{ display: "flex", flexDirection: "column", gap: 4, flex: 1, minWidth: 120 }}><label style={{ fontSize: 11, color: "#64748B", fontWeight: 300 }}>{p.label}</label>{p.children}</div>); }

export default TabDashboard;

var CARD = { backgroundColor: "#fff", borderRadius: 12, padding: 24, border: "0.5px solid #CBD5E1", boxShadow: "0 1px 4px rgba(0,0,0,0.06)" };
var CT_T = { margin: "0 0 16px", fontSize: 15, fontWeight: 600, color: "#1E293B" };
var INP = { height: 38, padding: "0 10px", borderRadius: 8, border: "0.5px solid #CBD5E1", fontSize: 13, color: "#1E293B", fontFamily: "'Inter',sans-serif", backgroundColor: "#F8FAFC", boxSizing: "border-box", width: "100%" };
var BTN_P = { padding: "10px 20px", borderRadius: 8, border: "none", backgroundColor: "#2563EB", color: "#fff", fontFamily: "'Montserrat',sans-serif", fontWeight: 500, fontSize: 13, cursor: "pointer" };
var BTN_S = { padding: "10px 20px", borderRadius: 8, border: "1px solid #CBD5E1", backgroundColor: "transparent", color: "#64748B", fontSize: 13, cursor: "pointer" };
