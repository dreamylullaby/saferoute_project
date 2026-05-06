import { useState, useEffect, useCallback } from "react";
import api from "../../services/api.js";
import CustomSelect from "../../components/CustomSelect.jsx";

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
      botones.push({ accion: "permanente", label: "Borrar", style: S.btnHardDelete });
    }
    return (
      <div style={{ display: "flex", gap: 6 }}>
        {botones.map(function (b) {
          return <button key={b.accion} onClick={function () { b.accion === "permanente" ? hardDeleteUsuario(u.id, u.username) : setModal({ id: u.id, username: u.username, accion: b.accion }); }} style={b.style}>{b.label}</button>;
        })}
      </div>
    );
  };

  var [modalHardDelete, setModalHardDelete] = useState(null);

  var hardDeleteUsuario = function (id, username) {
    setModalHardDelete({ id: id, username: username });
  };

  var confirmarHardDeleteUsuario = async function () {
    if (!modalHardDelete) return;
    setProcesando(true);
    try {
      await api.delete("/api/admin/usuarios/" + modalHardDelete.id + "/permanente");
      setMensaje({ tipo: "ok", texto: "Usuario eliminado permanentemente" });
      setModalHardDelete(null);
      cargar();
    } catch (err) {
      setMensaje({ tipo: "error", texto: err.response?.data?.message || "Error al eliminar permanentemente" });
      setModalHardDelete(null);
    } finally { setProcesando(false); }
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

      {/* Modal Hard Delete Usuario */}
      {modalHardDelete && (
        <div style={S.overlay} onClick={function () { setModalHardDelete(null); }}>
          <div style={S.modal} onClick={function (e) { e.stopPropagation(); }}>
            <div style={{ display: "flex", alignItems: "center", gap: 10, marginBottom: 16 }}>
              <svg width="22" height="22" viewBox="0 0 24 24" fill="none" stroke="#881337" strokeWidth="2"><path d="M10.29 3.86L1.82 18a2 2 0 0 0 1.71 3h16.94a2 2 0 0 0 1.71-3L13.71 3.86a2 2 0 0 0-3.42 0z"/><line x1="12" y1="9" x2="12" y2="13"/><line x1="12" y1="17" x2="12.01" y2="17"/></svg>
              <h3 style={{ margin: 0, fontSize: 18, fontWeight: 600, color: "#881337" }}>Eliminación permanente</h3>
            </div>
            <p style={{ margin: "0 0 12px", fontSize: 14, color: "#1E293B", lineHeight: 1.6 }}>
              Estás a punto de eliminar permanentemente al usuario <strong>{modalHardDelete.username}</strong>.
            </p>
            <div style={{ backgroundColor: "#FEF2F2", borderRadius: 8, padding: "12px 14px", marginBottom: 20, border: "1px solid #FECACA" }}>
              <p style={{ margin: 0, fontSize: 13, color: "#991B1B", lineHeight: 1.5 }}>
                ⚠️ Esta acción es <strong>irreversible</strong>. El usuario y todos sus datos asociados se perderán para siempre.
              </p>
            </div>
            <div style={{ display: "flex", justifyContent: "flex-end", gap: 10 }}>
              <button onClick={function () { setModalHardDelete(null); }} disabled={procesando} style={S.btnCancelar}>Cancelar</button>
              <button onClick={confirmarHardDeleteUsuario} disabled={procesando} style={{ padding: "8px 20px", borderRadius: 6, border: "none", backgroundColor: "#881337", color: "#fff", fontSize: 13, fontWeight: 600, cursor: "pointer" }}>
                {procesando ? "Eliminando..." : "Eliminar permanentemente"}
              </button>
            </div>
          </div>
        </div>
      )}

      {/* Modal confirmación */}
      {modal && (
        <div style={S.overlay}>
          <div style={S.modal}>
            <h3 style={S.modalTitle}>Confirmar acción</h3>
            <p style={S.modalText}>
              ¿Estás seguro de <strong>{modal.accion}</strong> al usuario <strong>{modal.username || "este usuario"}</strong>?
              {modal.accion === "eliminar" && <><br/><span style={{ fontSize: 12, color: "#DC2626" }}>El usuario pasará a estado "Eliminado". Desde ahí podrás borrarlo permanentemente si lo deseas.</span></>}
            </p>
            <div style={S.modalButtons}>
              <button onClick={function () { setModal(null); }} style={S.btnCancelar} disabled={procesando}>Cancelar</button>
              <button onClick={ejecutarAccion} style={modal.accion === "bloquear" || modal.accion === "eliminar" ? S.btnConfirmarBloquear : modal.accion === "ocultar" ? S.btnConfirmarOcultar : S.btnConfirmarReactivar} disabled={procesando}>
                {procesando ? "Procesando..." : modal.accion === "bloquear" ? "Bloquear" : modal.accion === "eliminar" ? "Eliminar" : modal.accion === "ocultar" ? "Ocultar" : "Reactivar"}
              </button>
            </div>
          </div>
        </div>
      )}

      {/* Controles: buscador + filtros */}
      <div style={S.controles}>
        <div style={{ flex: "1 1 200px", position: "relative" }}>
          <svg width="15" height="15" viewBox="0 0 24 24" fill="none" stroke="#94A3B8" strokeWidth="2" style={{ position: "absolute", left: 12, top: "50%", transform: "translateY(-50%)", pointerEvents: "none" }}><circle cx="11" cy="11" r="8"/><line x1="21" y1="21" x2="16.65" y2="16.65"/></svg>
          <input
            type="text"
            placeholder="Buscar por nombre o correo..."
            value={busquedaInput}
            onChange={function (e) { setBusquedaInput(e.target.value); }}
            style={{ ...S.inputBuscar, paddingLeft: 36 }}
          />
        </div>
        <div style={{ minWidth: 140 }}>
          <CustomSelect value={filtroEstado} onChange={function (v) { setFiltroEstado(v); setPage(1); }} placeholder="Estado" options={[{ label: "Todos", value: "" }, { label: "Activo", value: "activo" }, { label: "Bloqueado", value: "bloqueado" }, { label: "Oculto", value: "oculto" }, { label: "Eliminado", value: "eliminado" }]} />
        </div>
        <button onClick={function () { setBusquedaInput(""); setBusqueda(""); setFiltroEstado(""); setPage(1); }} style={S.btnLimpiar}>Limpiar</button>
        <span style={S.totalLabel}>{total} usuario{total !== 1 ? "s" : ""}</span>
      </div>

      {/* Aviso acciones destructivas */}
      <div style={{ display: "flex", alignItems: "flex-start", gap: 8, padding: "10px 14px", backgroundColor: "#FFF7ED", borderRadius: 8, border: "1px solid #FED7AA", marginBottom: 12 }}>
        <svg width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="#9A3412" strokeWidth="2" style={{ flexShrink: 0, marginTop: 1 }}><circle cx="12" cy="12" r="10"/><line x1="12" y1="16" x2="12" y2="12"/><line x1="12" y1="8" x2="12.01" y2="8"/></svg>
        <span style={{ fontSize: 12, color: "#9A3412", fontWeight: 400, lineHeight: 1.5 }}><strong>Bloquear/Eliminar</strong> cambia el estado del usuario (reversible, se puede restaurar). <strong>Borrar</strong> elimina permanentemente al usuario de la base de datos (irreversible). El botón "Borrar" solo aparece en usuarios con estado "Eliminado".</span>
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
              [...usuarios].sort(function (a, b) { if (a.rol === "admin" && b.rol !== "admin") return -1; if (a.rol !== "admin" && b.rol === "admin") return 1; return 0; }).map(function (u, i) {
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
        <div style={{ display: "flex", justifyContent: "center", alignItems: "center", gap: 16, marginTop: 16 }}>
          <button onClick={function () { setPage(function (p) { return Math.max(1, p - 1); }); }} disabled={page <= 1} style={S.btnPag}>← Anterior</button>
          <span style={{ fontSize: 13, color: "#64748B", fontFamily: "'Inter',sans-serif" }}>Página {page} de {totalPages}</span>
          <button onClick={function () { setPage(function (p) { return Math.min(totalPages, p + 1); }); }} disabled={page >= totalPages} style={S.btnPag}>Siguiente →</button>
        </div>
      )}
    </div>
  );
}


var S = {
  controles: { display: "flex", alignItems: "center", gap: 12, marginBottom: 16, flexWrap: "wrap" },
  inputBuscar: { width: "100%", padding: "10px 14px", borderRadius: 8, border: "1px solid #CBD5E1", fontSize: 13, fontFamily: "'Inter',sans-serif", outline: "none", boxSizing: "border-box" },
  selectFiltro: { padding: "10px 32px 10px 12px", borderRadius: 8, border: "1px solid #CBD5E1", fontSize: 13, fontFamily: "'Inter',sans-serif", backgroundColor: "#fff", cursor: "pointer", flexShrink: 0 },
  btnLimpiar: { height: 38, padding: "0 14px", borderRadius: 8, border: "1px solid #CBD5E1", backgroundColor: "transparent", color: "#64748B", fontSize: 13, cursor: "pointer", fontFamily: "'Inter',sans-serif", whiteSpace: "nowrap", flexShrink: 0 },
  totalLabel: { fontSize: 13, color: "#64748B", fontWeight: 500, fontFamily: "'Inter',sans-serif", marginLeft: "auto" },
  tableWrapper: { backgroundColor: "#fff", borderRadius: 12, border: "0.5px solid #CBD5E1", boxShadow: "0 1px 4px rgba(0,0,0,0.06)", overflow: "hidden" },
  table: { width: "100%", borderCollapse: "collapse", fontSize: 13, fontFamily: "'Inter',sans-serif" },
  th: { padding: "12px 16px", textAlign: "left", color: "#fff", fontWeight: 500, fontSize: 11, backgroundColor: "#2563EB", textTransform: "uppercase", letterSpacing: 0.5 },
  td: { padding: "12px 16px", color: "#1E293B" },
  avatar: { width: 32, height: 32, borderRadius: "50%", backgroundColor: "#2563EB", display: "flex", alignItems: "center", justifyContent: "center", color: "#fff", fontSize: 11, fontWeight: 700, fontFamily: "'Montserrat',sans-serif" },
  btnBloquear: { padding: "6px 14px", borderRadius: 6, border: "1px solid #FCA5A5", backgroundColor: "#FEF2F2", color: "#DC2626", fontSize: 12, fontWeight: 600, cursor: "pointer", fontFamily: "'Inter',sans-serif" },
  btnReactivar: { padding: "6px 14px", borderRadius: 6, border: "1px solid #86EFAC", backgroundColor: "#F0FDF4", color: "#16A34A", fontSize: 12, fontWeight: 600, cursor: "pointer", fontFamily: "'Inter',sans-serif" },
  btnOcultar: { padding: "6px 14px", borderRadius: 6, border: "1px solid #FCD34D", backgroundColor: "#FFFBEB", color: "#D97706", fontSize: 12, fontWeight: 600, cursor: "pointer", fontFamily: "'Inter',sans-serif" },
  btnEliminar: { padding: "6px 14px", borderRadius: 6, border: "1px solid #FCA5A5", backgroundColor: "#FEF2F2", color: "#DC2626", fontSize: 12, fontWeight: 600, cursor: "pointer", fontFamily: "'Inter',sans-serif" },
  btnHardDelete: { padding: "6px 14px", borderRadius: 6, border: "1px solid #881337", backgroundColor: "#FFF1F2", color: "#881337", fontSize: 12, fontWeight: 600, cursor: "pointer", fontFamily: "'Inter',sans-serif" },
  paginacion: { display: "flex", justifyContent: "center", alignItems: "center", gap: 16, marginTop: 16 },
  btnPag: { padding: "8px 16px", borderRadius: 8, border: "1px solid #E2E8F0", backgroundColor: "#fff", color: "#1E293B", fontSize: 13, cursor: "pointer", fontFamily: "'Inter',sans-serif", transition: "border-color 0.2s ease" },
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
