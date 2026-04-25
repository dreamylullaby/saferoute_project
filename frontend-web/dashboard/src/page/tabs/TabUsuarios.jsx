import { useState, useEffect } from "react";
import api from "../../services/api.js";

export default function TabUsuarios({ onCountChange }) {
  var [usuarios, setUsuarios] = useState([]);
  var [cargando, setCargando] = useState(true);

  useEffect(function () {
    setCargando(true);
    api.get("/api/auth/admin/usuarios")
      .then(function (res) { setUsuarios(res.data.data || []); onCountChange?.(res.data.data?.length || 0); })
      .catch(function () { setUsuarios([]); })
      .finally(function () { setCargando(false); });
  }, []); // eslint-disable-line react-hooks/exhaustive-deps

  if (cargando) return <p style={{ color: "#64748b", textAlign: "center", padding: 60, fontWeight: 300, fontFamily: "'Inter',sans-serif" }}>Cargando...</p>;

  if (usuarios.length === 0) {
    return (
      <div style={{ display: "flex", justifyContent: "center", alignItems: "center", minHeight: "60vh" }}>
        <div style={{ backgroundColor: "#fff", borderRadius: 12, border: "0.5px solid #CBD5E1", boxShadow: "0 1px 4px rgba(0,0,0,0.06)", padding: 48, textAlign: "center", maxWidth: 420 }}>
          <svg width="64" height="64" viewBox="0 0 24 24" fill="none" stroke="#CBD5E1" strokeWidth="1.5" strokeLinecap="round" strokeLinejoin="round" style={{ marginBottom: 16 }}>
            <path d="M17 21v-2a4 4 0 0 0-4-4H5a4 4 0 0 0-4 4v2"/>
            <circle cx="9" cy="7" r="4"/>
            <path d="M23 21v-2a4 4 0 0 0-3-3.87"/>
            <path d="M16 3.13a4 4 0 0 1 0 7.75"/>
          </svg>
          <h3 style={{ margin: "0 0 8px", fontSize: 18, fontWeight: 600, color: "#1E293B", fontFamily: "'Inter',sans-serif" }}>Gestión de usuarios</h3>
          <p style={{ margin: "0 0 16px", fontSize: 14, color: "#64748B", fontWeight: 400, fontFamily: "'Inter',sans-serif" }}>Esta sección estará disponible próximamente</p>
          <span style={{ display: "inline-block", backgroundColor: "#EFF6FF", color: "#2563EB", padding: "5px 16px", borderRadius: 99, fontSize: 12, fontWeight: 500, fontFamily: "'Montserrat',sans-serif" }}>En desarrollo</span>
        </div>
      </div>
    );
  }

  /* Si hay usuarios, mostrar tabla (lógica existente preservada) */
  return (
    <div style={{ backgroundColor: "#fff", borderRadius: 12, border: "0.5px solid #CBD5E1", boxShadow: "0 1px 4px rgba(0,0,0,0.06)", overflow: "hidden" }}>
      <table style={{ width: "100%", borderCollapse: "collapse", fontSize: 13, fontFamily: "'Inter',sans-serif" }}>
        <thead><tr>
          {["USUARIO", "EMAIL", "ROL", "ACCIONES"].map(function (h) { return <th key={h} style={{ padding: "12px 16px", textAlign: "left", color: "#64748B", fontWeight: 500, fontSize: 12, backgroundColor: "#F1F5F9", textTransform: "uppercase", letterSpacing: 0.5 }}>{h}</th>; })}
        </tr></thead>
        <tbody>
          {usuarios.map(function (u, i) {
            var bg = i % 2 === 0 ? "#fff" : "#F8FAFC";
            return (
              <tr key={u.id} style={{ backgroundColor: bg, borderBottom: "1px solid #F1F5F9" }}>
                <td style={{ padding: "12px 16px", color: "#1E293B" }}>
                  <div style={{ display: "flex", alignItems: "center", gap: 10 }}>
                    <div style={{ width: 32, height: 32, borderRadius: "50%", backgroundColor: "#2563EB", display: "flex", alignItems: "center", justifyContent: "center", color: "#fff", fontSize: 11, fontWeight: 700 }}>{u.username ? u.username.substring(0, 2).toUpperCase() : "?"}</div>
                    <span>{u.username || "Sin nombre"}</span>
                  </div>
                </td>
                <td style={{ padding: "12px 16px", color: "#1E293B" }}>{u.correo}</td>
                <td style={{ padding: "12px 16px" }}>
                  <span style={{ padding: "4px 10px", borderRadius: 12, fontSize: 11, fontWeight: 600, backgroundColor: u.rol === "admin" ? "#DBEAFE" : "#F1F5F9", color: u.rol === "admin" ? "#2563EB" : "#64748B" }}>{u.rol === "admin" ? "Admin" : "Usuario"}</span>
                </td>
                <td style={{ padding: "12px 16px" }}>—</td>
              </tr>
            );
          })}
        </tbody>
      </table>
    </div>
  );
}
