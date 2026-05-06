import { useState } from "react";
import { useNavigate, useSearchParams, Link } from "react-router-dom";
import api from "../services/api";

export default function ResetPassword() {
  const [searchParams]                  = useSearchParams();
  const token                           = searchParams.get("token") || "";
  const navigate                        = useNavigate();

  const [nuevaPassword,    setNueva]    = useState("");
  const [confirmar,        setConfirmar] = useState("");
  const [error,            setError]    = useState("");
  const [cargando,         setCargando] = useState(false);

  const validate = () => {
    if (!token)                          return "Token inválido o faltante en la URL";
    if (nuevaPassword.length < 8)        return "La contraseña debe tener al menos 8 caracteres";
    if (nuevaPassword !== confirmar)     return "Las contraseñas no coinciden";
    return null;
  };

  const handleSubmit = async (e) => {
    e.preventDefault();
    const err = validate();
    if (err) return setError(err);

    setError("");
    setCargando(true);
    try {
      await api.post("/api/auth/reset-password", { token, nuevaPassword });
      navigate("/", { state: { mensaje: "Contraseña actualizada. Inicia sesión." } });
    } catch (e) {
      setError(e.response?.data?.message || "Error al restablecer la contraseña");
    } finally {
      setCargando(false);
    }
  };

  return (
    <div style={styles.container}>
      <div style={styles.card}>
        <h1 style={styles.titulo}>CIVICTRACKIO</h1>
        <p style={styles.subtitulo}>Nueva contraseña</p>

        {!token && (
          <p style={styles.errorMsg}>
            Enlace inválido. Solicita uno nuevo desde la pantalla de login.
          </p>
        )}

        <form onSubmit={handleSubmit}>
          <div style={styles.fieldGroup}>
            <label style={styles.label}>Nueva contraseña</label>
            <input
              type="password"
              value={nuevaPassword}
              onChange={(e) => setNueva(e.target.value)}
              placeholder="Mínimo 8 caracteres"
              style={styles.input}
            />
          </div>

          <div style={styles.fieldGroup}>
            <label style={styles.label}>Confirmar contraseña</label>
            <input
              type="password"
              value={confirmar}
              onChange={(e) => setConfirmar(e.target.value)}
              placeholder="Repite la contraseña"
              style={styles.input}
            />
          </div>

          {error && <p style={styles.errorMsg}>{error}</p>}

          <button type="submit" disabled={cargando || !token} style={styles.btn}>
            {cargando ? "Guardando..." : "Cambiar contraseña"}
          </button>
        </form>

        <Link to="/" style={styles.link}>Volver al login</Link>
      </div>
    </div>
  );
}

const styles = {
  container: {
    minHeight: "100vh", display: "flex",
    alignItems: "center", justifyContent: "center",
    backgroundColor: "#f1f5f9",
  },
  card: {
    backgroundColor: "#fff", padding: "40px",
    borderRadius: "16px", width: "100%", maxWidth: "400px",
    boxShadow: "0 4px 24px rgba(0,0,0,0.08)", textAlign: "center",
  },
  titulo: { margin: "0 0 4px", fontSize: "22px", color: "#1e293b", fontWeight: "700" },
  subtitulo: { margin: "0 0 24px", color: "#64748b", fontSize: "14px" },
  fieldGroup: { textAlign: "left", marginBottom: "16px" },
  label: { display: "block", fontSize: "13px", color: "#64748b", marginBottom: "6px" },
  input: {
    width: "100%", padding: "10px 12px", borderRadius: "8px",
    border: "1px solid #cbd5e1", fontSize: "14px",
    boxSizing: "border-box",
  },
  errorMsg: { color: "#ef4444", fontSize: "13px", margin: "0 0 12px" },
  btn: {
    width: "100%", padding: "12px", borderRadius: "8px",
    backgroundColor: "#2563eb", color: "#fff",
    border: "none", cursor: "pointer", fontSize: "14px",
    fontWeight: "600", marginBottom: "16px",
  },
  link: { color: "#2563eb", fontSize: "13px", textDecoration: "none" },
};
