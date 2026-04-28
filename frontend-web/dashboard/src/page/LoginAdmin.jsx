import { useState, useEffect, useRef } from "react";
import { useNavigate, Link } from "react-router-dom";
import { loginAdmin } from "../services/authService.js";
import "./LoginAdmin.css";

export default function LoginAdmin() {
  var navigate = useNavigate();
  var [correo, setCorreo] = useState("");
  var [password, setPassword] = useState("");
  var [errors, setErrors] = useState({});
  var [serverError, setServerError] = useState("");
  var [isLoading, setIsLoading] = useState(false);
  var activos = 22; /* Valor de referencia — se actualizará al ingresar al dashboard */

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
    try { await loginAdmin(correo, password); navigate("/dashboard"); }
    catch (err) { setServerError(err.response?.data?.message || "Error al iniciar sesión"); }
    finally { setIsLoading(false); }
  };

  return (
    <div className="login-layout">
      {/* Left column */}
      <div className="login-left">
        <div className="login-left-deco1" />
        <div className="login-left-deco2" />
        <div className="login-left-content">
          <div className="login-brand">
            <div className="login-brand-icon">
              <svg width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="#fff" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round"><path d="M12 22s8-4 8-10V5l-8-3-8 3v7c0 6 8 10 8 10z"/></svg>
            </div>
            <span className="login-brand-text">SafeRoute</span>
          </div>
          <div className="login-hero">
            <h1 className="login-hero-title">{"Panel de\nAdministración"}</h1>
            <p className="login-hero-sub">Monitorea incidentes, gestiona reportes y analiza estadísticas de seguridad en Pasto.</p>
            <div className="login-stats">
              <StatCard target={activos} label="Reportes activos" />
              <StatCard target={12} label="Comunas" />
              <StatCard target={4} label="Tipos de hurto" />
            </div>
          </div>
          <div className="login-dots">
            <div className="login-dot login-dot-active" />
            <div className="login-dot" />
            <div className="login-dot" />
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
                <input id="correo" type="email" value={correo} onChange={function (e) { setCorreo(e.target.value); }} placeholder="admin@saferoute.com" className={errors.correo ? "login-input login-input-err" : "login-input"} />
              </div>
              {errors.correo && <span className="login-err">{errors.correo}</span>}
            </div>
            <div className="login-field">
              <label htmlFor="password">CONTRASEÑA</label>
              <div className="login-input-wrap">
                <svg className="login-input-icon" width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="#94A3B8" strokeWidth="2"><rect x="3" y="11" width="18" height="11" rx="2"/><path d="M7 11V7a5 5 0 0 1 10 0v4"/></svg>
                <input id="password" type="password" value={password} onChange={function (e) { setPassword(e.target.value); }} placeholder="••••••••" className={errors.password ? "login-input login-input-err" : "login-input"} />
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
          <p className="login-footer">Solo para administradores autorizados del sistema SafeRoute</p>
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
