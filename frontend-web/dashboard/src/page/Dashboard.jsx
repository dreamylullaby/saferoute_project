import { useNavigate } from "react-router-dom";

/**
 * Página principal del panel de administración.
 * Solo accesible si hay una sesión de administrador en sessionStorage.
 * Muestra el nombre del admin y permite cerrar sesión.
 */
export default function Dashboard() {
  const navigate = useNavigate();
  const admin = JSON.parse(sessionStorage.getItem("admin") || "{}");

  /**
   * Elimina la sesión del administrador y redirige al login.
   */
  const cerrarSesion = () => {
    sessionStorage.removeItem("admin");
    navigate("/");
  };

  return (
    <div style={{ padding: "40px", fontFamily: "sans-serif" }}>
      <div style={{ display: "flex", justifyContent: "space-between", alignItems: "center" }}>
        <h1>SafeRoute — Dashboard</h1>
        <button
          onClick={cerrarSesion}
          style={{
            padding: "8px 16px",
            backgroundColor: "#ef4444",
            color: "white",
            border: "none",
            borderRadius: "8px",
            cursor: "pointer"
          }}
        >
          Cerrar sesión
        </button>
      </div>
      <p>Bienvenido, <strong>{admin.username}</strong></p>
    </div>
  );
}
