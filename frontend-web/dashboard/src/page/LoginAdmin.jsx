import { useState } from "react";
import { useNavigate } from "react-router-dom";
import { loginAdmin } from "../services/authService";
import "./LoginAdmin.css";

export default function LoginAdmin() {
  const navigate = useNavigate();

  const [correo, setCorreo]       = useState("");
  const [password, setPassword]   = useState("");
  const [errors, setErrors]       = useState({});
  const [serverError, setServerError] = useState("");
  const [isLoading, setIsLoading] = useState(false);

  const validate = () => {
    const newErrors = {};

    if (!correo.trim()) {
      newErrors.correo = "El correo es obligatorio";
    } else if (!/^[^\s@]+@[^\s@]+\.[^\s@]+$/.test(correo)) {
      newErrors.correo = "Correo inválido";
    }

    if (!password) {
      newErrors.password = "La contraseña es obligatoria";
    } else if (password.length < 6) {
      newErrors.password = "Mínimo 6 caracteres";
    }

    return newErrors;
  };

  const handleSubmit = async (e) => {
    e.preventDefault();
    setServerError("");

    const validationErrors = validate();
    if (Object.keys(validationErrors).length > 0) {
      setErrors(validationErrors);
      return;
    }

    setErrors({});
    setIsLoading(true);

    try {
      const data = await loginAdmin(correo, password);

      if (data.user.rol !== "admin") {
        setServerError("No tienes permisos de administrador");
        return;
      }

      sessionStorage.setItem("admin", JSON.stringify(data.user));
      navigate("/dashboard");

    } catch (err) {
      const msg = err.response?.data?.message || "Error al iniciar sesión";
      setServerError(msg);
    } finally {
      setIsLoading(false);
    }
  };

  return (
    <div className="login-container">
      <div className="login-card">
        <h1 className="login-title">SAFEROUTE</h1>
        <p className="login-subtitle">Panel de administración</p>

        <form onSubmit={handleSubmit} noValidate>

          <div className="field-group">
            <label htmlFor="correo">Correo</label>
            <input
              id="correo"
              type="email"
              value={correo}
              onChange={(e) => setCorreo(e.target.value)}
              placeholder="admin@saferoute.com"
              className={errors.correo ? "input-error" : ""}
            />
            {errors.correo && <span className="error-msg">{errors.correo}</span>}
          </div>

          <div className="field-group">
            <label htmlFor="password">Contraseña</label>
            <input
              id="password"
              type="password"
              value={password}
              onChange={(e) => setPassword(e.target.value)}
              placeholder="••••••••"
              className={errors.password ? "input-error" : ""}
            />
            {errors.password && <span className="error-msg">{errors.password}</span>}
          </div>

          {serverError && <p className="server-error">{serverError}</p>}

          <button type="submit" disabled={isLoading} className="submit-btn">
            {isLoading ? "Ingresando..." : "Iniciar sesión"}
          </button>

        </form>
      </div>
    </div>
  );
}
