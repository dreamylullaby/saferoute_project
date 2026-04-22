import { useEffect, useState } from "react";
import { useNavigate } from "react-router-dom";
import { logoutAdmin } from "../services/authService";
import { getResumen } from "../services/reportService";
import ReportesAdmin from "./ReportesAdmin";

const COLORES_TIPO = {
  atraco:     { bg: "#fee2e2", text: "#b91c1c" },
  raponazo:   { bg: "#fce7f3", text: "#9d174d" },
  fleteo:     { bg: "#fae8ff", text: "#7e22ce" },
  cosquilleo: { bg: "#ede9fe", text: "#5b21b6" },
};

export default function Dashboard() {
  const navigate = useNavigate();
  const admin = JSON.parse(sessionStorage.getItem("admin") || "{}");
  const [resumen, setResumen] = useState(null);

  useEffect(() => {
    getResumen()
      .then(setResumen)
      .catch(console.error);
  }, []);

  const cerrarSesion = async () => {
    await logoutAdmin();
    navigate("/");
  };

  return (
    <div style={styles.page}>
      {/* Header */}
      <div style={styles.header}>
        <div>
          <h1 style={styles.titulo}>SafeRoute — Panel Admin</h1>
          <p style={styles.subtitulo}>Bienvenido, <strong>{admin.username}</strong></p>
        </div>
        <button onClick={cerrarSesion} style={styles.btnLogout}>
          Cerrar sesión
        </button>
      </div>

      {/* Tarjetas de resumen */}
      {resumen && (
        <div style={styles.tarjetas}>
          <Tarjeta titulo="Total reportes" valor={resumen.total} color={{ bg: "#eff6ff", text: "#1d4ed8" }} />
          <Tarjeta titulo="Activos"  valor={resumen.porEstado?.activo  || 0} color={{ bg: "#f0fdf4", text: "#166534" }} />
          <Tarjeta titulo="Ocultos"  valor={resumen.porEstado?.oculto  || 0} color={{ bg: "#fefce8", text: "#854d0e" }} />
          {Object.entries(resumen.porTipo || {}).map(([tipo, count]) => (
            <Tarjeta
              key={tipo}
              titulo={tipo.charAt(0).toUpperCase() + tipo.slice(1)}
              valor={count}
              color={COLORES_TIPO[tipo] || { bg: "#f1f5f9", text: "#475569" }}
            />
          ))}
        </div>
      )}

      {/* Tabla de reportes */}
      <div style={styles.seccion}>
        <h2 style={styles.seccionTitulo}>Incidentes registrados</h2>
        <ReportesAdmin />
      </div>
    </div>
  );
}

function Tarjeta({ titulo, valor, color }) {
  return (
    <div style={{ ...styles.tarjeta, backgroundColor: color.bg }}>
      <span style={{ ...styles.tarjetaValor, color: color.text }}>{valor}</span>
      <span style={styles.tarjetaTitulo}>{titulo}</span>
    </div>
  );
}

const styles = {
  page: {
    padding: "32px 40px",
    fontFamily: "'Inter', sans-serif",
    backgroundColor: "#f8fafc",
    minHeight: "100vh",
  },
  header: {
    display: "flex", justifyContent: "space-between", alignItems: "flex-start",
    marginBottom: "28px",
  },
  titulo: { margin: 0, fontSize: "22px", color: "#1e293b", fontWeight: "700" },
  subtitulo: { margin: "4px 0 0", color: "#64748b", fontSize: "14px" },
  btnLogout: {
    padding: "8px 16px", borderRadius: "8px",
    backgroundColor: "#ef4444", color: "#fff",
    border: "none", cursor: "pointer", fontSize: "13px",
  },
  tarjetas: {
    display: "flex", flexWrap: "wrap", gap: "12px",
    marginBottom: "28px",
  },
  tarjeta: {
    display: "flex", flexDirection: "column", alignItems: "center",
    padding: "16px 24px", borderRadius: "12px",
    minWidth: "120px",
  },
  tarjetaValor: { fontSize: "28px", fontWeight: "700" },
  tarjetaTitulo: { fontSize: "12px", color: "#64748b", marginTop: "4px" },
  seccion: {
    backgroundColor: "#fff",
    borderRadius: "12px",
    padding: "24px",
    boxShadow: "0 1px 4px rgba(0,0,0,0.06)",
  },
  seccionTitulo: {
    margin: "0 0 16px",
    fontSize: "16px", color: "#1e293b", fontWeight: "600",
  },
};
