import { useState, useEffect, useRef } from "react";
import { useNavigate, Link } from "react-router-dom";
import { loginAdmin } from "../services/authService.js";
import api from "../services/api.js";
import "./LoginAdmin.css";

export default function LoginAdmin() {
  var navigate = useNavigate();
  var [correo, setCorreo] = useState("");
  var [password, setPassword] = useState("");
  var [showPassword, setShowPassword] = useState(false);
  var [errors, setErrors] = useState({});
  var [serverError, setServerError] = useState("");
  var [isLoading, setIsLoading] = useState(false);
  var passwordRef = useRef(null);

  // Stats dinámicos
  var [stats, setStats] = useState({ reportes: 0, usuarios: 0, corregimientos: 0, comunas: 12 });

  useEffect(function () {
    async function cargarStats() {
      try {
        var res = await api.get("/api/reportes/stats-login");
        if (res.data && res.data.data) setStats(res.data.data);
      } catch (_) {}
    }
    cargarStats();
  }, []);

  var validate = function () {
    var e = {};
    if (!correo.trim()) e.correo = "El correo es obligatorio";
    else if (!/^[^\s@]+@[^\s@]+\.[^\s@]+$/.test(correo)) e.correo = "Correo inválido";
    if (!password) e.password = "La contraseña es obligatoria";
    else if (password.length < 6) e.password = "Mínimo 6 caracteres";
    return e;
  };

  var handleSubmit = async function (e) {
    e.preventDefault();
    setServerError("");
    var v = validate();
    if (Object.keys(v).length > 0) { setErrors(v); return; }
    setErrors({});
    setIsLoading(true);
    try {
      await loginAdmin(correo.trim().toLowerCase(), password);
      navigate("/dashboard");
    } catch (err) {
      setServerError(err.response?.data?.message || "Error al iniciar sesión");
    } finally {
      setIsLoading(false);
    }
  };

  return (
    <div className="login-layout">
      {/* Left column */}
      <div className="login-left">
        <div className="login-left-deco1" />
        <div className="login-left-deco2" />
        <div className="login-left-content">
          <div className="login-brand">
            <img src="/assets/Logo_CivicTrackIO_Color.png" alt="CivicTrackIO" className="login-brand-logo" />
            <span className="login-brand-text">Civic<span style={{ fontWeight: 400 }}>Track</span><span style={{ color: "#3B82F6" }}>IO</span></span>
          </div>
          <div className="login-hero">
            <h1 className="login-hero-title">{"Panel de\nAdministración"}</h1>
            <p className="login-hero-sub">Monitorea incidentes, gestiona reportes y analiza estadísticas de seguridad en Pasto.</p>
            <div className="login-stats">
              <StatCard target={stats.reportes} label="Reportes activos" />
              <StatCard target={stats.usuarios} label="Usuarios" />
              <StatCard target={stats.corregimientos} label="Corregimientos" />
              <StatCard target={stats.comunas} label="Comunas" />
            </div>
          </div>
        </div>
      </div>

      {/* Right column */}
      <div className="login-right">
        <div className="login-form-wrap">
          <div className="login-badge-admin">
            <svg width="12" height="12" viewBox="0 0 24 24" fill="none" stroke="#1E3A8A" strokeWidth="2"><path d="M12 22s8-4 8-10V5l-8-3-8 3v7c0 6 8 10 8 10z"/></svg>
            <span>Acceso administrador</span>
          </div>
          <h2 className="login-form-title">Bienvenido de nuevo</h2>
          <p className="login-form-sub">Ingresa tus credenciales para continuar</p>

          <form onSubmit={handleSubmit} noValidate>
            <div className="login-field">
              <label htmlFor="correo">CORREO</label>
              <div className="login-input-wrap">
                <svg className="login-input-icon" width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="#94A3B8" strokeWidth="2"><path d="M4 4h16c1.1 0 2 .9 2 2v12c0 1.1-.9 2-2 2H4c-1.1 0-2-.9-2-2V6c0-1.1.9-2 2-2z"/><polyline points="22,6 12,13 2,6"/></svg>
                <input
                  id="correo"
                  type="email"
                  value={correo}
                  onChange={function (e) { setCorreo(e.target.value); }}
                  onKeyDown={function (e) { if (e.key === "Enter") { e.preventDefault(); passwordRef.current?.focus(); } }}
                  placeholder="admin@civictrackio.com"
                  className={errors.correo ? "login-input login-input-err" : "login-input"}
                />
              </div>
              {errors.correo && <span className="login-err">{errors.correo}</span>}
            </div>
            <div className="login-field">
              <label htmlFor="password">CONTRASEÑA</label>
              <div className="login-input-wrap">
                <svg className="login-input-icon" width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="#94A3B8" strokeWidth="2"><rect x="3" y="11" width="18" height="11" rx="2"/><path d="M7 11V7a5 5 0 0 1 10 0v4"/></svg>
                <input
                  id="password"
                  ref={passwordRef}
                  type={showPassword ? "text" : "password"}
                  value={password}
                  onChange={function (e) { setPassword(e.target.value); }}
                  placeholder="••••••••"
                  className={errors.password ? "login-input login-input-err login-input-password" : "login-input login-input-password"}
                />
                <button type="button" className="login-eye-btn" onClick={function () { setShowPassword(!showPassword); }} tabIndex={-1} aria-label={showPassword ? "Ocultar contraseña" : "Mostrar contraseña"}>
                  {showPassword ? (
                    <svg width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="#64748B" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round"><path d="M17.94 17.94A10.07 10.07 0 0 1 12 20c-7 0-11-8-11-8a18.45 18.45 0 0 1 5.06-5.94"/><path d="M9.9 4.24A9.12 9.12 0 0 1 12 4c7 0 11 8 11 8a18.5 18.5 0 0 1-2.16 3.19"/><line x1="1" y1="1" x2="23" y2="23"/></svg>
                  ) : (
                    <svg width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="#64748B" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round"><path d="M1 12s4-8 11-8 11 8 11 8-4 8-11 8-11-8-11-8z"/><circle cx="12" cy="12" r="3"/></svg>
                  )}
                </button>
              </div>
              {errors.password && <span className="login-err">{errors.password}</span>}
            </div>
            {serverError && <p className="login-server-err">{serverError}</p>}
            <button type="submit" disabled={isLoading} className="login-btn">{isLoading ? "Ingresando..." : "Iniciar sesión"}</button>
            <div style={{textAlign:"center",marginTop:"12px"}}>
              <Link to="/forgot-password" style={{color:"#2563eb",fontSize:"13px",textDecoration:"none"}}>
                ¿Olvidaste tu contraseña?
              </Link>
            </div>
          </form>
          <p className="login-footer">Solo para administradores autorizados del sistema CivicTrackIO</p>
        </div>
      </div>
    </div>
  );
}

function StatCard(props) {
  var ref = useRef(null);
  var [val, setVal] = useState(0);
  useEffect(function () {
    var start = performance.now();
    var dur = 1200;
    var target = props.target || 0;
    function tick(now) {
      var t = Math.min((now - start) / dur, 1);
      var ease = 1 - Math.pow(1 - t, 3);
      setVal(Math.round(ease * target));
      if (t < 1) requestAnimationFrame(tick);
    }
    requestAnimationFrame(tick);
  }, [props.target]);
  return (
    <div className="login-stat-card">
      <span className="login-stat-num" ref={ref}>{val}</span>
      <span className="login-stat-label">{props.label}</span>
    </div>
  );
}
