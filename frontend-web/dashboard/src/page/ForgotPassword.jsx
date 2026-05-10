import { useState } from "react";
import { Link } from "react-router-dom";
import api from "../services/api";

export default function ForgotPassword() {
  const [correo,    setCorreo]    = useState("");
  const [enviado,   setEnviado]   = useState(false);
  const [error,     setError]     = useState("");
  const [cargando,  setCargando]  = useState(false);

  const handleSubmit = async (e) => {
    e.preventDefault();
    setError("");

    if (!correo.trim() || !/^[^\s@]+@[^\s@]+\.[^\s@]+$/.test(correo))
      return setError("Ingresa un correo válido");

    setCargando(true);
    try {
      await api.post("/api/auth/forgot-password", { correo: correo.trim(), plataforma: "web" });
      setEnviado(true);
    } catch {
      setError("Error al procesar la solicitud. Intenta de nuevo.");
    } finally {
      setCargando(false);
    }
  };

  if (enviado) {
    return (
      <div style={styles.container}>
        <div style={styles.card}>
          <div style={styles.iconOk}>✓</div>
          <h2 style={styles.titulo}>Revisa tu correo</h2>
          <p style={styles.texto}>
            Si el correo está registrado, recibirás un enlace para restablecer tu contraseña.
          </p>
          <Link to="/" style={styles.link}>Volver al login</Link>
        </div>
      </div>
    );
  }

  return (
    <div style={styles.container}>
      <div style={styles.card}>
        <h1 style={styles.titulo}>CIVICTRACKIO</h1>
        <p style={styles.subtitulo}>Recuperar contraseña</p>

        <form onSubmit={handleSubmit}>
          <div style={styles.fieldGroup}>
            <label style={styles.label}>Correo electrónico</label>
            <input
              type="email"
              value={correo}
              onChange={(e) => setCorreo(e.target.value)}
              placeholder="admin@civictrackio.com"
              style={styles.input}
            />
          </div>

          {error && <p style={styles.errorMsg}>{error}</p>}

          <button type="submit" disabled={cargando} style={styles.btn}>
            {cargando ? "Enviando..." : "Enviar enlace"}
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
  iconOk: {
    width: "56px", height: "56px", borderRadius: "50%",
    backgroundColor: "#dcfce7", color: "#166534",
    fontSize: "24px", display: "flex",
    alignItems: "center", justifyContent: "center",
    margin: "0 auto 16px",
  },
  titulo: { margin: "0 0 4px", fontSize: "22px", color: "#1e293b", fontWeight: "700" },
  subtitulo: { margin: "0 0 24px", color: "#64748b", fontSize: "14px" },
  texto: { color: "#64748b", fontSize: "14px", lineHeight: "1.6", margin: "0 0 24px" },
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
