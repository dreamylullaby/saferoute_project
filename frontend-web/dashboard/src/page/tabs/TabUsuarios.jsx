import { useState, useEffect } from "react";
import api from "../../services/api";

export default function TabUsuarios({ onCountChange }) {
  const [usuarios, setUsuarios] = useState([]);
  const [cargando, setCargando] = useState(true);
  const [detalle, setDetalle] = useState(null);
  const [modalType, setModalType] = useState(null);

  const cargar = async () => {
    setCargando(true);
    try {
      const { data } = await api.get("/api/reportes/admin/resumen");
      // Intentar obtener usuarios del endpoint admin si existe
      try {
        const res = await api.get("/api/auth/admin/usuarios");
        setUsuarios(res.data.data || []);
        onCountChange?.(res.data.data?.length || 0);
      } catch {
        // Fallback: mostrar info del resumen
        setUsuarios([]);
        onCountChange?.(0);
      }
    } catch (e) {
      console.error(e);
    } finally {
      setCargando(false);
    }
  };

  useEffect(() => { cargar(); }, []);

  const getIniciales = (nombre) => {
    if (!nombre) return "?";
    const partes = nombre.trim().split(/\s+/);
    if (partes.length >= 2) return (partes[0][0] + partes[1][0]).toUpperCase();
    return nombre.substring(0, 2).toUpperCase();
  };

  const getColor = (index) => {
    const colores = ["#B91C1C", "#9D174D", "#2563EB", "#059669", "#D946EF", "#F97316", "#8A2BE2", "#1E3A8A"];
    return colores[index % colores.length];
  };

  return (
    <div style={styles.card}>
      {cargando ? (
        <p style={{ color: "#64748b", textAlign: "center", padding: "40px" }}>Cargando...</p>
      ) : usuarios.length === 0 ? (
        <p style={{ color: "#64748b", textAlign: "center", padding: "40px" }}>
          El endpoint de listado de usuarios aún no está disponible. Se conectará próximamente.
        </p>
      ) : (
        <table style={styles.table}>
          <thead>
            <tr>
              {["USUARIO", "EMAIL", "ROL", "ACCIONES"].map(h => (
                <th key={h} style={styles.th}>{h}</th>
              ))}
            </tr>
          </thead>
          <tbody>
            {usuarios.map((u, i) => (
              <tr key={u.id} style={styles.tr}>
                <td style={styles.td}>
                  <div style={styles.userCell}>
                    <div style={{ ...styles.avatar, backgroundColor: getColor(i) }}>
                      {getIniciales(u.username)}
                    </div>
                    <span>{u.username || "Sin nombre"}</span>
                  </div>
                </td>
                <td style={styles.td}>{u.correo}</td>
                <td style={styles.td}>
                  <span style={{
                    ...styles.rolBadge,
                    backgroundColor: u.rol === "admin" ? "#DBEAFE" : "#F1F5F9",
                    color: u.rol === "admin" ? "#2563EB" : "#64748B",
                  }}>
                    {u.rol === "admin" ? "Admin" : "Usuario"}
                  </span>
                </td>
                <td style={styles.td}>
                  <div style={styles.acciones}>
                    <button onClick={() => { setDetalle(u); setModalType("ver"); }} style={styles.btnAccion} title="Ver">👁️</button>
                    <button onClick={() => { setDetalle(u); setModalType("editar"); }} style={{ ...styles.btnAccion, color: "#2563EB" }} title="Editar">✏️</button>
                    <button onClick={() => { setDetalle(u); setModalType("eliminar"); }} style={{ ...styles.btnAccion, color: "#EF4444" }} title="Eliminar">🗑️</button>
                  </div>
                </td>
              </tr>
            ))}
          </tbody>
        </table>
      )}

      {/* Modal Ver */}
      {detalle && modalType === "ver" && (
        <ModalOverlay onClose={() => setDetalle(null)}>
          <h2 style={styles.modalTitle}>Detalle del Usuario</h2>
          <Campo label="ID" valor={detalle.id} />
          <Campo label="Username" valor={detalle.username} />
          <Campo label="Correo" valor={detalle.correo} />
          <Campo label="Rol" valor={detalle.rol} />
          <Campo label="Auth provider" valor={detalle.auth_provider} />
          <Campo label="Estado" valor={detalle.estado} />
          <Campo label="Miembro desde" valor={detalle.fecha_creacion ? new Date(detalle.fecha_creacion).toLocaleDateString("es-CO") : null} />
        </ModalOverlay>
      )}

      {/* Modal Editar — placeholder */}
      {detalle && modalType === "editar" && (
        <ModalOverlay onClose={() => setDetalle(null)}>
          <h2 style={styles.modalTitle}>Editar Usuario</h2>
          <p style={{ color: "#64748b", fontSize: "14px" }}>
            Los endpoints de edición de usuarios se conectarán próximamente.
          </p>
        </ModalOverlay>
      )}

      {/* Modal Eliminar — placeholder */}
      {detalle && modalType === "eliminar" && (
        <ModalOverlay onClose={() => setDetalle(null)}>
          <h2 style={{ ...styles.modalTitle, color: "#EF4444" }}>Bloquear Usuario</h2>
          <p style={{ color: "#64748b", fontSize: "14px", marginBottom: "16px" }}>
            ¿Estás seguro de que deseas bloquear a <strong>{detalle.username}</strong>?
          </p>
          <div style={{ display: "flex", gap: "8px" }}>
            <button onClick={() => setDetalle(null)} style={styles.btnCancelar}>Cancelar</button>
            <button onClick={() => { /* TODO: conectar PATCH estado */ setDetalle(null); }} style={styles.btnEliminar}>Confirmar</button>
          </div>
        </ModalOverlay>
      )}
    </div>
  );
}

function ModalOverlay({ children, onClose }) {
  return (
    <div style={styles.overlay} onClick={onClose}>
      <div style={styles.modal} onClick={(e) => e.stopPropagation()}>
        <button style={styles.modalClose} onClick={onClose}>✕</button>
        {children}
      </div>
    </div>
  );
}

function Campo({ label, valor }) {
  if (!valor) return null;
  return (
    <div style={styles.campo}>
      <span style={styles.campoLabel}>{label}</span>
      <span style={styles.campoValor}>{valor}</span>
    </div>
  );
}

const styles = {
  card: {
    backgroundColor: "#fff", borderRadius: "12px",
    boxShadow: "0 1px 4px rgba(0,0,0,0.06)", overflow: "hidden",
  },
  table: { width: "100%", borderCollapse: "collapse", fontSize: "13px" },
  th: {
    padding: "12px 16px", textAlign: "left",
    color: "#64748b", fontWeight: "600", fontSize: "11px",
    borderBottom: "2px solid #e2e8f0", textTransform: "uppercase",
    letterSpacing: "0.5px",
  },
  tr: { borderBottom: "1px solid #f1f5f9" },
  td: { padding: "12px 16px", color: "#1e293b" },
  userCell: { display: "flex", alignItems: "center", gap: "10px" },
  avatar: {
    width: "32px", height: "32px", borderRadius: "50%",
    display: "flex", alignItems: "center", justifyContent: "center",
    color: "#fff", fontSize: "11px", fontWeight: "700",
  },
  rolBadge: {
    padding: "4px 10px", borderRadius: "12px",
    fontSize: "11px", fontWeight: "600",
  },
  acciones: { display: "flex", gap: "4px" },
  btnAccion: {
    width: "32px", height: "32px", borderRadius: "6px",
    border: "1px solid #e2e8f0", backgroundColor: "#fff",
    cursor: "pointer", fontSize: "14px",
    display: "flex", alignItems: "center", justifyContent: "center",
  },
  overlay: {
    position: "fixed", inset: 0, backgroundColor: "rgba(0,0,0,0.5)",
    display: "flex", alignItems: "center", justifyContent: "center", zIndex: 1000,
  },
  modal: {
    backgroundColor: "#fff", borderRadius: "12px", width: "100%", maxWidth: "480px",
    maxHeight: "85vh", overflowY: "auto", padding: "24px", position: "relative",
    boxShadow: "0 20px 60px rgba(0,0,0,0.3)",
  },
  modalClose: {
    position: "absolute", top: "16px", right: "16px",
    background: "none", border: "none", fontSize: "18px",
    cursor: "pointer", color: "#64748b",
  },
  modalTitle: { margin: "0 0 16px", fontSize: "18px", color: "#1e293b" },
  campo: {
    display: "flex", justifyContent: "space-between",
    padding: "8px 0", borderBottom: "1px solid #f1f5f9",
  },
  campoLabel: { color: "#64748b", fontSize: "13px" },
  campoValor: { color: "#1e293b", fontSize: "13px", fontWeight: "500", textAlign: "right", maxWidth: "60%" },
  btnCancelar: {
    flex: 1, padding: "10px", borderRadius: "8px",
    backgroundColor: "#f1f5f9", color: "#64748b",
    border: "1px solid #cbd5e1", cursor: "pointer", fontSize: "13px",
  },
  btnEliminar: {
    flex: 1, padding: "10px", borderRadius: "8px",
    backgroundColor: "#EF4444", color: "#fff",
    border: "none", cursor: "pointer", fontSize: "13px", fontWeight: "600",
  },
};
