import { useState, useEffect, useCallback } from "react";
import { getReportesAdmin, getReporteById } from "../../services/reportService.js";

var TIPOS = ["", "atraco", "raponazo", "cosquilleo", "fleteo"];
var COMUNAS = ["", ...Array.from({ length: 12 }, function (_, i) { return String(i + 1); })];
var FRANJAS = ["", "00:00-05:59", "06:00-11:59", "12:00-17:59", "18:00-23:59"];
var COLORES_TIPO = { atraco: "#B91C1C", raponazo: "#9D174D", fleteo: "#D946EF", cosquilleo: "#8A2BE2" };
var MAPBOX_TOKEN = import.meta.env.VITE_MAPBOX_TOKEN || "";

function fmtFecha(f) { if (!f) return "—"; var p = f.split("-"); return p.length === 3 ? p[2] + "/" + p[1] + "/" + p[0] : f; }
function truncId(id) { return id ? id.substring(0, 8) + "…" : "—"; }
function copyId(id) { if (id && navigator.clipboard) navigator.clipboard.writeText(id); }

export default function TabIncidentes({ onCountChange }) {
  var [reportes, setReportes] = useState([]);
  var [total, setTotal] = useState(0);
  var [page, setPage] = useState(1);
  var [totalPages, setTotalPages] = useState(1);
  var [cargando, setCargando] = useState(true);
  var [detalle, setDetalle] = useState(null);
  var [modalType, setModalType] = useState(null);
  var [filtros, setFiltros] = useState({ busqueda: "", tipo_hurto: "", comuna: "", franja: "", fechaDesde: "", fechaHasta: "" });

  var cargar = useCallback(async function () {
    setCargando(true);
    try {
      var params = { page: page, limit: 10 };
      if (filtros.tipo_hurto) params.tipo_hurto = filtros.tipo_hurto;
      if (filtros.comuna) params.comuna = filtros.comuna;
      if (filtros.fechaDesde) params.fechaDesde = filtros.fechaDesde;
      if (filtros.fechaHasta) params.fechaHasta = filtros.fechaHasta;
      if (filtros.busqueda) params.busqueda = filtros.busqueda;
      var res = await getReportesAdmin(params);
      setReportes(res.data || []); setTotal(res.total || 0); setTotalPages(res.totalPages || 1);
    } catch (e) { console.error(e); } finally { setCargando(false); }
  }, [page, filtros]); // eslint-disable-line react-hooks/exhaustive-deps

  useEffect(function () { cargar(); }, [cargar]);
  useEffect(function () { onCountChange?.(total); }, [total]); // eslint-disable-line react-hooks/exhaustive-deps

  var abrirModal = async function (id, type) {
    try { var data = await getReporteById(id); setDetalle(data); setModalType(type); } catch (e) { console.error(e); }
  };

  var exportarExcel = function () {
    var headers = ["Fecha", "Comuna", "Tipo", "Barrio", "Franja", "Usuario", "Estado"];
    var rows = reportes.map(function (r) { return [r.fecha_incidente, r.comuna ?? "", r.tipo_hurto, r.barrio_ingresado, r.franja_horaria, r.usuarios?.username ?? r.usuario_id, r.estado]; });
    var csv = [headers, ...rows].map(function (r) { return r.join(","); }).join("\n");
    var blob = new Blob(["\uFEFF" + csv], { type: "text/csv;charset=utf-8;" });
    var url = URL.createObjectURL(blob);
    var a = document.createElement("a"); a.href = url; a.download = "incidentes_saferoute_" + new Date().toISOString().split("T")[0] + ".csv"; a.click(); URL.revokeObjectURL(url);
  };

  var setFiltro = function (key, val) {
    setFiltros(function (f) { return { ...f, [key]: val }; });
    setPage(1);
  };
  var hayUsuarios = reportes.some(function (r) { return r.usuarios?.username && r.usuarios.username !== "—"; });

  return (
    <div style={{ display: "flex", flexDirection: "column", gap: 16, paddingBottom: 24 }}>
      {/* Filtros — una sola fila */}
      <div style={CARD}>
        <div style={{ display: "flex", alignItems: "center", gap: 10, flexWrap: "wrap" }}>
          <div style={{ flex: "1.5 1 160px", position: "relative" }}>
            <svg width="15" height="15" viewBox="0 0 24 24" fill="none" stroke="#94A3B8" strokeWidth="2" style={{ position: "absolute", left: 10, top: "50%", transform: "translateY(-50%)", pointerEvents: "none" }}><circle cx="11" cy="11" r="8"/><line x1="21" y1="21" x2="16.65" y2="16.65"/></svg>
            <input type="text" placeholder="Buscar..." value={filtros.busqueda} onChange={function (e) { setFiltro("busqueda", e.target.value); }} style={{ ...FI, paddingLeft: 34, width: "100%" }} />
          </div>
          <select value={filtros.comuna} onChange={function (e) { setFiltro("comuna", e.target.value); }} style={{ ...FI, flex: "1 1 100px" }}>{COMUNAS.map(function (c) { return <option key={c} value={c}>{c || "Comuna"}</option>; })}</select>
          <select value={filtros.tipo_hurto} onChange={function (e) { setFiltro("tipo_hurto", e.target.value); }} style={{ ...FI, flex: "1 1 100px" }}>{TIPOS.map(function (t) { return <option key={t} value={t}>{t ? t.charAt(0).toUpperCase() + t.slice(1) : "Tipo"}</option>; })}</select>
          <select value={filtros.franja} onChange={function (e) { setFiltro("franja", e.target.value); }} style={{ ...FI, flex: "1 1 100px" }}>{FRANJAS.map(function (f) { return <option key={f} value={f}>{f || "Horario"}</option>; })}</select>
          <input type="date" value={filtros.fechaDesde} onChange={function (e) { setFiltro("fechaDesde", e.target.value); }} style={{ ...FI, flex: "1 1 120px" }} />
          <input type="date" value={filtros.fechaHasta} onChange={function (e) { setFiltro("fechaHasta", e.target.value); }} style={{ ...FI, flex: "1 1 120px" }} />
          <button onClick={exportarExcel} style={BTN_EXPORT}>
            <svg width="15" height="15" viewBox="0 0 24 24" fill="none" stroke="#fff" strokeWidth="2"><path d="M21 15v4a2 2 0 0 1-2 2H5a2 2 0 0 1-2-2v-4"/><polyline points="7 10 12 15 17 10"/><line x1="12" y1="15" x2="12" y2="3"/></svg>
            <span>Exportar</span>
          </button>
          <button onClick={function () { setFiltros({ busqueda: "", tipo_hurto: "", comuna: "", franja: "", fechaDesde: "", fechaHasta: "" }); setPage(1); }} style={{ height: 38, padding: "0 14px", borderRadius: 8, border: "1px solid #CBD5E1", backgroundColor: "transparent", color: "#64748B", fontSize: 13, cursor: "pointer", whiteSpace: "nowrap", flexShrink: 0 }}>Limpiar</button>
        </div>
      </div>

      {cargando ? (<p style={{ color: "#64748b", textAlign: "center", padding: 40, fontWeight: 300 }}>Cargando...</p>) : (
        <div style={CARD_TABLE}>
          <table style={{ width: "100%", borderCollapse: "collapse", fontSize: 13, fontFamily: "'Inter',sans-serif" }}>
            <thead><tr style={{ backgroundColor: "#2563EB" }}>
              <th style={{ ...TH_NEW, width: "15%", borderRadius: "8px 0 0 0" }}>FECHA</th>
              <th style={{ ...TH_NEW, width: "12%" }}>COMUNA</th>
              <th style={{ ...TH_NEW, width: "18%" }}>TIPO</th>
              {hayUsuarios && <th style={TH_NEW}>USUARIO</th>}
              <th style={{ ...TH_NEW, width: "12%", textAlign: "center", borderRadius: "0 8px 0 0" }}>ACCIONES</th>
            </tr></thead>
            <tbody>
              {reportes.map(function (r, idx) {
                var bg = idx % 2 === 0 ? "#fff" : "#F8FAFC";
                var tipoColor = COLORES_TIPO[r.tipo_hurto] || "#64748b";
                return (
                  <tr key={r.id} style={{ backgroundColor: bg, borderBottom: "1px solid #F1F5F9" }}>
                    <td style={TD}>{fmtFecha(r.fecha_incidente)}</td>
                    <td style={TD}>{r.comuna ?? "—"}</td>
                    <td style={TD}><span style={{ backgroundColor: tipoColor + "26", color: tipoColor, padding: "4px 12px", borderRadius: 99, fontSize: 11, fontWeight: 500, fontFamily: "'Montserrat',sans-serif" }}>{r.tipo_hurto?.charAt(0).toUpperCase() + r.tipo_hurto?.slice(1)}</span></td>
                    {hayUsuarios && <td style={TD}>{r.usuarios?.username ?? "—"}</td>}
                    <td style={{ ...TD, textAlign: "center" }}>
                      <div style={{ display: "flex", justifyContent: "center", alignItems: "center", gap: 6 }}>
                        <button onClick={function () { abrirModal(r.id, "ver"); }} style={{ width: 30, height: 30, borderRadius: 6, border: "none", backgroundColor: "#EFF6FF", cursor: "pointer", display: "flex", alignItems: "center", justifyContent: "center", color: "#2563EB" }} title="Ver detalle"><svg width="15" height="15" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2"><path d="M1 12s4-8 11-8 11 8 11 8-4 8-11 8-11-8-11-8z"/><circle cx="12" cy="12" r="3"/></svg></button>
                        <button onClick={function () { abrirModal(r.id, "editar"); }} style={{ width: 30, height: 30, borderRadius: 6, border: "none", backgroundColor: "#FFFBEB", cursor: "pointer", display: "flex", alignItems: "center", justifyContent: "center", color: "#D97706" }} title="Editar"><svg width="15" height="15" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2"><path d="M17 3a2.83 2.83 0 1 1 4 4L7.5 20.5 2 22l1.5-5.5L17 3z"/></svg></button>
                        <button onClick={function () { abrirModal(r.id, "eliminar"); }} style={{ width: 30, height: 30, borderRadius: 6, border: "none", backgroundColor: "#FEF2F2", cursor: "pointer", display: "flex", alignItems: "center", justifyContent: "center", color: "#B91C1C" }} title="Ocultar"><svg width="15" height="15" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2"><polyline points="3 6 5 6 21 6"/><path d="M19 6v14a2 2 0 0 1-2 2H7a2 2 0 0 1-2-2V6m3 0V4a2 2 0 0 1 2-2h4a2 2 0 0 1 2 2v2"/></svg></button>
                      </div>
                    </td>
                  </tr>
                );
              })}
            </tbody>
          </table>
          <div style={{ display: "flex", justifyContent: "space-between", alignItems: "center", padding: "12px 16px", borderTop: "1px solid #F1F5F9" }}>
            <span style={{ color: "#64748b", fontSize: 13, fontWeight: 300 }}>Página {page} de {totalPages}</span>
            <div style={{ display: "flex", gap: 4 }}>
              <button onClick={function () { setPage(function (p) { return Math.max(1, p - 1); }); }} disabled={page === 1} style={BTN_PAG}>‹</button>
              <button onClick={function () { setPage(function (p) { return Math.min(totalPages, p + 1); }); }} disabled={page === totalPages} style={BTN_PAG}>›</button>
            </div>
          </div>
        </div>
      )}

      {/* Modal Ver */}
      {detalle && modalType === "ver" && (
        <ModalBase onClose={function () { setDetalle(null); }} maxWidth={480}>
          <div style={{ backgroundColor: "#2563EB", padding: "16px 20px", borderRadius: "12px 12px 0 0", display: "flex", alignItems: "center", justifyContent: "space-between" }}>
            <div style={{ display: "flex", alignItems: "center", gap: 10 }}>
              <h2 style={{ margin: 0, fontSize: 16, fontWeight: 600, color: "#fff", fontFamily: "'Montserrat',sans-serif" }}>Detalle del Incidente</h2>
              <span style={{ backgroundColor: (COLORES_TIPO[detalle.tipo_hurto] || "#64748b") + "33", color: "#fff", padding: "3px 12px", borderRadius: 99, fontSize: 12, fontWeight: 500, fontFamily: "'Montserrat',sans-serif", border: "1px solid rgba(255,255,255,0.3)" }}>{detalle.tipo_hurto ? detalle.tipo_hurto.charAt(0).toUpperCase() + detalle.tipo_hurto.slice(1) : ""}</span>
            </div>
            <button onClick={function () { setDetalle(null); }} style={{ background: "none", border: "none", color: "#fff", fontSize: 18, cursor: "pointer" }}>✕</button>
          </div>
          <div style={{ padding: "20px 24px" }}>
            <Fila label="ID" valor={<span style={{ display: "flex", alignItems: "center", gap: 6 }}>{truncId(detalle.id)}<button onClick={function () { copyId(detalle.id); }} style={{ background: "none", border: "none", cursor: "pointer", padding: 0, color: "#64748B" }} title="Copiar ID completo"><svg width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2"><rect x="9" y="9" width="13" height="13" rx="2"/><path d="M5 15H4a2 2 0 0 1-2-2V4a2 2 0 0 1 2-2h9a2 2 0 0 1 2 2v1"/></svg></button></span>} />
            <Fila label="Estado" valor={detalle.estado} />
            <Fila label="Tipo reportante" valor={detalle.tipo_reportante} />
            <Fila label="Fecha incidente" valor={fmtFecha(detalle.fecha_incidente)} />
            <Fila label="Franja horaria" valor={detalle.franja_horaria} />
            <Fila label="Barrio" valor={detalle.barrio_ingresado} />
            <Fila label="Comuna" valor={detalle.comuna ? "Comuna " + detalle.comuna : null} />
            <Fila label="Dirección" valor={detalle.direccion} />
            {detalle.latitud && <Fila label="Coordenadas" valor={detalle.latitud + ", " + detalle.longitud} />}
            <Fila label="Objeto hurtado" valor={detalle.objeto_hurtado} />
            <Fila label="N° agresores" valor={detalle.numero_agresores} />
            {detalle.descripcion && (<div style={{ padding: "10px 0", borderBottom: "0.5px solid #F1F5F9" }}><span style={{ color: "#1E293B", fontSize: 13, fontWeight: 600, display: "block", marginBottom: 6 }}>Descripción</span><p style={{ margin: 0, fontSize: 13, color: "#1E293B", fontWeight: 400, lineHeight: 1.5 }}>{detalle.descripcion}</p></div>)}
            {detalle.latitud && detalle.longitud && (
              <div style={{ marginTop: 16 }}>
                <div style={{ borderRadius: 10, overflow: "hidden", border: "0.5px solid #CBD5E1", position: "relative" }}>
                  <img src={"https://api.mapbox.com/styles/v1/mapbox/streets-v12/static/pin-s+B91C1C(" + detalle.longitud + "," + detalle.latitud + ")/" + detalle.longitud + "," + detalle.latitud + ",15,0/440x180@2x?access_token=" + MAPBOX_TOKEN} alt="Ubicación del incidente" style={{ width: "100%", height: 180, objectFit: "cover", display: "block" }} />
                </div>
                <div style={{ display: "flex", justifyContent: "center", marginTop: 8 }}>
                  <a href={"https://www.google.com/maps?q=" + detalle.latitud + "," + detalle.longitud} target="_blank" rel="noopener noreferrer" style={{ display: "inline-flex", alignItems: "center", gap: 6, fontSize: 12, color: "#2563EB", textDecoration: "none", fontWeight: 500 }}>
                    <svg width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="#2563EB" strokeWidth="2"><path d="M21 10c0 7-9 13-9 13s-9-6-9-13a9 9 0 0 1 18 0z"/><circle cx="12" cy="10" r="3"/></svg>
                    Ver ubicación en Google Maps
                  </a>
                </div>
              </div>
            )}
          </div>
        </ModalBase>
      )}

      {/* Modal Editar */}
      {detalle && modalType === "editar" && (
        <ModalBase onClose={function () { setDetalle(null); }} maxWidth={420}>
          <div style={{ padding: 24 }}>
            <div style={{ display: "flex", gap: 8, alignItems: "center", marginBottom: 16 }}>
              <span style={{ fontSize: 12, color: "#64748B", fontWeight: 300 }}>{truncId(detalle.id)}</span>
              <span style={{ backgroundColor: (COLORES_TIPO[detalle.tipo_hurto] || "#64748b") + "26", color: COLORES_TIPO[detalle.tipo_hurto] || "#64748b", padding: "3px 10px", borderRadius: 99, fontSize: 11, fontWeight: 500, fontFamily: "'Montserrat',sans-serif" }}>{detalle.tipo_hurto ? detalle.tipo_hurto.charAt(0).toUpperCase() + detalle.tipo_hurto.slice(1) : ""}</span>
            </div>
            <div style={{ textAlign: "center", padding: "32px 0" }}>
              <svg width="48" height="48" viewBox="0 0 24 24" fill="none" stroke="#CBD5E1" strokeWidth="1.5"><circle cx="12" cy="12" r="3"/><path d="M19.4 15a1.65 1.65 0 0 0 .33 1.82l.06.06a2 2 0 0 1-2.83 2.83l-.06-.06a1.65 1.65 0 0 0-1.82-.33 1.65 1.65 0 0 0-1 1.51V21a2 2 0 0 1-4 0v-.09A1.65 1.65 0 0 0 9 19.4a1.65 1.65 0 0 0-1.82.33l-.06.06a2 2 0 0 1-2.83-2.83l.06-.06A1.65 1.65 0 0 0 4.68 15a1.65 1.65 0 0 0-1.51-1H3a2 2 0 0 1 0-4h.09A1.65 1.65 0 0 0 4.6 9a1.65 1.65 0 0 0-.33-1.82l-.06-.06a2 2 0 0 1 2.83-2.83l.06.06A1.65 1.65 0 0 0 9 4.68a1.65 1.65 0 0 0 1-1.51V3a2 2 0 0 1 4 0v.09a1.65 1.65 0 0 0 1 1.51 1.65 1.65 0 0 0 1.82-.33l.06-.06a2 2 0 0 1 2.83 2.83l-.06.06A1.65 1.65 0 0 0 19.4 9a1.65 1.65 0 0 0 1.51 1H21a2 2 0 0 1 0 4h-.09a1.65 1.65 0 0 0-1.51 1z"/></svg>
              <h3 style={{ margin: "12px 0 4px", fontSize: 16, fontWeight: 600, color: "#1E293B" }}>Edición en desarrollo</h3>
              <p style={{ margin: 0, fontSize: 14, color: "#64748B" }}>Esta función estará disponible próximamente</p>
              <span style={{ display: "inline-block", marginTop: 12, backgroundColor: "#EFF6FF", color: "#2563EB", padding: "4px 14px", borderRadius: 99, fontSize: 12, fontWeight: 500, fontFamily: "'Montserrat',sans-serif" }}>Próximamente</span>
            </div>
            <button onClick={function () { setDetalle(null); }} style={{ width: "100%", padding: 10, borderRadius: 8, border: "1px solid #CBD5E1", backgroundColor: "transparent", color: "#64748B", cursor: "pointer", fontSize: 13, marginTop: 8 }}>Cerrar</button>
          </div>
        </ModalBase>
      )}

      {/* Modal Ocultar */}
      {detalle && modalType === "eliminar" && (
        <ModalBase onClose={function () { setDetalle(null); }} maxWidth={420}>
          <div style={{ backgroundColor: "#FEF2F2", padding: "16px 20px", borderRadius: "12px 12px 0 0", display: "flex", alignItems: "center", justifyContent: "space-between", borderBottom: "1px solid #FECACA" }}>
            <div style={{ display: "flex", alignItems: "center", gap: 8 }}>
              <svg width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="#B91C1C" strokeWidth="2"><path d="M10.29 3.86L1.82 18a2 2 0 0 0 1.71 3h16.94a2 2 0 0 0 1.71-3L13.71 3.86a2 2 0 0 0-3.42 0z"/><line x1="12" y1="9" x2="12" y2="13"/><line x1="12" y1="17" x2="12.01" y2="17"/></svg>
              <h2 style={{ margin: 0, fontSize: 16, fontWeight: 600, color: "#B91C1C" }}>Ocultar Incidente</h2>
            </div>
            <button onClick={function () { setDetalle(null); }} style={{ background: "none", border: "none", color: "#B91C1C", fontSize: 18, cursor: "pointer" }}>✕</button>
          </div>
          <div style={{ padding: "20px 24px" }}>
            <p style={{ color: "#1E293B", fontSize: 14, marginBottom: 16, fontWeight: 400 }}>¿Estás seguro de que deseas ocultar este incidente? Esta acción cambiará su estado a "oculto".</p>
            <div style={{ backgroundColor: "#FEF2F2", borderRadius: 8, padding: "10px 14px", display: "flex", flexDirection: "column", gap: 4, marginBottom: 20 }}>
              <div style={{ display: "flex", justifyContent: "space-between" }}><span style={{ fontSize: 12, color: "#1E293B", fontWeight: 600 }}>ID</span><span style={{ fontSize: 12, color: "#1E293B", fontWeight: 400 }}>{truncId(detalle.id)}</span></div>
              <div style={{ display: "flex", justifyContent: "space-between" }}><span style={{ fontSize: 12, color: "#1E293B", fontWeight: 600 }}>Tipo</span><span style={{ fontSize: 12, color: "#1E293B", fontWeight: 400 }}>{detalle.tipo_hurto ? detalle.tipo_hurto.charAt(0).toUpperCase() + detalle.tipo_hurto.slice(1) : ""}</span></div>
              <div style={{ display: "flex", justifyContent: "space-between" }}><span style={{ fontSize: 12, color: "#1E293B", fontWeight: 600 }}>Fecha</span><span style={{ fontSize: 12, color: "#1E293B", fontWeight: 400 }}>{fmtFecha(detalle.fecha_incidente)}</span></div>
            </div>
            <div style={{ display: "flex", gap: 10, padding: "0" }}>
              <button onClick={function () { setDetalle(null); }} style={{ flex: 1, height: 40, borderRadius: 8, border: "1px solid #CBD5E1", backgroundColor: "#fff", color: "#64748B", cursor: "pointer", fontSize: 14, fontWeight: 500 }}>Cancelar</button>
              <button onClick={function () { setDetalle(null); }} style={{ flex: 1, height: 40, borderRadius: 8, border: "none", backgroundColor: "#B91C1C", color: "#fff", cursor: "pointer", fontSize: 14, fontWeight: 600, fontFamily: "'Montserrat',sans-serif" }}>Confirmar</button>
            </div>
          </div>
        </ModalBase>
      )}
    </div>
  );
}

function ModalBase(props) {
  return (
    <div style={{ position: "fixed", inset: 0, backgroundColor: "rgba(0,0,0,0.5)", display: "flex", alignItems: "center", justifyContent: "center", zIndex: 1000 }} onClick={props.onClose}>
      <div style={{ backgroundColor: "#fff", borderRadius: 12, width: "100%", maxWidth: props.maxWidth || 480, maxHeight: "85vh", overflowY: "auto", boxShadow: "0 20px 60px rgba(0,0,0,0.3)", scrollbarWidth: "thin", scrollbarColor: "rgba(0,0,0,0.12) transparent" }} onClick={function (e) { e.stopPropagation(); }}>
        {props.children}
      </div>
    </div>
  );
}

function Fila(props) {
  if (!props.valor) return null;
  return (
    <div style={{ display: "flex", alignItems: "center", padding: "10px 0", borderBottom: "0.5px solid #F1F5F9", gap: 8 }}>
      <span style={{ color: "#1E293B", fontSize: 13, fontWeight: 600, minWidth: 120 }}>{props.label}</span>
      <span style={{ color: "#1E293B", fontSize: 13, fontWeight: 400, textAlign: "right", flex: 1 }}>{props.valor}</span>
    </div>
  );
}

var CARD = { backgroundColor: "#fff", borderRadius: 12, padding: 16, border: "0.5px solid #CBD5E1", boxShadow: "0 1px 4px rgba(0,0,0,0.06)" };
var CARD_TABLE = { backgroundColor: "#fff", borderRadius: 12, border: "0.5px solid #CBD5E1", boxShadow: "0 1px 4px rgba(0,0,0,0.06)", overflow: "hidden" };
var FI = { height: 38, padding: "0 10px", borderRadius: 8, border: "0.5px solid #CBD5E1", fontSize: 13, color: "#1E293B", fontFamily: "'Inter',sans-serif", backgroundColor: "#F8FAFC", boxSizing: "border-box" };
var TH_NEW = { padding: "12px 16px", textAlign: "left", color: "#fff", fontWeight: 500, fontSize: 12, textTransform: "uppercase", letterSpacing: 0.5, fontFamily: "'Inter',sans-serif" };
var TD = { padding: "12px 16px", color: "#1E293B", fontFamily: "'Inter',sans-serif" };
var BTN_EXPORT = { display: "flex", alignItems: "center", gap: 6, height: 38, padding: "0 16px", borderRadius: 8, border: "none", backgroundColor: "#10B981", color: "#fff", fontFamily: "'Montserrat',sans-serif", fontWeight: 500, fontSize: 13, cursor: "pointer", whiteSpace: "nowrap", flexShrink: 0 };
var BTN_PAG = { width: 32, height: 32, borderRadius: 6, border: "1px solid #E2E8F0", backgroundColor: "#fff", cursor: "pointer", fontSize: 16 };
