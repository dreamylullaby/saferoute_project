import { useState, useEffect, useCallback } from "react";
import api from "../../services/api.js";
import CustomSelect from "../../components/CustomSelect.jsx";

/* Endpoints de Fer:
 * GET  /api/admin/solicitudes-eliminacion?estado=pendiente
 * GET  /api/admin/solicitudes-eliminacion/:id
 * POST /api/admin/solicitudes-eliminacion/:id/aprobar
 * POST /api/admin/solicitudes-eliminacion/:id/rechazar
 */

var ESTADOS_FILTRO = ["", "pendiente", "aprobada", "rechazada"];
var COLORES_ESTADO = { pendiente: { bg: "#FEF3C7", color: "#D97706" }, aprobada: { bg: "#DCFCE7", color: "#16A34A" }, rechazada: { bg: "#FEE2E2", color: "#DC2626" } };

function fmtFecha(f) { if (!f) return "—"; return new Date(f).toLocaleDateString("es-CO", { day: "2-digit", month: "short", year: "numeric" }); }
function truncId(id) { return id ? id.substring(0, 8) + "…" : "—"; }

export default function TabSolicitudes({ onCountChange }) {
  var [solicitudes, setSolicitudes] = useState([]);
  var [cargando, setCargando] = useState(true);
  var [filtroEstado, setFiltroEstado] = useState("pendiente");
  var [modal, setModal] = useState(null); // { id, accion: "aprobar"|"rechazar", reporte }
  var [detalle, setDetalle] = useState(null);
  var [procesando, setProcesando] = useState(false);
  var [mensaje, setMensaje] = useState(null);

  var cargar = useCallback(function () {
    setCargando(true);
    var params = {};
    if (filtroEstado) params.estado = filtroEstado;
    api.get("/api/admin/solicitudes-eliminacion", { params: params })
      .then(function (res) {
        var data = res.data.data || [];
        setSolicitudes(data);
        if (filtroEstado === "pendiente" || !filtroEstado) onCountChange?.(data.filter(function (s) { return s.estado_solicitud === "pendiente"; }).length);
      })
      .catch(function () { setSolicitudes([]); })
      .finally(function () { setCargando(false); });
  }, [filtroEstado]);

  useEffect(function () { cargar(); }, [cargar]);

  useEffect(function () {
    if (!mensaje) return;
    var t = setTimeout(function () { setMensaje(null); }, 4000);
    return function () { clearTimeout(t); };
  }, [mensaje]);

  var verDetalle = function (id) {
    api.get("/api/admin/solicitudes-eliminacion/" + id)
      .then(function (res) { setDetalle(res.data.data); })
      .catch(function () { setMensaje({ tipo: "error", texto: "Error al cargar detalle" }); });
  };

  var ejecutarAccion = function () {
    if (!modal) return;
    setProcesando(true);
    api.post("/api/admin/solicitudes-eliminacion/" + modal.id + "/" + modal.accion)
      .then(function () {
        setMensaje({ tipo: "ok", texto: "Solicitud " + (modal.accion === "aprobar" ? "aprobada" : "rechazada") + " correctamente" });
        setModal(null);
        setDetalle(null);
        cargar();
      })
      .catch(function (err) {
        setMensaje({ tipo: "error", texto: err.response?.data?.message || "Error al procesar" });
        setModal(null);
      })
      .finally(function () { setProcesando(false); });
  };

  var badgeEstado = function (estado) {
    var c = COLORES_ESTADO[estado] || COLORES_ESTADO.pendiente;
    return <span style={{ padding: "4px 10px", borderRadius: 12, fontSize: 11, fontWeight: 600, backgroundColor: c.bg, color: c.color }}>{estado.charAt(0).toUpperCase() + estado.slice(1)}</span>;
  };

  if (cargando) return <p style={{ color: "#64748b", textAlign: "center", padding: 60, fontFamily: "'Inter',sans-serif" }}>Cargando...</p>;

  return (
    <div>
      {mensaje && (
        <div style={{ position: "fixed", top: 20, right: 20, padding: "12px 20px", borderRadius: 8, fontSize: 13, fontWeight: 600, fontFamily: "'Inter',sans-serif", zIndex: 9999, boxShadow: "0 4px 12px rgba(0,0,0,0.1)", backgroundColor: mensaje.tipo === "ok" ? "#DCFCE7" : "#FEE2E2", color: mensaje.tipo === "ok" ? "#16A34A" : "#DC2626" }}>
          {mensaje.texto}
        </div>
      )}

      {/* Modal confirmación */}
      {modal && (
        <div style={S.overlay} onClick={function () { setModal(null); }}>
          <div style={S.modal} onClick={function (e) { e.stopPropagation(); }}>
            <h3 style={{ margin: "0 0 12px", fontSize: 18, fontWeight: 600, color: "#1E293B" }}>Confirmar acción</h3>
            <p style={{ margin: "0 0 20px", fontSize: 14, color: "#64748B", lineHeight: 1.5 }}>
              ¿Estás seguro de <strong>{modal.accion}</strong> esta solicitud?
              {modal.accion === "aprobar" && " El reporte será marcado como eliminado."}
            </p>
            <div style={{ display: "flex", justifyContent: "flex-end", gap: 10 }}>
              <button onClick={function () { setModal(null); }} disabled={procesando} style={S.btnCancelar}>Cancelar</button>
              <button onClick={ejecutarAccion} disabled={procesando} style={modal.accion === "aprobar" ? S.btnAprobar : S.btnRechazar}>
                {procesando ? "Procesando..." : (modal.accion === "aprobar" ? "Aprobar" : "Rechazar")}
              </button>
            </div>
          </div>
        </div>
      )}

      {/* Modal detalle */}
      {detalle && !modal && (
        <div style={S.overlay} onClick={function () { setDetalle(null); }}>
          <div style={{ ...S.modal, maxWidth: 520 }} onClick={function (e) { e.stopPropagation(); }}>
            <div style={{ display: "flex", justifyContent: "space-between", alignItems: "center", marginBottom: 16 }}>
              <h3 style={{ margin: 0, fontSize: 16, fontWeight: 600, color: "#1E293B" }}>Detalle de solicitud</h3>
              <button onClick={function () { setDetalle(null); }} style={{ background: "none", border: "none", fontSize: 18, cursor: "pointer", color: "#64748B" }}>✕</button>
            </div>
            <div style={{ display: "flex", flexDirection: "column", gap: 8 }}>
              <DetRow label="ID Solicitud" value={truncId(detalle.id)} />
              <DetRow label="Estado" value={badgeEstado(detalle.estado_solicitud)} />
              <DetRow label="Fecha solicitud" value={fmtFecha(detalle.fecha_solicitud)} />
              <DetRow label="Motivo" value={detalle.motivo || "Sin motivo"} />
              {detalle.fecha_resolucion && <DetRow label="Fecha resolución" value={fmtFecha(detalle.fecha_resolucion)} />}
              {detalle.reportes && (
                <>
                  <div style={{ height: 1, backgroundColor: "#F1F5F9", margin: "8px 0" }} />
                  <DetRow label="Reporte ID" value={truncId(detalle.reportes?.id || detalle.reporte_id)} />
                  <DetRow label="Tipo hurto" value={detalle.reportes?.tipo_hurto} />
                  <DetRow label="Fecha incidente" value={detalle.reportes?.fecha_incidente} />
                  <DetRow label="Barrio" value={detalle.reportes?.barrio_ingresado} />
                  <DetRow label="Estado reporte" value={detalle.reportes?.estado} />
                </>
              )}
              {detalle.usuarios && (
                <>
                  <div style={{ height: 1, backgroundColor: "#F1F5F9", margin: "8px 0" }} />
                  <DetRow label="Solicitante" value={detalle.usuarios?.username || detalle.usuarios?.correo} />
                </>
              )}
            </div>
            {detalle.estado_solicitud === "pendiente" && (
              <div style={{ display: "flex", gap: 10, marginTop: 20 }}>
                <button onClick={function () { setModal({ id: detalle.id, accion: "rechazar" }); }} style={{ ...S.btnRechazar, flex: 1 }}>Rechazar</button>
                <button onClick={function () { setModal({ id: detalle.id, accion: "aprobar" }); }} style={{ ...S.btnAprobar, flex: 1 }}>Aprobar eliminación</button>
              </div>
            )}
          </div>
        </div>
      )}

      {/* Filtro */}
      <div style={{ display: "flex", alignItems: "center", gap: 12, marginBottom: 16 }}>
        <div style={{ minWidth: 150 }}>
          <CustomSelect value={filtroEstado} onChange={function (v) { setFiltroEstado(v); }} placeholder="Estado" options={ESTADOS_FILTRO.map(function (e) { return { label: e ? e.charAt(0).toUpperCase() + e.slice(1) : "Todas", value: e }; })} />
        </div>
        <span style={{ fontSize: 13, color: "#64748B", marginLeft: "auto" }}>{solicitudes.length} solicitud{solicitudes.length !== 1 ? "es" : ""}</span>
      </div>

      {/* Tabla */}
      <div style={S.tableWrapper}>
        <table style={S.table}>
          <thead><tr>
            {["SOLICITANTE", "REPORTE", "MOTIVO", "ESTADO", "FECHA", "ACCIONES"].map(function (h) {
              return <th key={h} style={S.th}>{h}</th>;
            })}
          </tr></thead>
          <tbody>
            {solicitudes.length === 0 ? (
              <tr><td colSpan={6} style={{ padding: 40, textAlign: "center", color: "#94A3B8", fontSize: 14 }}>No hay solicitudes</td></tr>
            ) : solicitudes.map(function (s, i) {
              return (
                <tr key={s.id} style={{ backgroundColor: i % 2 === 0 ? "#fff" : "#F8FAFC", borderBottom: "1px solid #F1F5F9" }}>
                  <td style={S.td}>{s.usuarios?.username || s.usuarios?.correo || truncId(s.usuario_id)}</td>
                  <td style={S.td}><span style={{ fontSize: 12, color: "#64748B", fontFamily: "monospace" }}>{truncId(s.reporte_id)}</span></td>
                  <td style={{ ...S.td, maxWidth: 200, overflow: "hidden", textOverflow: "ellipsis", whiteSpace: "nowrap" }}>{s.motivo || "—"}</td>
                  <td style={S.td}>{badgeEstado(s.estado_solicitud)}</td>
                  <td style={{ ...S.td, fontSize: 12, color: "#64748B" }}>{fmtFecha(s.fecha_solicitud)}</td>
                  <td style={S.td}>
                    <div style={{ display: "flex", gap: 6 }}>
                      <button onClick={function () { verDetalle(s.id); }} style={S.btnVer} title="Ver detalle">
                        <svg width="15" height="15" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2"><path d="M1 12s4-8 11-8 11 8 11 8-4 8-11 8-11-8-11-8z"/><circle cx="12" cy="12" r="3"/></svg>
                      </button>
                      {s.estado_solicitud === "pendiente" && (
                        <>
                          <button onClick={function () { setModal({ id: s.id, accion: "aprobar" }); }} style={S.btnAprobarSmall} title="Aprobar">✓</button>
                          <button onClick={function () { setModal({ id: s.id, accion: "rechazar" }); }} style={S.btnRechazarSmall} title="Rechazar">✕</button>
                        </>
                      )}
                    </div>
                  </td>
                </tr>
              );
            })}
          </tbody>
        </table>
      </div>
    </div>
  );
}

function DetRow(props) {
  if (!props.value) return null;
  return (
    <div style={{ display: "flex", justifyContent: "space-between", alignItems: "center", padding: "6px 0" }}>
      <span style={{ fontSize: 13, color: "#64748B", fontWeight: 500 }}>{props.label}</span>
      <span style={{ fontSize: 13, color: "#1E293B", fontWeight: 400, textAlign: "right" }}>{props.value}</span>
    </div>
  );
}

var S = {
  select: { padding: "10px 14px", borderRadius: 8, border: "1px solid #CBD5E1", fontSize: 13, fontFamily: "'Inter',sans-serif", backgroundColor: "#fff", cursor: "pointer" },
  tableWrapper: { backgroundColor: "#fff", borderRadius: 12, border: "0.5px solid #CBD5E1", boxShadow: "0 1px 4px rgba(0,0,0,0.06)", overflow: "hidden" },
  table: { width: "100%", borderCollapse: "collapse", fontSize: 13, fontFamily: "'Inter',sans-serif" },
  th: { padding: "12px 16px", textAlign: "left", color: "#fff", fontWeight: 500, fontSize: 11, backgroundColor: "#2563EB", textTransform: "uppercase", letterSpacing: 0.5 },
  td: { padding: "12px 16px", color: "#1E293B" },
  overlay: { position: "fixed", inset: 0, backgroundColor: "rgba(0,0,0,0.4)", display: "flex", alignItems: "center", justifyContent: "center", zIndex: 9998 },
  modal: { backgroundColor: "#fff", borderRadius: 12, padding: 32, maxWidth: 420, width: "90%", boxShadow: "0 8px 32px rgba(0,0,0,0.15)" },
  btnCancelar: { padding: "8px 20px", borderRadius: 6, border: "1px solid #CBD5E1", backgroundColor: "#fff", color: "#64748B", fontSize: 13, fontWeight: 500, cursor: "pointer" },
  btnAprobar: { padding: "8px 20px", borderRadius: 6, border: "none", backgroundColor: "#16A34A", color: "#fff", fontSize: 13, fontWeight: 600, cursor: "pointer" },
  btnRechazar: { padding: "8px 20px", borderRadius: 6, border: "none", backgroundColor: "#DC2626", color: "#fff", fontSize: 13, fontWeight: 600, cursor: "pointer" },
  btnVer: { width: 30, height: 30, borderRadius: 6, border: "none", backgroundColor: "#EFF6FF", cursor: "pointer", display: "flex", alignItems: "center", justifyContent: "center", color: "#2563EB" },
  btnAprobarSmall: { width: 30, height: 30, borderRadius: 6, border: "none", backgroundColor: "#F0FDF4", cursor: "pointer", display: "flex", alignItems: "center", justifyContent: "center", color: "#16A34A", fontSize: 16, fontWeight: 700 },
  btnRechazarSmall: { width: 30, height: 30, borderRadius: 6, border: "none", backgroundColor: "#FEF2F2", cursor: "pointer", display: "flex", alignItems: "center", justifyContent: "center", color: "#DC2626", fontSize: 14, fontWeight: 700 },
};
