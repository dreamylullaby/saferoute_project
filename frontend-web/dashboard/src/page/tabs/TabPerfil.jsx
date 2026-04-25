import { useState, useEffect } from "react";
import api from "../../services/api.js";

export default function TabPerfil() {
  var [perfil, setPerfil] = useState(null);
  var [cargando, setCargando] = useState(true);
  var [editUsername, setEditUsername] = useState("");
  var [msg, setMsg] = useState("");

  useEffect(function () {
    api.get("/api/perfil").then(function (res) {
      setPerfil(res.data.data);
      setEditUsername(res.data.data.username || "");
    }).catch(function () {}).finally(function () { setCargando(false); });
  }, []);

  function guardar() {
    if (!editUsername.trim() || editUsername.trim().length < 3) { setMsg("err:Mínimo 3 caracteres"); return; }
    api.patch("/api/perfil", { username: editUsername.trim() }).then(function (res) {
      setMsg("ok:Guardado correctamente");
      setPerfil(function (p) { return { ...p, username: res.data.data.username }; });
      var s = JSON.parse(sessionStorage.getItem("admin") || "{}");
      s.username = res.data.data.username;
      sessionStorage.setItem("admin", JSON.stringify(s));
      setTimeout(function () { setMsg(""); }, 3000);
    }).catch(function (err) { setMsg("err:" + (err.response?.data?.message || "Error al guardar")); });
  }

  function getIniciales(n) {
    if (!n) return "AD";
    var p = n.trim().split(/\s+/);
    if (p.length >= 2) return (p[0][0] + p[1][0]).toUpperCase();
    return n.substring(0, 2).toUpperCase();
  }

  function fmtFecha(f) {
    if (!f) return "—";
    return new Date(f).toLocaleDateString("es-CO", { day: "2-digit", month: "long", year: "numeric" });
  }

  if (cargando) return <p style={{ color: "#64748b", textAlign: "center", padding: 60, fontWeight: 300 }}>Cargando perfil...</p>;
  if (!perfil) return <p style={{ color: "#64748b", textAlign: "center" }}>Error al cargar perfil</p>;

  var isErr = msg.startsWith("err:");
  var msgText = msg.replace(/^(err:|ok:)/, "");

  return (
    <div style={{ maxWidth: 720, margin: "0 auto" }}>
      {/* Header card */}
      <div style={{ ...CARD, padding: 0, overflow: "hidden", marginBottom: 20 }}>
        <div style={{ background: "linear-gradient(135deg, #1E1E7C, #333C87, #6D6DF9)", padding: "36px 32px", display: "flex", alignItems: "center", gap: 20 }}>
          <div style={{ width: 80, height: 80, borderRadius: "50%", backgroundColor: "rgba(255,255,255,0.2)", display: "flex", alignItems: "center", justifyContent: "center", border: "3px solid rgba(255,255,255,0.3)", fontSize: 28, fontWeight: 700, color: "#fff", fontFamily: "'Montserrat',sans-serif", flexShrink: 0 }}>
            {getIniciales(perfil.username)}
          </div>
          <div>
            <div style={{ fontSize: 22, fontWeight: 700, color: "#fff", fontFamily: "'Montserrat',sans-serif" }}>{perfil.username || "Administrador"}</div>
            <div style={{ fontSize: 13, color: "rgba(255,255,255,0.7)", marginTop: 4 }}>{perfil.correo}</div>
            <div style={{ display: "flex", gap: 8, marginTop: 10 }}>
              <span style={{ backgroundColor: "rgba(255,255,255,0.15)", color: "#fff", padding: "3px 14px", borderRadius: 99, fontSize: 11, fontWeight: 500, fontFamily: "'Montserrat',sans-serif" }}>{perfil.rol === "admin" ? "Administrador" : "Usuario"}</span>
              <span style={{ backgroundColor: "rgba(255,255,255,0.1)", color: "rgba(255,255,255,0.8)", padding: "3px 14px", borderRadius: 99, fontSize: 11, fontWeight: 400 }}>{perfil.auth_provider === "google" ? "Google" : "Autenticación local"}</span>
            </div>
          </div>
        </div>
      </div>

      <div style={{ display: "grid", gridTemplateColumns: "1fr 1fr", gap: 20 }}>
        {/* Info de la cuenta */}
        <div style={CARD}>
          <h3 style={TITLE}>Información de la cuenta</h3>
          <Row label="Correo electrónico" value={perfil.correo} />
          <Row label="Rol" value={perfil.rol === "admin" ? "Administrador" : "Usuario"} />
          <Row label="Proveedor de autenticación" value={perfil.auth_provider === "google" ? "Google" : "Local"} />
          <Row label="Miembro desde" value={fmtFecha(perfil.fecha_creacion)} />
          <Row label="Notificaciones" value={perfil.notificaciones_activas ? "Activas" : "Desactivadas"} />
          <div style={{ marginTop: 16, backgroundColor: "#F8FAFC", borderRadius: 8, padding: "10px 14px", border: "0.5px solid #E2E8F0" }}>
            <span style={{ fontSize: 11, color: "#64748B", display: "block", marginBottom: 2 }}>ID de usuario</span>
            <span style={{ fontSize: 11, color: "#1E293B", fontFamily: "monospace", wordBreak: "break-all" }}>{perfil.id}</span>
          </div>
        </div>

        {/* Editar perfil */}
        <div style={{ display: "flex", flexDirection: "column", gap: 20 }}>
          <div style={CARD}>
            <h3 style={TITLE}>Editar perfil</h3>
            <label style={{ fontSize: 12, color: "#64748B", fontWeight: 500, display: "block", marginBottom: 6 }}>Nombre de usuario</label>
            <div style={{ display: "flex", gap: 8 }}>
              <input value={editUsername} onChange={function (e) { setEditUsername(e.target.value); }} style={INP} />
              <button onClick={guardar} style={{ height: 38, padding: "0 20px", borderRadius: 8, border: "none", backgroundColor: "#2563EB", color: "#fff", fontSize: 13, fontWeight: 500, cursor: "pointer", fontFamily: "'Montserrat',sans-serif", whiteSpace: "nowrap" }}>Guardar</button>
            </div>
            {msgText && <p style={{ margin: "8px 0 0", fontSize: 12, color: isErr ? "#EF4444" : "#10B981", fontWeight: 500 }}>{msgText}</p>}
          </div>

          {/* Próximamente */}
          <div style={CARD}>
            <h3 style={TITLE}>Seguridad</h3>
            <div style={{ display: "flex", alignItems: "center", justifyContent: "space-between", padding: "12px 0", borderBottom: "0.5px solid #F1F5F9" }}>
              <div>
                <span style={{ fontSize: 13, color: "#1E293B", fontWeight: 500, display: "block" }}>Cambiar contraseña</span>
                <span style={{ fontSize: 12, color: "#64748B", fontWeight: 300 }}>Actualiza tu contraseña de acceso</span>
              </div>
              <span style={{ backgroundColor: "#EFF6FF", color: "#2563EB", padding: "3px 12px", borderRadius: 99, fontSize: 11, fontWeight: 500, fontFamily: "'Montserrat',sans-serif" }}>Próximamente</span>
            </div>
          </div>

          <div style={CARD}>
            <h3 style={TITLE}>Preferencias</h3>
            <div style={{ display: "flex", alignItems: "center", justifyContent: "space-between", padding: "12px 0", borderBottom: "0.5px solid #F1F5F9" }}>
              <div>
                <span style={{ fontSize: 13, color: "#1E293B", fontWeight: 500, display: "block" }}>Modo oscuro</span>
                <span style={{ fontSize: 12, color: "#64748B", fontWeight: 300 }}>Cambia la apariencia del panel</span>
              </div>
              <span style={{ backgroundColor: "#EFF6FF", color: "#2563EB", padding: "3px 12px", borderRadius: 99, fontSize: 11, fontWeight: 500, fontFamily: "'Montserrat',sans-serif" }}>Próximamente</span>
            </div>
            <div style={{ display: "flex", alignItems: "center", justifyContent: "space-between", padding: "12px 0" }}>
              <div>
                <span style={{ fontSize: 13, color: "#1E293B", fontWeight: 500, display: "block" }}>Idioma</span>
                <span style={{ fontSize: 12, color: "#64748B", fontWeight: 300 }}>Español (Colombia)</span>
              </div>
              <span style={{ backgroundColor: "#EFF6FF", color: "#2563EB", padding: "3px 12px", borderRadius: 99, fontSize: 11, fontWeight: 500, fontFamily: "'Montserrat',sans-serif" }}>Próximamente</span>
            </div>
          </div>
        </div>
      </div>
    </div>
  );
}

function Row(props) {
  return (
    <div style={{ display: "flex", justifyContent: "space-between", padding: "10px 0", borderBottom: "0.5px solid #F1F5F9" }}>
      <span style={{ fontSize: 13, color: "#64748B", fontWeight: 400 }}>{props.label}</span>
      <span style={{ fontSize: 13, color: "#1E293B", fontWeight: 500, textAlign: "right", maxWidth: "60%" }}>{props.value}</span>
    </div>
  );
}

var CARD = { backgroundColor: "#fff", borderRadius: 12, padding: 24, border: "0.5px solid #CBD5E1", boxShadow: "0 1px 4px rgba(0,0,0,0.06)" };
var TITLE = { margin: "0 0 16px", fontSize: 14, fontWeight: 600, color: "#1E293B", textTransform: "uppercase", letterSpacing: 0.5 };
var INP = { flex: 1, height: 38, padding: "0 12px", borderRadius: 8, border: "0.5px solid #CBD5E1", fontSize: 13, color: "#1E293B", backgroundColor: "#F8FAFC", boxSizing: "border-box" };
