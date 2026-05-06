import { useState, useEffect, useRef } from "react";
import ChartDataLabels from "chartjs-plugin-datalabels";
import { Chart as ChartJS, CategoryScale, LinearScale, BarElement, PointElement, LineElement, ArcElement, Tooltip, Legend, Filler } from "chart.js";
import { Bar, Doughnut, Line } from "react-chartjs-2";
import { getResumen, getReportesMapa } from "../../services/reportService.js";
import mapboxgl from "mapbox-gl";

ChartJS.register(CategoryScale, LinearScale, BarElement, PointElement, LineElement, ArcElement, Tooltip, Legend, Filler, ChartDataLabels);

var COLORES_TIPO = { atraco: "#B91C1C", raponazo: "#0891B2", fleteo: "#D946EF", cosquilleo: "#8A2BE2" };
var COLORES_FRANJA = { "06:00-11:59": "#FBBF24", "12:00-17:59": "#F97316", "18:00-23:59": "#BE185D", "00:00-05:59": "#D946EF" };
var NOMBRES_FRANJA = { "06:00-11:59": "Mañana (06:00-11:59)", "12:00-17:59": "Tarde (12:00-17:59)", "18:00-23:59": "Noche (18:00-23:59)", "00:00-05:59": "Madrugada (00:00-05:59)" };

var NIVELES = [
  { min: 0, max: 0, label: "Zona segura", color: "#22C55E", bg: "rgba(34,197,94,0.2)", text: "#166534" },
  { min: 1, max: 2, label: "Bajo riesgo", color: "#FACC15", bg: "rgba(250,204,21,0.2)", text: "#854D0E" },
  { min: 3, max: 5, label: "Riesgo medio", color: "#F97316", bg: "rgba(249,115,22,0.2)", text: "#9A3412" },
  { min: 6, max: 9999, label: "Alto riesgo", color: "#BE185D", bg: "rgba(190,24,93,0.2)", text: "#881337" },
];

function getNivel(val) {
  for (var i = 0; i < NIVELES.length; i++) { if (val >= NIVELES[i].min && val <= NIVELES[i].max) return NIVELES[i]; }
  return NIVELES[3];
}

var MAPBOX_TOKEN = import.meta.env.VITE_MAPBOX_TOKEN || "";

function MapaCalor() {
  var mapContainer = useRef(null);
  var mapRef = useRef(null);
  var [puntos, setPuntos] = useState([]);

  useEffect(function () {
    getReportesMapa().then(setPuntos).catch(function () { setPuntos([]); });
  }, []);

  useEffect(function () {
    if (!mapContainer.current || mapRef.current) return;
    mapboxgl.accessToken = MAPBOX_TOKEN;
    var map = new mapboxgl.Map({
      container: mapContainer.current,
      style: "mapbox://styles/mapbox/light-v11",
      center: [-77.2811, 1.2136],
      zoom: 12.5,
      attributionControl: false,
      interactive: true,
    });
    map.addControl(new mapboxgl.NavigationControl({ showCompass: false }), "top-right");
    mapRef.current = map;

    map.on("load", function () {
      if (puntos.length > 0) addHeatmap(map, puntos);
    });

    return function () { map.remove(); mapRef.current = null; };
  }, []);

  useEffect(function () {
    if (!mapRef.current || puntos.length === 0) return;
    var map = mapRef.current;
    if (map.isStyleLoaded()) { addHeatmap(map, puntos); }
    else { map.on("load", function () { addHeatmap(map, puntos); }); }
  }, [puntos]);

  return (
    <div ref={mapContainer} style={{ width: "100%", height: "100%", borderRadius: 10, minHeight: 380 }} />
  );
}

function addHeatmap(map, puntos) {
  if (map.getSource("incidentes")) return;
  var geojson = {
    type: "FeatureCollection",
    features: puntos.filter(function (p) { return p.latitud && p.longitud; }).map(function (p) {
      return { type: "Feature", geometry: { type: "Point", coordinates: [parseFloat(p.longitud), parseFloat(p.latitud)] }, properties: { tipo: p.tipo_hurto } };
    }),
  };
  map.addSource("incidentes", { type: "geojson", data: geojson });
  map.addLayer({
    id: "incidentes-heat",
    type: "heatmap",
    source: "incidentes",
    paint: {
      "heatmap-weight": 1,
      "heatmap-intensity": ["interpolate", ["linear"], ["zoom"], 10, 1, 15, 3],
      "heatmap-color": ["interpolate", ["linear"], ["heatmap-density"], 0, "rgba(34,197,94,0)", 0.2, "#22C55E", 0.4, "#FACC15", 0.6, "#F97316", 0.8, "#BE185D", 1, "#881337"],
      "heatmap-radius": ["interpolate", ["linear"], ["zoom"], 10, 15, 15, 30],
      "heatmap-opacity": 0.8,
    },
  });
  map.addLayer({
    id: "incidentes-point",
    type: "circle",
    source: "incidentes",
    minzoom: 14,
    paint: {
      "circle-radius": 6,
      "circle-color": "#B91C1C",
      "circle-stroke-width": 1.5,
      "circle-stroke-color": "#fff",
      "circle-opacity": 0.9,
    },
  });
}

export default function TabEstadisticas() {
  var [resumen, setResumen] = useState(null);
  var [resumenZona, setResumenZona] = useState(null);
  var [cargando, setCargando] = useState(true);
  var [compDesde, setCompDesde] = useState("");
  var [compHasta, setCompHasta] = useState("");
  var [modoRural, setModoRural] = useState(false);
  var [corregimientos, setCorregimientos] = useState([]);

  useEffect(function () {
    getResumen().then(setResumen).catch(console.error).finally(function () { setCargando(false); });
    import("../../services/api.js").then(function (mod) {
      mod.default.get("/api/reportes/corregimientos").then(function (r) { setCorregimientos(r.data.data || []); }).catch(function () {});
    });
  }, []);

  useEffect(function () {
    var cancelled = false;
    setResumenZona(null);
    var zona = modoRural ? "rural" : "urbana";
    import("../../services/api.js").then(function (mod) {
      mod.default.get("/api/reportes/admin/resumen", { params: { zona_tipo: zona } }).then(function (r) { if (!cancelled) setResumenZona(r.data.data); }).catch(console.error);
    });
    return function () { cancelled = true; };
  }, [modoRural]);

  function toggleModo(rural) { if (rural === modoRural) return; setResumenZona(null); setModoRural(rural); }

  if (cargando) return <p style={{ color: "#64748b", textAlign: "center", padding: 40, fontWeight: 300 }}>Cargando...</p>;
  if (!resumen) return <p style={{ color: "#64748b", textAlign: "center" }}>Error al cargar estadísticas</p>;

  var d = resumenZona || resumen;
  var porTipo = d.porTipo || {};
  var porComuna = d.porComuna || {};
  var porFranja = d.porFranja || {};
  var porFecha = d.porFecha || {};
  var porCorregimiento = d.porCorregimiento || {};
  var totalTipos = Object.values(porTipo).reduce(function (a, b) { return a + b; }, 0) || 1;
  var totalFranjas = Object.values(porFranja).reduce(function (a, b) { return a + b; }, 0) || 1;

  var comunas = Array.from({ length: 12 }, function (_, i) {
    var val = porComuna[String(i + 1)] || porComuna[i + 1] || 0;
    return { numero: i + 1, incidentes: val, nivel: getNivel(val) };
  });

  /* Comparativa mensual — filtrar por rango si hay filtros activos */
  var fechasFiltradas = porFecha;
  if (compDesde || compHasta) {
    fechasFiltradas = {};
    Object.entries(porFecha).forEach(function (e) {
      if (compDesde && e[0] < compDesde) return;
      if (compHasta && e[0] > compHasta) return;
      fechasFiltradas[e[0]] = e[1];
    });
  }
  var meses = {};
  Object.entries(fechasFiltradas).forEach(function (e) { var k = e[0].substring(0, 7); meses[k] = (meses[k] || 0) + e[1]; });
  var mesesEntries = Object.entries(meses).sort(function (a, b) { return a[0].localeCompare(b[0]); });
  var usarSemanas = mesesEntries.length <= 1;
  var compLabels, compValues;

  if (usarSemanas) {
    var semanas = {};
    Object.entries(porFecha).forEach(function (e) {
      var d = new Date(e[0] + "T00:00:00"); var ini = new Date(d); ini.setDate(d.getDate() - d.getDay());
      var k = ini.toISOString().split("T")[0]; semanas[k] = (semanas[k] || 0) + e[1];
    });
    var semEntries = Object.entries(semanas).sort(function (a, b) { return a[0].localeCompare(b[0]); });
    compLabels = semEntries.map(function (e) { var d = new Date(e[0] + "T00:00:00"); return d.toLocaleDateString("es-CO", { day: "2-digit", month: "short" }); });
    compValues = semEntries.map(function (e) { return e[1]; });
  } else {
    compLabels = mesesEntries.map(function (e) { var d = new Date(e[0] + "-01T00:00:00"); return d.toLocaleDateString("es-CO", { month: "short", year: "2-digit" }); });
    compValues = mesesEntries.map(function (e) { return e[1]; });
  }

  /* Color de tendencia */
  var tendColor = "#2563EB";
  if (compValues.length >= 2) {
    var last = compValues[compValues.length - 1]; var prev = compValues[compValues.length - 2];
    tendColor = last > prev ? "#EF4444" : last < prev ? "#10B981" : "#2563EB";
  }

  var totalGeneral = Object.values(porTipo).reduce(function (a, b) { return a + b; }, 0);
  var comunaConMas = comunas.reduce(function (a, b) { return b.incidentes > a.incidentes ? b : a; }, comunas[0]);
  var franjaConMas = Object.entries(porFranja).sort(function (a, b) { return b[1] - a[1]; })[0];

  // Corregimientos para modo rural
  var corrEntries = Object.entries(porCorregimiento).sort(function (a, b) { return b[1] - a[1]; });
  var corrMax = corrEntries[0];

  return (
    <div style={{ display: "flex", flexDirection: "column", gap: 20 }}>
      <style>{`@keyframes fadeIn { from { opacity: 0; transform: translateY(6px); } to { opacity: 1; transform: translateY(0); } }`}</style>

      {/* Chip Urbano/Rural */}
      <div style={{ display: "flex", alignItems: "center", gap: 12 }}>
        <div style={{ display: "flex", background: "#F1F5F9", borderRadius: 8, padding: 3, height: 38, boxSizing: "border-box", position: "relative", overflow: "hidden", width: 180 }}>
          <div style={{ position: "absolute", top: 3, left: modoRural ? "50%" : 3, width: "calc(50% - 3px)", height: "calc(100% - 6px)", borderRadius: 6, backgroundColor: modoRural ? "#16A34A" : "#2563EB", transition: "left 0.3s cubic-bezier(0.4, 0, 0.2, 1), background-color 0.3s ease", zIndex: 0 }} />
          <button type="button" onClick={function () { toggleModo(false); }} style={{ display: "flex", alignItems: "center", gap: 5, padding: "0 14px", border: "none", borderRadius: 6, fontSize: 13, fontFamily: "'Inter',sans-serif", fontWeight: 500, cursor: "pointer", height: "100%", backgroundColor: "transparent", transition: "color 0.25s ease", flex: 1, justifyContent: "center", color: modoRural ? "#64748B" : "#fff", position: "relative", zIndex: 1 }}>Urbano</button>
          <button type="button" onClick={function () { toggleModo(true); }} style={{ display: "flex", alignItems: "center", gap: 5, padding: "0 14px", border: "none", borderRadius: 6, fontSize: 13, fontFamily: "'Inter',sans-serif", fontWeight: 500, cursor: "pointer", height: "100%", backgroundColor: "transparent", transition: "color 0.25s ease", flex: 1, justifyContent: "center", color: modoRural ? "#fff" : "#64748B", position: "relative", zIndex: 1 }}>Rural</button>
        </div>
        <span style={{ fontSize: 12, color: "#64748B", fontWeight: 300 }}>{"Mostrando estadísticas " + (modoRural ? "rurales" : "urbanas") + " — " + totalGeneral + " reportes"}</span>
      </div>

      {/* Resumen ejecutivo */}
      <div style={{ ...CARD, backgroundColor: "#EFF6FF", border: "0.5px solid #BFDBFE" }}>
        <p style={{ margin: 0, fontSize: 13, color: "#1E3A8A", fontWeight: 400, fontFamily: "'Inter',sans-serif", lineHeight: 1.6 }}>
          {modoRural
            ? "Se registran " + totalGeneral + " incidentes rurales." + (corrMax ? " El corregimiento con mayor incidencia es " + corrMax[0] + " con " + corrMax[1] + " reportes." : "") + (franjaConMas ? " La franja horaria más crítica es " + (NOMBRES_FRANJA[franjaConMas[0]] || franjaConMas[0]) + " con " + franjaConMas[1] + " incidentes." : "")
            : "Se registran " + totalGeneral + " incidentes en total. La comuna con mayor incidencia es la Comuna " + comunaConMas.numero + " con " + comunaConMas.incidentes + " reportes" + (comunaConMas.incidentes >= 6 ? " (alto riesgo)" : "") + ". " + (franjaConMas ? "La franja horaria más crítica es " + (NOMBRES_FRANJA[franjaConMas[0]] || franjaConMas[0]) + " con " + franjaConMas[1] + " incidentes." : "")
          }
        </p>
      </div>

      {/* Sección 1: Mapa de calor */}
      <div style={CARD}>
        <div style={{ textAlign: "center", marginBottom: 16 }}>
          <h3 style={CARD_TITLE_CENTER}>{modoRural ? "Mapa de Calor Rural" : "Mapa de Calor por Comuna"}</h3>
          <p style={{ margin: "4px 0 0", fontSize: 12, color: "#64748b", fontWeight: 300 }}>Distribución de incidentes en Pasto</p>
        </div>
        <div style={{ display: "flex", justifyContent: "center", gap: 16, marginBottom: 20 }}>
          {NIVELES.map(function (n) { return (<div key={n.label} style={{ display: "flex", alignItems: "center", gap: 6 }}><div style={{ width: 10, height: 10, borderRadius: "50%", backgroundColor: n.color }} /><span style={{ fontSize: 12, color: "#64748b", fontWeight: 300 }}>{n.label}</span></div>); })}
        </div>
        <div style={{ display: "grid", gridTemplateColumns: "1fr 1fr", gap: 16 }}>
          {/* Mapa interactivo */}
          <div style={{ borderRadius: 10, overflow: "hidden", border: "0.5px solid #CBD5E1", minHeight: 380 }}>
            <MapaCalor />
          </div>
          {/* Tarjetas de comunas o corregimientos */}
          {modoRural ? (
            <div style={{ display: "grid", gridTemplateColumns: "repeat(3, 1fr)", gap: 8, alignContent: "start", animation: "fadeIn 0.4s ease", maxHeight: 380, overflowY: "auto" }}>
              {corregimientos.map(function (c) {
                var val = porCorregimiento[c.nombre] || 0;
                var nivel = getNivel(val);
                return (
                  <div key={c.id} style={{ borderRadius: 10, padding: 12, backgroundColor: nivel.bg, textAlign: "left", border: "0.5px solid " + nivel.color + "33" }}>
                    <span style={{ fontSize: 9, fontWeight: 500, letterSpacing: 0.5, textTransform: "uppercase", color: nivel.text }}>CORREG.</span>
                    <span style={{ display: "block", fontSize: 13, fontWeight: 700, color: nivel.text, margin: "1px 0 4px", lineHeight: 1.2 }}>{c.nombre.length > 10 ? c.nombre.substring(0, 10) + "." : c.nombre}</span>
                    <span style={{ fontSize: 10, fontWeight: 300, color: nivel.text }}>Incidentes</span>
                    <span style={{ display: "block", fontSize: 16, fontWeight: 700, color: nivel.color }}>{val}</span>
                  </div>
                );
              })}
            </div>
          ) : (
            <div style={{ display: "grid", gridTemplateColumns: "repeat(3, 1fr)", gap: 8, alignContent: "start", animation: "fadeIn 0.4s ease" }}>
            {comunas.map(function (c) { return (
              <div key={c.numero} style={{ borderRadius: 10, padding: 12, backgroundColor: c.nivel.bg, textAlign: "left", border: "0.5px solid " + c.nivel.color + "33" }}>
                <span style={{ fontSize: 9, fontWeight: 500, letterSpacing: 0.5, textTransform: "uppercase", color: c.nivel.text }}>COMUNA</span>
                <span style={{ display: "block", fontSize: 22, fontWeight: 700, color: c.nivel.text, margin: "1px 0 4px" }}>{c.numero}</span>
                <span style={{ fontSize: 10, fontWeight: 300, color: c.nivel.text }}>Incidentes</span>
                <span style={{ display: "block", fontSize: 16, fontWeight: 700, color: c.nivel.color }}>{c.incidentes}</span>
              </div>
            ); })}
            </div>
          )}
        </div>
      </div>

      {/* Sección 2: Tipos de hurto */}
      <div style={CARD}>
        <h3 style={CARD_TITLE_CENTER}>Distribución de Tipos de Hurto</h3>
        <div style={{ display: "grid", gridTemplateColumns: "repeat(4, 1fr)", gap: 16, marginTop: 16 }}>
          {Object.entries(porTipo).map(function (entry) {
            var tipo = entry[0]; var count = entry[1];
            var color = COLORES_TIPO[tipo] || "#64748B";
            var pct = ((count / totalTipos) * 100).toFixed(1);
            return (
              <div key={tipo} style={{ textAlign: "center" }}>
                <div style={{ width: 52, height: 52, borderRadius: "50%", backgroundColor: color + "26", display: "flex", alignItems: "center", justifyContent: "center", margin: "0 auto 10px" }}>
                  <span style={{ fontSize: 18, fontWeight: 700, color: color, fontFamily: "'Inter',sans-serif" }}>{count}</span>
                </div>
                <span style={{ display: "block", fontSize: 14, fontWeight: 600, color: "#1E293B" }}>{tipo.charAt(0).toUpperCase() + tipo.slice(1)}</span>
                <span style={{ display: "block", fontSize: 12, color: "#64748B", fontWeight: 300, marginTop: 2 }}>{pct}% del total</span>
                <div style={{ height: 8, borderRadius: 99, backgroundColor: "#F1F5F9", marginTop: 8, width: "100%" }}>
                  <div style={{ height: 8, borderRadius: 99, backgroundColor: color, width: pct + "%" }} />
                </div>
              </div>
            );
          })}
        </div>
      </div>

      {/* Sección 3: Franja horaria */}
      <div style={{ display: "grid", gridTemplateColumns: "1fr 1fr", gap: 16 }}>
        <div style={CARD}>
          <h3 style={CARD_TITLE}>Análisis por Franja Horaria</h3>
          <div style={{ maxWidth: 260, margin: "0 auto" }}>
            <Doughnut data={{ labels: Object.keys(porFranja).map(function (f) { return NOMBRES_FRANJA[f] || f; }), datasets: [{ data: Object.values(porFranja), backgroundColor: Object.keys(porFranja).map(function (f) { return COLORES_FRANJA[f] || "#64748B"; }), borderWidth: 0, cutout: "60%" }] }} options={{ responsive: true, plugins: { legend: { display: false }, datalabels: { display: true, color: "#fff", font: { size: 14, weight: 700 }, formatter: function (value) { return value > 0 ? value : ""; } } } }} />
          </div>
          <div style={{ display: "grid", gridTemplateColumns: "1fr 1fr", gap: "6px 12px", marginTop: 14 }}>
            {Object.entries(porFranja).map(function (e) { return (<div key={e[0]} style={{ display: "flex", alignItems: "center", gap: 5 }}><div style={{ width: 8, height: 8, borderRadius: "50%", backgroundColor: COLORES_FRANJA[e[0]] || "#64748B", flexShrink: 0 }} /><span style={{ fontSize: 11, color: "#1E293B" }}>{NOMBRES_FRANJA[e[0]] || e[0]}</span><span style={{ fontSize: 11, fontWeight: 700, color: COLORES_FRANJA[e[0]] || "#1E293B" }}>{e[1]}</span></div>); })}
          </div>
        </div>
        <div style={CARD}>
          <h3 style={CARD_TITLE}>Incidentes por Franja</h3>
          <div style={{ display: "flex", flexDirection: "column", gap: 16, marginTop: 8 }}>
            {Object.entries(porFranja).map(function (entry) {
              var franja = entry[0]; var count = entry[1];
              var color = COLORES_FRANJA[franja] || "#64748B";
              var pct = ((count / totalFranjas) * 100).toFixed(1);
              return (
                <div key={franja}>
                  <div style={{ display: "flex", justifyContent: "space-between", marginBottom: 6 }}>
                    <span style={{ fontSize: 13, color: "#1E293B", fontWeight: 500 }}>{NOMBRES_FRANJA[franja] || franja}</span>
                    <span style={{ fontSize: 13, color: "#64748B", fontWeight: 300 }}>{count} ({pct}%)</span>
                  </div>
                  <div style={{ height: 12, borderRadius: 6, backgroundColor: "#F1F5F9" }}>
                    <div style={{ height: 12, borderRadius: 6, backgroundColor: color, width: pct + "%", transition: "width 0.3s" }} />
                  </div>
                </div>
              );
            })}
          </div>
        </div>
      </div>

      {/* Sección 4: Comparativa mensual */}
      <div style={CARD}>
        <div style={{ display: "flex", justifyContent: "space-between", alignItems: "center", marginBottom: 16, flexWrap: "wrap", gap: 10 }}>
          <h3 style={{ ...CARD_TITLE, marginBottom: 0 }}>{usarSemanas ? "Tendencia Semanal" : "Comparativa Mensual"}</h3>
          <div style={{ display: "flex", alignItems: "center", gap: 8 }}>
            <input type="date" value={compDesde} onChange={function (e) { setCompDesde(e.target.value); }} style={FINP} placeholder="Desde" />
            <input type="date" value={compHasta} onChange={function (e) { setCompHasta(e.target.value); }} style={FINP} placeholder="Hasta" />
            {(compDesde || compHasta) && <button onClick={function () { setCompDesde(""); setCompHasta(""); }} style={{ height: 34, padding: "0 12px", borderRadius: 6, border: "1px solid #CBD5E1", backgroundColor: "transparent", color: "#64748B", fontSize: 12, cursor: "pointer" }}>Limpiar</button>}
          </div>
        </div>
        <div style={{ maxHeight: 300, width: "100%" }}>
        <Line data={{ labels: compLabels, datasets: [{ label: "Reportes", data: compValues, borderColor: tendColor, backgroundColor: tendColor + "1A", fill: true, tension: 0.4, pointBackgroundColor: tendColor, pointRadius: 5, pointHoverRadius: 7 }] }} options={{ responsive: true, maintainAspectRatio: false, plugins: { legend: { display: false } }, scales: { y: { min: Math.max(0, Math.min.apply(null, compValues.length ? compValues : [0]) - 1), ticks: { stepSize: 1, font: { size: 11 } }, grid: { color: "#F1F5F9" } }, x: { ticks: { font: { size: 11 } }, grid: { display: false } } } }} />
        </div>
        {compValues.length >= 2 && (
          <div style={{ display: "flex", justifyContent: "center", gap: 16, marginTop: 12 }}>
            <span style={{ fontSize: 12, color: "#10B981", fontWeight: 500 }}>● Decremento</span>
            <span style={{ fontSize: 12, color: "#F59E0B", fontWeight: 500 }}>● Moderado</span>
            <span style={{ fontSize: 12, color: "#EF4444", fontWeight: 500 }}>● Incremento</span>
          </div>
        )}
      </div>
    </div>
  );
}

var CARD = { backgroundColor: "#fff", borderRadius: 12, padding: 24, border: "0.5px solid #CBD5E1", boxShadow: "0 1px 4px rgba(0,0,0,0.06)" };
var CARD_TITLE = { margin: "0 0 16px", fontSize: 15, fontWeight: 600, color: "#1E293B", fontFamily: "'Inter',sans-serif" };
var CARD_TITLE_CENTER = { margin: 0, fontSize: 16, color: "#1E293B", fontWeight: 600, fontFamily: "'Inter',sans-serif" };
var FINP = { height: 34, padding: "0 10px", borderRadius: 6, border: "0.5px solid #CBD5E1", fontSize: 12, color: "#1E293B", backgroundColor: "#F8FAFC", boxSizing: "border-box" };
