import { useState, useEffect, useCallback } from "react";
import api from "../../services/api.js";

/* Endpoints que Fer debe implementar:
 * GET    /api/auth/admin/usuarios?page=1&limit=10&estado=activo&buscar=texto
 * PATCH  /api/auth/admin/usuarios/:id/bloquear
 * PATCH  /api/auth/admin/usuarios/:id/reactivar
 */

export default function TabUsuarios({ onCountChange }) {
  var [usuarios, setUsuarios] = useState([]);
  var [cargando, setCargando] = useState(true);
  var [page, setPage] = useState(1);
  var [totalPages, setTotalPages] = useState(1);
  var [total, setTotal] = useState(0);
  var [filtroEstado, setFiltroEstado] = useState("");
  var [busqueda, setBusqueda] = useState("");
  var [busquedaInput, setBusquedaInput] = useState("");
  var [modal, setModal] = useState(null);
  var [procesando, setProcesando] = useState(false);
  var [mensaje, setMensaje] = useState(null);
  var LIMIT = 10;

  var cargar = useCallback(function () {
    setCargando(true);
    var params = { page: page, limit: LIMIT };
    if (filtroEstado) params.estado = filtroEstado;
    if (busqueda) params.q = busqueda;
    api.get("/api/admin/usuarios", { params: params })
      .then(function (res) {
        var d = res.data;
        setUsuarios(d.data || []);
        setTotal(d.total || 0);
        setTotalPages(d.totalPages || 1);
        onCountChange?.(d.total || 0);
      })
      .catch(function () { setUsuarios([]); setTotal(0); })
      .finally(function () { setCargando(false); });
  }, [page, filtroEstado, busqueda]);

  useEffect(function () { cargar(); }, [cargar]);

  useEffect(function () {
    var t = setTimeout(function () { setBusqueda(busquedaInput); setPage(1); }, 400);
    return function () { clearTimeout(t); };
  }, [busquedaInput]);

  var ejecutarAccion = function () {
    if (!modal) return;
    setProcesando(true);
    api.patch("/api/admin/usuarios/" + modal.id + "/" + modal.accion)
      .then(function () {
        setMensaje({ tipo: "ok", texto: "Usuario " + modal.accion + (modal.accion.endsWith("r") ? "" : "do") + " correctamente" });
        setModal(null);
        cargar();
      })
      .catch(function (err) {
        setMensaje({ tipo: "error", texto: err.response?.data?.message || "Error al procesar" });
        setModal(null);
      })
      .finally(function () { setProcesando(false); });
  };

  useEffect(function () {
    if (!mensaje) return;
    var t = setTimeout(function () { setMensaje(null); }, 4000);
    return function () { clearTimeout(t); };
  }, [mensaje]);

  var badgeEstado = function (estado) {
    var c = { activo: { bg: "#DCFCE7", color: "#16A34A" }, bloqueado: { bg: "#FEE2E2", color: "#DC2626" }, oculto: { bg: "#FEF3C7", color: "#D97706" }, eliminado: { bg: "#F1F5F9", color: "#94A3B8" } };
    var s = c[estado] || c.activo;
    return <span style={{ padding: "4px 10px", borderRadius: 12, fontSize: 11, fontWeight: 600, backgroundColor: s.bg, color: s.color }}>{estado.charAt(0).toUpperCase() + estado.slice(1)}</span>;
  };

  var badgeRol = function (rol) {
    var esAdmin = rol === "admin";
    return <span style={{ padding: "4px 10px", borderRadius: 12, fontSize: 11, fontWeight: 600, backgroundColor: esAdmin ? "#DBEAFE" : "#F1F5F9", color: esAdmin ? "#2563EB" : "#64748B" }}>{esAdmin ? "Admin" : "Usuario"}</span>;
  };

  var botonAccion = function (u) {
    if (u.rol === "admin") return <span style={{ color: "#CBD5E1", fontSize: 12 }}>—</span>;
    var botones = [];
    if (u.estado === "activo") {
      botones.push({ accion: "bloquear", label: "Bloquear", style: S.btnBloquear });
      botones.push({ accion: "ocultar", label: "Ocultar", style: S.btnOcultar });
    } else if (u.estado === "bloqueado" || u.estado === "oculto") {
      botones.push({ accion: "reactivar", label: "Reactivar", style: S.btnReactivar });
      botones.push({ accion: "eliminar", label: "Eliminar", style: S.btnEliminar });
    } else if (u.estado === "eliminado") {
      botones.push({ accion: "reactivar", label: "Restaurar", style: S.btnReactivar });
    }
    return (
      <div style={{ display: "flex", gap: 6 }}>
        {botones.map(function (b) {
          return <button key={b.accion} onClick={function () { setModal({ id: u.id, username: u.username, accion: b.accion }); }} style={b.style}>{b.label}</button>;
        })}
      </div>
    );
  };

  if (cargando && usuarios.length === 0) {
    return <p style={{ color: "#64748b", textAlign: "center", padding: 60, fontFamily: "'Inter',sans-serif" }}>Cargando...</p>;
  }

  return (
    <div>
      {/* Mensaje toast */}
      {mensaje && (
        <div style={{ ...S.toast, backgroundColor: mensaje.tipo === "ok" ? "#DCFCE7" : "#FEE2E2", color: mensaje.tipo === "ok" ? "#16A34A" : "#DC2626" }}>
          {mensaje.texto}
        </div>
      )}

      {/* Modal confirmación */}
      {modal && (
        <div style={S.overlay}>
          <div style={S.modal}>
            <h3 style={S.modalTitle}>Confirmar acción</h3>
            <p style={S.modalText}>
              ¿Estás seguro de <strong>{modal.accion}</strong> al usuario <strong>{modal.username || "este usuario"}</strong>?
            </p>
            <div style={S.modalButtons}>
              <button onClick={function () { setModal(null); }} style={S.btnCancelar} disabled={procesando}>Cancelar</button>
              <button onClick={ejecutarAccion} style={modal.accion === "bloquear" || modal.accion === "eliminar" ? S.btnConfirmarBloquear : modal.accion === "ocultar" ? S.btnConfirmarOcultar : S.btnConfirmarReactivar} disabled={procesando}>
                {procesando ? "Procesando..." : (modal.accion === "bloquear" ? "Bloquear" : "Reactivar")}
              </button>
            </div>
          </div>
        </div>
      )}

      {/* Controles: buscador + filtro estado */}
      <div style={S.controles}>
        <input
          type="text"
          placeholder="Buscar por nombre o correo..."
          value={busquedaInput}
          onChange={function (e) { setBusquedaInput(e.target.value); }}
          style={S.inputBuscar}
        />
        <select value={filtroEstado} onChange={function (e) { setFiltroEstado(e.target.value); setPage(1); }} style={S.selectEstado}>
          <option value="">Todos los estados</option>
          <option value="activo">Activo</option>
          <option value="bloqueado">Bloqueado</option>
          <option value="oculto">Oculto</option>
          <option value="eliminado">Eliminado</option>
        </select>
        <span style={S.totalLabel}>{total} usuario{total !== 1 ? "s" : ""}</span>
      </div>

      {/* Tabla */}
      <div style={S.tableWrapper}>
        <table style={S.table}>
          <thead>
            <tr>
              {["USUARIO", "EMAIL", "ROL", "ESTADO", "REGISTRO", "ACCIONES"].map(function (h) {
                return <th key={h} style={S.th}>{h}</th>;
              })}
            </tr>
          </thead>
          <tbody>
            {usuarios.length === 0 ? (
              <tr><td colSpan={6} style={{ padding: 40, textAlign: "center", color: "#94A3B8", fontSize: 14 }}>No se encontraron usuarios</td></tr>
            ) : (
              usuarios.map(function (u, i) {
                return (
                  <tr key={u.id} style={{ backgroundColor: i % 2 === 0 ? "#fff" : "#F8FAFC", borderBottom: "1px solid #F1F5F9" }}>
                    <td style={S.td}>
                      <div style={{ display: "flex", alignItems: "center", gap: 10 }}>
                        <div style={S.avatar}>{u.username ? u.username.substring(0, 2).toUpperCase() : "?"}</div>
                        <span>{u.username || "Sin nombre"}</span>
                      </div>
                    </td>
                    <td style={S.td}>{u.correo}</td>
                    <td style={S.td}>{badgeRol(u.rol)}</td>
                    <td style={S.td}>{badgeEstado(u.estado)}</td>
                    <td style={{ ...S.td, fontSize: 12, color: "#64748B" }}>{u.fecha_creacion ? new Date(u.fecha_creacion).toLocaleDateString("es-CO") : "—"}</td>
                    <td style={S.td}>{botonAccion(u)}</td>
                  </tr>
                );
              })
            )}
          </tbody>
        </table>
      </div>

      {/* Paginación */}
      {totalPages > 1 && (
        <div style={S.paginacion}>
          <button onClick={function () { setPage(function (p) { return Math.max(1, p - 1); }); }} disabled={page <= 1} style={S.btnPag}>← Anterior</button>
          <span style={S.pagInfo}>Página {page} de {totalPages}</span>
          <button onClick={function () { setPage(function (p) { return Math.min(totalPages, p + 1); }); }} disabled={page >= totalPages} style={S.btnPag}>Siguiente →</button>
        </div>
      )}
    </div>
  );
}


var S = {
  controles: { display: "flex", alignItems: "center", gap: 12, marginBottom: 16, flexWrap: "wrap" },
  inputBuscar: { flex: 1, minWidth: 200, padding: "10px 14px", borderRadius: 8, border: "1px solid #CBD5E1", fontSize: 13, fontFamily: "'Inter',sans-serif", outline: "none" },
  selectEstado: { padding: "10px 14px", borderRadius: 8, border: "1px solid #CBD5E1", fontSize: 13, fontFamily: "'Inter',sans-serif", backgroundColor: "#fff", cursor: "pointer" },
  totalLabel: { fontSize: 13, color: "#64748B", fontWeight: 500, fontFamily: "'Inter',sans-serif", marginLeft: "auto" },
  tableWrapper: { backgroundColor: "#fff", borderRadius: 12, border: "0.5px solid #CBD5E1", boxShadow: "0 1px 4px rgba(0,0,0,0.06)", overflow: "hidden" },
  table: { width: "100%", borderCollapse: "collapse", fontSize: 13, fontFamily: "'Inter',sans-serif" },
  th: { padding: "12px 16px", textAlign: "left", color: "#64748B", fontWeight: 500, fontSize: 11, backgroundColor: "#F1F5F9", textTransform: "uppercase", letterSpacing: 0.5 },
  td: { padding: "12px 16px", color: "#1E293B" },
  avatar: { width: 32, height: 32, borderRadius: "50%", backgroundColor: "#2563EB", display: "flex", alignItems: "center", justifyContent: "center", color: "#fff", fontSize: 11, fontWeight: 700, fontFamily: "'Montserrat',sans-serif" },
  btnBloquear: { padding: "6px 14px", borderRadius: 6, border: "1px solid #FCA5A5", backgroundColor: "#FEF2F2", color: "#DC2626", fontSize: 12, fontWeight: 600, cursor: "pointer", fontFamily: "'Inter',sans-serif" },
  btnReactivar: { padding: "6px 14px", borderRadius: 6, border: "1px solid #86EFAC", backgroundColor: "#F0FDF4", color: "#16A34A", fontSize: 12, fontWeight: 600, cursor: "pointer", fontFamily: "'Inter',sans-serif" },
  btnOcultar: { padding: "6px 14px", borderRadius: 6, border: "1px solid #FCD34D", backgroundColor: "#FFFBEB", color: "#D97706", fontSize: 12, fontWeight: 600, cursor: "pointer", fontFamily: "'Inter',sans-serif" },
  btnEliminar: { padding: "6px 14px", borderRadius: 6, border: "1px solid #FCA5A5", backgroundColor: "#FEF2F2", color: "#DC2626", fontSize: 12, fontWeight: 600, cursor: "pointer", fontFamily: "'Inter',sans-serif" },
  paginacion: { display: "flex", justifyContent: "center", alignItems: "center", gap: 16, marginTop: 16 },
  btnPag: { padding: "8px 16px", borderRadius: 6, border: "1px solid #CBD5E1", backgroundColor: "#fff", color: "#1E293B", fontSize: 13, cursor: "pointer", fontFamily: "'Inter',sans-serif" },
  pagInfo: { fontSize: 13, color: "#64748B", fontFamily: "'Inter',sans-serif" },
  toast: { position: "fixed", top: 20, right: 20, padding: "12px 20px", borderRadius: 8, fontSize: 13, fontWeight: 600, fontFamily: "'Inter',sans-serif", zIndex: 9999, boxShadow: "0 4px 12px rgba(0,0,0,0.1)" },
  overlay: { position: "fixed", top: 0, left: 0, right: 0, bottom: 0, backgroundColor: "rgba(0,0,0,0.4)", display: "flex", alignItems: "center", justifyContent: "center", zIndex: 9998 },
  modal: { backgroundColor: "#fff", borderRadius: 12, padding: 32, maxWidth: 420, width: "90%", boxShadow: "0 8px 32px rgba(0,0,0,0.15)" },
  modalTitle: { margin: "0 0 12px", fontSize: 18, fontWeight: 600, color: "#1E293B", fontFamily: "'Inter',sans-serif" },
  modalText: { margin: "0 0 24px", fontSize: 14, color: "#64748B", fontFamily: "'Inter',sans-serif", lineHeight: 1.5 },
  modalButtons: { display: "flex", justifyContent: "flex-end", gap: 10 },
  btnCancelar: { padding: "8px 20px", borderRadius: 6, border: "1px solid #CBD5E1", backgroundColor: "#fff", color: "#64748B", fontSize: 13, fontWeight: 500, cursor: "pointer", fontFamily: "'Inter',sans-serif" },
  btnConfirmarBloquear: { padding: "8px 20px", borderRadius: 6, border: "none", backgroundColor: "#DC2626", color: "#fff", fontSize: 13, fontWeight: 600, cursor: "pointer", fontFamily: "'Inter',sans-serif" },
  btnConfirmarOcultar: { padding: "8px 20px", borderRadius: 6, border: "none", backgroundColor: "#D97706", color: "#fff", fontSize: 13, fontWeight: 600, cursor: "pointer", fontFamily: "'Inter',sans-serif" },
  btnConfirmarReactivar: { padding: "8px 20px", borderRadius: 6, border: "none", backgroundColor: "#16A34A", color: "#fff", fontSize: 13, fontWeight: 600, cursor: "pointer", fontFamily: "'Inter',sans-serif" },
};
