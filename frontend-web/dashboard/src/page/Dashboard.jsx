import { useState } from "react";
import { useNavigate } from "react-router-dom";
import { logoutAdmin } from "../services/authService";
import TabResumen from "./tabs/TabResumen";
import TabIncidentes from "./tabs/TabIncidentes";
import TabUsuarios from "./tabs/TabUsuarios";
import TabEstadisticas from "./tabs/TabEstadisticas";

const TABS = [
  { id: "resumen", label: "Resumen", icon: "📊" },
  { id: "incidentes", label: "Incidentes", icon: "⚠️" },
  { id: "usuarios", label: "Usuarios", icon: "👥" },
  { id: "estadisticas", label: "Estadísticas", icon: "📈" },
];

export default function Dashboard() {
  const navigate = useNavigate();
  const admin = JSON.parse(sessionStorage.getItem("admin") || "{}");
  const [activeTab, setActiveTab] = useState("resumen");
  const [counts, setCounts] = useState({ incidentes: 0, usuarios: 0 });

  const cerrarSesion = async () => {
    await logoutAdmin();
    navigate("/");
  };

  const renderTab = () => {
    switch (activeTab) {
      case "resumen":      return <TabResumen />;
      case "incidentes":   return <TabIncidentes onCountChange={(n) => setCounts(c => ({ ...c, incidentes: n }))} />;
      case "usuarios":     return <TabUsuarios onCountChange={(n) => setCounts(c => ({ ...c, usuarios: n }))} />;
      case "estadisticas": return <TabEstadisticas />;
      default:             return null;
    }
  };

  const getTabLabel = (tab) => {
    if (tab.id === "incidentes" && counts.incidentes > 0) return `${tab.label} (${counts.incidentes})`;
    if (tab.id === "usuarios" && counts.usuarios > 0) return `${tab.label} (${counts.usuarios})`;
    return tab.label;
  };

  return (
    <div style={styles.page}>
      {/* Header */}
      <header style={styles.header}>
        <div style={styles.headerLeft}>
          <div style={styles.logoCircle}>
            <span style={{ fontSize: "18px" }}>🛡️</span>
          </div>
          <div>
            <h1 style={styles.titulo}>Panel de Administración</h1>
            <p style={styles.subtitulo}>SafeRoute: Pasto - Análisis de Seguridad</p>
          </div>
        </div>
        <div style={styles.headerRight}>
          <span style={styles.adminName}>{admin.username}</span>
          <button onClick={cerrarSesion} style={styles.btnLogout} title="Cerrar sesión">
            ⎋
          </button>
        </div>
      </header>

      {/* Tabs */}
      <nav style={styles.tabBar}>
        {TABS.map((tab) => (
          <button
            key={tab.id}
            onClick={() => setActiveTab(tab.id)}
            style={{
              ...styles.tab,
              ...(activeTab === tab.id ? styles.tabActive : {}),
            }}
          >
            <span style={styles.tabIcon}>{tab.icon}</span>
            {getTabLabel(tab)}
          </button>
        ))}
      </nav>

      {/* Content */}
      <main style={styles.content}>
        {renderTab()}
      </main>
    </div>
  );
}

const styles = {
  page: {
    fontFamily: "'Inter', -apple-system, sans-serif",
    backgroundColor: "#f1f5f9",
    minHeight: "100vh",
  },
  header: {
    display: "flex",
    justifyContent: "space-between",
    alignItems: "center",
    padding: "16px 32px",
    background: "linear-gradient(135deg, #1E1E7C, #333c87, #6D6DF9)",
    color: "#fff",
  },
  headerLeft: { display: "flex", alignItems: "center", gap: "12px" },
  logoCircle: {
    width: "40px", height: "40px", borderRadius: "50%",
    backgroundColor: "rgba(255,255,255,0.15)",
    display: "flex", alignItems: "center", justifyContent: "center",
  },
  titulo: { margin: 0, fontSize: "18px", fontWeight: "700" },
  subtitulo: { margin: "2px 0 0", fontSize: "12px", opacity: 0.8 },
  headerRight: { display: "flex", alignItems: "center", gap: "12px" },
  adminName: { fontSize: "13px", opacity: 0.9 },
  btnLogout: {
    width: "36px", height: "36px", borderRadius: "8px",
    backgroundColor: "rgba(255,255,255,0.15)", color: "#fff",
    border: "none", cursor: "pointer", fontSize: "16px",
    display: "flex", alignItems: "center", justifyContent: "center",
  },
  tabBar: {
    display: "flex", gap: "0",
    backgroundColor: "#fff",
    borderBottom: "2px solid #e2e8f0",
    padding: "0 32px",
  },
  tab: {
    padding: "14px 20px",
    border: "none", background: "none",
    cursor: "pointer",
    fontSize: "13px", fontWeight: "500",
    color: "#64748b",
    borderBottom: "2px solid transparent",
    marginBottom: "-2px",
    transition: "all 0.2s",
    display: "flex", alignItems: "center", gap: "6px",
  },
  tabActive: {
    color: "#2563EB",
    borderBottomColor: "#2563EB",
    fontWeight: "600",
  },
  tabIcon: { fontSize: "14px" },
  content: { padding: "24px 32px" },
};
