import { useState, useEffect } from "react";
import api from "../../services/api.js";

// Traducciones básicas
var LANG = {
  es: { info: "Información de la cuenta", edit: "Editar perfil", security: "Seguridad", prefs: "Preferencias", darkMode: "Modo oscuro", darkDesc: "Cambia la apariencia del panel", language: "Idioma", save: "Guardar", changePwd: "Cambiar contraseña", currentPwd: "Contraseña actual", newPwd: "Nueva contraseña", confirmPwd: "Confirmar nueva contraseña", email: "Correo electrónico", role: "Rol", provider: "Proveedor de autenticación", memberSince: "Miembro desde", notifications: "Notificaciones", active: "Activas", disabled: "Desactivadas", username: "Nombre de usuario", userId: "ID de usuario", admin: "Administrador", user: "Usuario" },
  en: { info: "Account Information", edit: "Edit Profile", security: "Security", prefs: "Preferences", darkMode: "Dark Mode", darkDesc: "Changes the panel appearance", language: "Language", save: "Save", changePwd: "Change Password", currentPwd: "Current password", newPwd: "New password", confirmPwd: "Confirm new password", email: "Email", role: "Role", provider: "Auth provider", memberSince: "Member since", notifications: "Notifications", active: "Active", disabled: "Disabled", username: "Username", userId: "User ID", admin: "Administrator", user: "User" },
};

export default function TabPerfil() {
  var [perfil, setPerfil] = useState(null);
  var [cargando, setCargando] = useState(true);
  var [editUsername, setEditUsername] = useState("");
  var [msg, setMsg] = useState("");
  var [darkMode, setDarkMode] = useState(function () { return localStorage.getItem("admin_dark") === "true"; });
  var [idioma, setIdioma] = useState(function () { return localStorage.getItem("admin_lang") || "es"; });
  var t = LANG[idioma] || LANG.es;

  useEffect(function () {
    api.get("/api/perfil").then(function (res) {
      setPerfil(res.data.data);
      setEditUsername(res.data.data.username || "");
    }).catch(function () {}).finally(function () { setCargando(false); });
  }, []);

  useEffect(function () {
    localStorage.setItem("admin_dark", darkMode);
    document.documentElement.setAttribute("data-theme", darkMode ? "dark" : "light");
  }, [darkMode]);

  useEffect(function () {
    localStorage.setItem("admin_lang", idioma);
  }, [idioma]);

  function guardar() {
    if (!editUsername.trim() || editUsername.trim().length < 3) { setMsg("err:Mínimo 3 caracteres"); return; }
    api.put("/api/perfil", { username: editUsername.trim() }).then(function (res) {
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
              <span style={{ backgroundColor: "rgba(255,255,255,0.1)", color: "rgba(255,255,255,0.8)", padding: "3px 14px", borderRadius: 99, fontSize: 11, fontWeight: 400 }}>{Array.isArray(perfil.auth_provider) ? perfil.auth_provider.join(" + ") : perfil.auth_provider}</span>
            </div>
          </div>
        </div>
      </div>

      <div style={{ display: "grid", gridTemplateColumns: "1fr 1fr", gap: 20 }}>
        {/* Info de la cuenta + Preferencias */}
        <div style={{ display: "flex", flexDirection: "column", gap: 20 }}>
          <div style={CARD}>
            <h3 style={TITLE}>{t.info}</h3>
            <Row label={t.email} value={<span style={{ display: "flex", alignItems: "center", gap: 6 }}><span style={{ overflow: "hidden", textOverflow: "ellipsis", whiteSpace: "nowrap" }}>{perfil.correo}</span><button onClick={function () { navigator.clipboard.writeText(perfil.correo); }} style={{ background: "none", border: "none", cursor: "pointer", padding: 0, color: "#64748B", flexShrink: 0 }} title="Copiar correo"><svg width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2"><rect x="9" y="9" width="13" height="13" rx="2"/><path d="M5 15H4a2 2 0 0 1-2-2V4a2 2 0 0 1 2-2h9a2 2 0 0 1 2 2v1"/></svg></button></span>} />
            <Row label={t.role} value={perfil.rol === "admin" ? t.admin : t.user} />
            <Row label={t.provider} value={Array.isArray(perfil.auth_provider) ? perfil.auth_provider.map(function(p) { return p === "google" ? "Google" : "Local"; }).join(" + ") : perfil.auth_provider} />
            <Row label={t.memberSince} value={fmtFecha(perfil.fecha_creacion)} />
            <Row label={t.notifications} value={perfil.notificaciones_activas ? t.active : t.disabled} />
            <div style={{ marginTop: 12, backgroundColor: "#F8FAFC", borderRadius: 8, padding: "10px 14px", border: "0.5px solid #E2E8F0" }}>
              <span style={{ fontSize: 11, color: "#64748B", display: "block", marginBottom: 2 }}>{t.userId}</span>
              <span style={{ fontSize: 11, color: "#1E293B", fontFamily: "monospace", wordBreak: "break-all" }}>{perfil.id}</span>
            </div>
          </div>

          <div style={CARD}>
            <h3 style={TITLE}>{t.prefs}</h3>
            <div style={{ display: "flex", alignItems: "center", justifyContent: "space-between", padding: "12px 0", borderBottom: "0.5px solid #F1F5F9" }}>
              <div>
                <span style={{ fontSize: 13, color: "#1E293B", fontWeight: 500, display: "block" }}>{t.darkMode}</span>
                <span style={{ fontSize: 12, color: "#64748B", fontWeight: 300 }}>{t.darkDesc}</span>
              </div>
              <button onClick={function () { setDarkMode(!darkMode); }} style={{ width: 44, height: 24, borderRadius: 12, border: "none", backgroundColor: darkMode ? "#2563EB" : "#CBD5E1", cursor: "pointer", position: "relative", transition: "background-color 0.2s ease" }}>
                <div style={{ width: 18, height: 18, borderRadius: "50%", backgroundColor: "#fff", position: "absolute", top: 3, left: darkMode ? 23 : 3, transition: "left 0.2s ease", boxShadow: "0 1px 3px rgba(0,0,0,0.2)" }} />
              </button>
            </div>
            <div style={{ display: "flex", alignItems: "center", justifyContent: "space-between", padding: "12px 0" }}>
              <div>
                <span style={{ fontSize: 13, color: "#1E293B", fontWeight: 500, display: "block" }}>{t.language}</span>
                <span style={{ fontSize: 12, color: "#64748B", fontWeight: 300 }}>{idioma === "es" ? "Español (Colombia)" : "English"}</span>
              </div>
              <button onClick={function () { setIdioma(idioma === "es" ? "en" : "es"); }} style={{ padding: "4px 14px", borderRadius: 6, border: "1px solid #E2E8F0", backgroundColor: "#F8FAFC", color: "#1E293B", fontSize: 12, fontWeight: 500, cursor: "pointer", fontFamily: "'Inter',sans-serif" }}>
                {idioma === "es" ? "EN" : "ES"}
              </button>
            </div>
          </div>
        </div>

        {/* Editar perfil + Seguridad */}
        <div style={{ display: "flex", flexDirection: "column", gap: 20 }}>
          <div style={CARD}>
            <h3 style={TITLE}>{t.edit}</h3>
            <label style={{ fontSize: 12, color: "#64748B", fontWeight: 500, display: "block", marginBottom: 6 }}>{t.username}</label>
            <div style={{ display: "flex", gap: 8 }}>
              <input value={editUsername} onChange={function (e) { setEditUsername(e.target.value); }} style={INP} />
              <button onClick={guardar} style={{ height: 38, padding: "0 20px", borderRadius: 8, border: "none", backgroundColor: "#2563EB", color: "#fff", fontSize: 13, fontWeight: 500, cursor: "pointer", fontFamily: "'Montserrat',sans-serif", whiteSpace: "nowrap" }}>{t.save}</button>
            </div>
            {msgText && <p style={{ margin: "8px 0 0", fontSize: 12, color: isErr ? "#EF4444" : "#10B981", fontWeight: 500 }}>{msgText}</p>}
          </div>

          {/* Seguridad — Cambiar contraseña */}
          <div style={CARD}>
            <h3 style={TITLE}>{t.security}</h3>
            {(Array.isArray(perfil.auth_provider) ? !perfil.auth_provider.includes("local") : perfil.auth_provider === "google") ? (
              <div style={{ display: "flex", alignItems: "center", justifyContent: "space-between", padding: "12px 0" }}>
                <div>
                  <span style={{ fontSize: 13, color: "#1E293B", fontWeight: 500, display: "block" }}>{t.changePwd}</span>
                  <span style={{ fontSize: 12, color: "#64748B", fontWeight: 300 }}>No disponible para cuentas de Google</span>
                </div>
                <span style={{ backgroundColor: "#F1F5F9", color: "#94A3B8", padding: "3px 12px", borderRadius: 99, fontSize: 11, fontWeight: 500 }}>Google</span>
              </div>
            ) : (
              <CambiarPassword lang={t} />
            )}
          </div>
        </div>
      </div>
    </div>
  );
}

function CambiarPassword({ lang }) {
  var t = lang || LANG.es;
  var [actual, setActual] = useState("");
  var [nueva, setNueva] = useState("");
  var [confirmar, setConfirmar] = useState("");
  var [msg, setMsg] = useState("");
  var [guardando, setGuardando] = useState(false);

  function cambiar() {
    if (!actual || !nueva || !confirmar) { setMsg("err:Todos los campos son obligatorios"); return; }
    if (nueva.length < 6) { setMsg("err:La nueva contraseña debe tener al menos 6 caracteres"); return; }
    if (nueva !== confirmar) { setMsg("err:Las contraseñas no coinciden"); return; }
    setGuardando(true);
    api.put("/api/perfil/password", { passwordActual: actual, nuevaPassword: nueva })
      .then(function () { setMsg("ok:Contraseña actualizada"); setActual(""); setNueva(""); setConfirmar(""); setTimeout(function () { setMsg(""); }, 3000); })
      .catch(function (err) { setMsg("err:" + (err.response?.data?.message || "Error al cambiar contraseña")); })
      .finally(function () { setGuardando(false); });
  }

  var isErr = msg.startsWith("err:");
  var msgText = msg.replace(/^(err:|ok:)/, "");

  return (
    <div>
      <label style={{ fontSize: 12, color: "#64748B", fontWeight: 500, display: "block", marginBottom: 4 }}>{t.currentPwd}</label>
      <input type="password" value={actual} onChange={function (e) { setActual(e.target.value); }} style={{ ...INP, width: "100%", marginBottom: 10 }} />
      <label style={{ fontSize: 12, color: "#64748B", fontWeight: 500, display: "block", marginBottom: 4 }}>{t.newPwd}</label>
      <input type="password" value={nueva} onChange={function (e) { setNueva(e.target.value); }} style={{ ...INP, width: "100%", marginBottom: 10 }} />
      <label style={{ fontSize: 12, color: "#64748B", fontWeight: 500, display: "block", marginBottom: 4 }}>{t.confirmPwd}</label>
      <input type="password" value={confirmar} onChange={function (e) { setConfirmar(e.target.value); }} style={{ ...INP, width: "100%", marginBottom: 12 }} />
      <button onClick={cambiar} disabled={guardando} style={{ height: 38, padding: "0 20px", borderRadius: 8, border: "none", backgroundColor: "#2563EB", color: "#fff", fontSize: 13, fontWeight: 500, cursor: "pointer", fontFamily: "'Montserrat',sans-serif" }}>
        {guardando ? "..." : t.changePwd}
      </button>
      {msgText && <p style={{ margin: "8px 0 0", fontSize: 12, color: isErr ? "#EF4444" : "#10B981", fontWeight: 500 }}>{msgText}</p>}
    </div>
  );
}

function Row(props) {
  return (
    <div style={{ display: "flex", justifyContent: "space-between", padding: "10px 0", borderBottom: "0.5px solid #F1F5F9", gap: 12 }}>
      <span style={{ fontSize: 13, color: "#64748B", fontWeight: 400, flexShrink: 0 }}>{props.label}</span>
      <span style={{ fontSize: 13, color: "#1E293B", fontWeight: 500, textAlign: "right", overflow: "hidden", textOverflow: "ellipsis", whiteSpace: "nowrap" }}>{props.value}</span>
    </div>
  );
}

var CARD = { backgroundColor: "#fff", borderRadius: 12, padding: 24, border: "0.5px solid #CBD5E1", boxShadow: "0 1px 4px rgba(0,0,0,0.06)" };
var TITLE = { margin: "0 0 16px", fontSize: 14, fontWeight: 600, color: "#1E293B", textTransform: "uppercase", letterSpacing: 0.5 };
var INP = { flex: 1, height: 38, padding: "0 12px", borderRadius: 8, border: "0.5px solid #CBD5E1", fontSize: 13, color: "#1E293B", backgroundColor: "#F8FAFC", boxSizing: "border-box" };
