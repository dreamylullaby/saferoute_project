import { useState, useEffect } from "react";
import { getResumen } from "../../services/reportService";

const COLORES_RIESGO = {
  bajo:     { bg: "#DCFCE7", border: "#22C55E", text: "#166534" },
  medio:    { bg: "#FEF9C3", border: "#FACC15", text: "#854D0E" },
  alto:     { bg: "#FED7AA", border: "#F97316", text: "#9A3412" },
  muy_alto: { bg: "#FCE7F3", border: "#BE185D", text: "#9D174D" },
};

const COLORES_TIPO = {
  atraco:     { bg: "#FEE2E2", circle: "#B91C1C" },
  raponazo:   { bg: "#FCE7F3", circle: "#9D174D" },
  fleteo:     { bg: "#F3E8FF", circle: "#D946EF" },
  cosquilleo: { bg: "#EDE9FE", circle: "#8A2BE2" },
};

function getNivelRiesgo(cantidad) {
  if (cantidad <= 2) return "bajo";
  if (cantidad <= 5) return "medio";
  if (cantidad <= 8) return "alto";
  return "muy_alto";
}

export default function TabEstadisticas() {
  const [resumen, setResumen] = useState(null);
  const [cargando, setCargando] = useState(true);

  useEffect(() => {
    getResumen()
      .then(setResumen)
      .catch(console.error)
      .finally(() => setCargando(false));
  }, []);

  if (cargando) return <p style={{ color: "#64748b", textAlign: "center", padding: "40px" }}>Cargando...</p>;
  if (!resumen) return <p style={{ color: "#64748b", textAlign: "center" }}>Error al cargar estadísticas</p>;

  const porTipo = resumen.porTipo || {};
  const totalTipos = Object.values(porTipo).reduce((a, b) => a + b, 0) || 1;

  // Simular datos por comuna desde el resumen (si hay porComuna)
  const porComuna = resumen.porComuna || {};
  const comunas = Array.from({ length: 12 }, (_, i) => ({
    numero: i + 1,
    incidentes: porComuna[i + 1] || 0,
  }));

  return (
    <div>
      {/* Mapa de calor por comuna */}
      <div style={styles.card}>
        <div style={styles.cardHeader}>
          <h3 style={styles.cardTitle}>📍 Mapa de Calor por Comuna</h3>
          <p style={styles.cardSubtitle}>Distribución de incidentes en Pasto</p>
        </div>

        {/* Leyenda */}
        <div style={styles.leyenda}>
          {[
            { label: "Bajo", color: COLORES_RIESGO.bajo },
            { label: "Medio", color: COLORES_RIESGO.medio },
            { label: "Alto", color: COLORES_RIESGO.alto },
            { label: "Muy Alto", color: COLORES_RIESGO.muy_alto },
          ].map(({ label, color }) => (
            <div key={label} style={styles.leyendaItem}>
              <div style={{ ...styles.leyendaDot, backgroundColor: color.border }} />
              <span style={styles.leyendaText}>{label}</span>
            </div>
          ))}
        </div>

        {/* Grid de comunas */}
        <div style={styles.comunaGrid}>
          {comunas.map((c) => {
            const nivel = getNivelRiesgo(c.incidentes);
            const colores = COLORES_RIESGO[nivel];
            return (
              <div key={c.numero} style={{
                ...styles.comunaCard,
                backgroundColor: colores.bg,
                borderColor: colores.border,
              }}>
                <span style={{ ...styles.comunaLabel, color: colores.text }}>COMUNA</span>
                <span style={{ ...styles.comunaNumero, color: colores.text }}>{c.numero}</span>
                <div style={styles.comunaIncidentes}>
                  <span style={styles.comunaIncLabel}>Incidentes</span>
                  <span style={styles.comunaIncValor}>{c.incidentes}</span>
                </div>
              </div>
            );
          })}
        </div>
      </div>

      {/* Distribución por tipo */}
      <div style={{ ...styles.card, marginTop: "20px" }}>
        <h3 style={{ ...styles.cardTitle, textAlign: "center", marginBottom: "20px" }}>
          Distribución de Tipos de Hurto
        </h3>
        <div style={styles.tipoGrid}>
          {Object.entries(porTipo).map(([tipo, count]) => {
            const color = COLORES_TIPO[tipo] || { bg: "#F1F5F9", circle: "#64748B" };
            const pct = ((count / totalTipos) * 100).toFixed(1);
            return (
              <div key={tipo} style={{ ...styles.tipoCard, backgroundColor: color.bg }}>
                <div style={{ ...styles.tipoCircle, backgroundColor: color.circle }}>
                  {count}
                </div>
                <span style={styles.tipoNombre}>
                  {tipo.charAt(0).toUpperCase() + tipo.slice(1)}
                </span>
                <span style={styles.tipoPct}>{pct}% del total</span>
              </div>
            );
          })}
        </div>
      </div>
    </div>
  );
}

const styles = {
  card: {
    backgroundColor: "#fff", borderRadius: "12px", padding: "24px",
    boxShadow: "0 1px 4px rgba(0,0,0,0.06)",
  },
  cardHeader: { textAlign: "center", marginBottom: "16px" },
  cardTitle: { margin: 0, fontSize: "16px", color: "#1e293b", fontWeight: "600" },
  cardSubtitle: { margin: "4px 0 0", fontSize: "12px", color: "#64748b" },
  leyenda: {
    display: "flex", justifyContent: "center", gap: "16px",
    marginBottom: "20px",
  },
  leyendaItem: { display: "flex", alignItems: "center", gap: "6px" },
  leyendaDot: { width: "12px", height: "12px", borderRadius: "50%" },
  leyendaText: { fontSize: "12px", color: "#64748b" },
  comunaGrid: {
    display: "grid", gridTemplateColumns: "repeat(4, 1fr)",
    gap: "12px",
  },
  comunaCard: {
    borderRadius: "12px", padding: "16px",
    border: "2px solid", textAlign: "left",
  },
  comunaLabel: { fontSize: "10px", fontWeight: "700", letterSpacing: "0.5px" },
  comunaNumero: { display: "block", fontSize: "28px", fontWeight: "800", margin: "2px 0 8px" },
  comunaIncidentes: {
    backgroundColor: "rgba(255,255,255,0.7)", borderRadius: "6px",
    padding: "4px 8px", display: "inline-block",
  },
  comunaIncLabel: { fontSize: "10px", color: "#64748b", display: "block" },
  comunaIncValor: { fontSize: "16px", fontWeight: "700", color: "#1e293b" },
  tipoGrid: {
    display: "grid", gridTemplateColumns: "repeat(4, 1fr)", gap: "12px",
  },
  tipoCard: {
    borderRadius: "12px", padding: "20px",
    textAlign: "center",
  },
  tipoCircle: {
    width: "48px", height: "48px", borderRadius: "50%",
    display: "flex", alignItems: "center", justifyContent: "center",
    color: "#fff", fontSize: "18px", fontWeight: "700",
    margin: "0 auto 10px",
  },
  tipoNombre: { display: "block", fontSize: "14px", fontWeight: "600", color: "#1e293b" },
  tipoPct: { display: "block", fontSize: "12px", color: "#64748b", marginTop: "2px" },
};
