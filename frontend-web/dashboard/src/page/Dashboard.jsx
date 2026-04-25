import { useState } from "react";
import { useNavigate } from "react-router-dom";
import { logoutAdmin } from "../services/authService.js";
import TabDashboard from "./tabs/TabDashboard.jsx";
import TabIncidentes from "./tabs/TabIncidentes.jsx";
import TabUsuarios from "./tabs/TabUsuarios.jsx";
import TabEstadisticas from "./tabs/TabEstadisticas.jsx";

/* ── SVG Icons ── */
function IcoDashboard() {
  return (<svg width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round"><rect x="3" y="3" width="7" height="7"/><rect x="14" y="3" width="7" height="7"/><rect x="3" y="14" width="7" height="7"/><rect x="14" y="14" width="7" height="7"/></svg>);
}
function IcoIncidentes() {
  return (<svg width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round"><path d="M10.29 3.86L1.82 18a2 2 0 0 0 1.71 3h16.94a2 2 0 0 0 1.71-3L13.71 3.86a2 2 0 0 0-3.42 0z"/><line x1="12" y1="9" x2="12" y2="13"/><line x1="12" y1="17" x2="12.01" y2="17"/></svg>);
}
function IcoUsuarios() {
  return (<svg width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round"><path d="M17 21v-2a4 4 0 0 0-4-4H5a4 4 0 0 0-4 4v2"/><circle cx="9" cy="7" r="4"/><path d="M23 21v-2a4 4 0 0 0-3-3.87"/><path d="M16 3.13a4 4 0 0 1 0 7.75"/></svg>);
}
function IcoEstadisticas() {
  return (<svg width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round"><line x1="18" y1="20" x2="18" y2="10"/><line x1="12" y1="20" x2="12" y2="4"/><line x1="6" y1="20" x2="6" y2="14"/></svg>);
}
function IcoLogout() {
  return (<svg width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round"><path d="M9 21H5a2 2 0 0 1-2-2V5a2 2 0 0 1 2-2h4"/><polyline points="16 17 21 12 16 7"/><line x1="21" y1="12" x2="9" y2="12"/></svg>);
}
function IcoShield() {
  return (<svg width="24" height="24" viewBox="0 0 24 24" fill="none" stroke="#fff" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round"><path d="M12 22s8-4 8-10V5l-8-3-8 3v7c0 6 8 10 8 10z"/></svg>);
}

var NAV_ITEMS = [
  { id: "dashboard", label: "Dashboard", Ico: IcoDashboard },
  { id: "incidentes", label: "Incidentes", Ico: IcoIncidentes },
  { id: "usuarios", label: "Usuarios", Ico: IcoUsuarios },
  { id: "estadisticas", label: "Estadísticas", Ico: IcoEstadisticas },
];

var SECTION_TITLES = {
  dashboard: "Dashboard",
  incidentes: "Gestión de Incidentes",
  usuarios: "Gestión de Usuarios",
  estadisticas: "Estadísticas y Análisis",
};

export default function Dashboard() {
  var navigate = useNavigate();
  var admin = JSON.parse(sessionStorage.getItem("admin") || "{}");
  var [activeTab, setActiveTab] = useState("dashboard");
  var [counts, setCounts] = useState({ incidentes: 0, usuarios: 0 });

  var cerrarSesion = async function () {
    await logoutAdmin();
    navigate("/");
  };

  var getIniciales = function (nombre) {
    if (!nombre) return "AD";
    var partes = nombre.trim().split(/\s+/);
    if (partes.length >= 2) return (partes[0][0] + partes[1][0]).toUpperCase();
    return nombre.substring(0, 2).toUpperCase();
  };

  var renderTab = function () {
    switch (activeTab) {
      case "dashboard": return <TabDashboard />;
      case "incidentes": return <TabIncidentes onCountChange={function (n) { setCounts(function (c) { return { ...c, incidentes: n }; }); }} />;
      case "usuarios": return <TabUsuarios onCountChange={function (n) { setCounts(function (c) { return { ...c, usuarios: n }; }); }} />;
      case "estadisticas": return <TabEstadisticas />;
      default: return null;
    }
  };

  return (
    <div style={S.layout}>
      {/* ── Sidebar ── */}
      <aside style={S.sidebar}>
        <div style={S.sidebarTop}>
          <div style={S.logoRow}>
            <div style={S.logoCircle}><IcoShield /></div>
            <div>
              <div style={S.logoText}>SafeRoute</div>
              <div style={S.logoSub}>Panel de Administración</div>
            </div>
          </div>
          <nav style={S.nav}>
            {NAV_ITEMS.map(function (item) {
              var active = activeTab === item.id;
              return (
                <button key={item.id} onClick={function () { setActiveTab(item.id); }} style={active ? { ...S.navItem, ...S.navItemActive } : S.navItem}>
                  <item.Ico />
                  <span>{item.label}</span>
                  {item.id === "incidentes" && counts.incidentes > 0 && (
                    <span style={S.badge}>{counts.incidentes}</span>
                  )}
                </button>
              );
            })}
          </nav>
        </div>
        <div style={S.sidebarBottom}>
          <div style={S.divider} />
          <button onClick={cerrarSesion} style={S.logoutBtn}>
            <IcoLogout />
            <span>Cerrar sesión</span>
          </button>
        </div>
      </aside>

      {/* ── Main area ── */}
      <div style={S.mainArea}>
        {/* Header */}
        <header style={S.header}>
          <h2 style={S.headerTitle}>{SECTION_TITLES[activeTab] || "Dashboard"}</h2>
          <div style={S.headerRight}>
            <div style={S.headerInfo}>
              <span style={S.headerName}>{admin.username || "Administrador"}</span>
              <span style={S.headerRole}>Administrador</span>
            </div>
            <div style={S.headerAvatar}>{getIniciales(admin.username)}</div>
          </div>
        </header>
        {/* Content */}
        <main style={S.content}>{renderTab()}</main>
      </div>
    </div>
  );
}

var S = {
  layout: { display: "flex", minHeight: "100vh", fontFamily: "'Inter', sans-serif", backgroundColor: "#F1F5F9" },
  /* Sidebar */
  sidebar: { width: 220, background: "linear-gradient(180deg, #1E1E7C, #333C87, #6D6DF9)", display: "flex", flexDirection: "column", justifyContent: "space-between", padding: "24px 0", position: "fixed", top: 0, left: 0, bottom: 0, zIndex: 100 },
  sidebarTop: { display: "flex", flexDirection: "column", gap: 32 },
  logoRow: { display: "flex", alignItems: "center", gap: 10, padding: "0 20px" },
  logoCircle: { width: 40, height: 40, borderRadius: 10, backgroundColor: "rgba(255,255,255,0.15)", display: "flex", alignItems: "center", justifyContent: "center" },
  logoText: { fontFamily: "'Montserrat', sans-serif", fontWeight: 700, fontSize: 18, color: "#fff" },
  logoSub: { fontFamily: "'Inter', sans-serif", fontWeight: 300, fontSize: 11, color: "rgba(255,255,255,0.7)" },
  nav: { display: "flex", flexDirection: "column", gap: 2 },
  navItem: { display: "flex", alignItems: "center", gap: 12, padding: "12px 20px", border: "none", backgroundColor: "transparent", color: "#ffffffd9", cursor: "pointer", fontSize: 14, fontFamily: "'Inter', sans-serif", fontWeight: 500, width: "100%", textAlign: "left", borderLeft: "3px solid transparent", transition: "all 0.15s" },
  navItemActive: { backgroundColor: "rgba(255,255,255,0.15)", color: "#ffffff", borderLeft: "3px solid #fff", fontWeight: 600 },
  badge: { marginLeft: "auto", backgroundColor: "#EF4444", color: "#fff", fontSize: 11, fontWeight: 700, borderRadius: 10, padding: "2px 8px", fontFamily: "'Montserrat', sans-serif" },
  sidebarBottom: { padding: "0 20px" },
  divider: { height: 1, backgroundColor: "rgba(255,255,255,0.2)", marginBottom: 16 },
  logoutBtn: { display: "flex", alignItems: "center", gap: 12, padding: "10px 0", border: "none", backgroundColor: "transparent", color: "rgba(255,255,255,0.7)", cursor: "pointer", fontSize: 14, fontFamily: "'Inter', sans-serif", width: "100%" },
  /* Main */
  mainArea: { marginLeft: 220, flex: 1, display: "flex", flexDirection: "column" },
  header: { display: "flex", justifyContent: "space-between", alignItems: "center", padding: "16px 32px", backgroundColor: "#fff", borderBottom: "1px solid #CBD5E1" },
  headerTitle: { margin: 0, fontSize: 20, fontWeight: 600, color: "#1E293B", fontFamily: "'Inter', sans-serif" },
  headerRight: { display: "flex", alignItems: "center", gap: 12 },
  headerInfo: { display: "flex", flexDirection: "column", alignItems: "flex-end" },
  headerName: { fontSize: 13, fontWeight: 600, color: "#1E293B" },
  headerRole: { fontSize: 11, color: "#64748B", fontWeight: 300 },
  headerAvatar: { width: 38, height: 38, borderRadius: "50%", backgroundColor: "#2563EB", display: "flex", alignItems: "center", justifyContent: "center", color: "#fff", fontSize: 13, fontWeight: 700, fontFamily: "'Montserrat', sans-serif" },
  content: { padding: 24, flex: 1 },
};
