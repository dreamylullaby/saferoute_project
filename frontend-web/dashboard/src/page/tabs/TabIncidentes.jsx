import { useState, useEffect, useCallback } from "react";
import { getReportesAdmin, getReporteById, cambiarEstadoReporte, editarTipoHurtoReporte } from "../../services/reportService.js";
import api from "../../services/api.js";

var TIPOS = ["", "atraco", "raponazo", "cosquilleo", "fleteo"];
var ESTADOS = ["", "activo", "oculto", "eliminado"];
var COMUNAS = ["", ...Array.from({ length: 12 }, function (_, i) { return String(i + 1); })];
var FRANJAS = ["", "00:00-05:59", "06:00-11:59", "12:00-17:59", "18:00-23:59"];
var COLORES_TIPO = { atraco: "#B91C1C", raponazo: "#0891B2", fleteo: "#D946EF", cosquilleo: "#8A2BE2" };
var COLORES_ESTADO = { activo: { bg: "#DCFCE7", color: "#16A34A" }, oculto: { bg: "#FEF3C7", color: "#D97706" }, eliminado: { bg: "#FEE2E2", color: "#DC2626" } };
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
  var [modalEstado, setModalEstado] = useState(null); // { id, tipo_hurto, fecha, estadoActual, nuevoEstado }
  var [modalEditar, setModalEditar] = useState(null); // { id, tipoActual, descripcion }
  var [nuevoTipo, setNuevoTipo] = useState("");
  var [procesando, setProcesando] = useState(false);
  var [mensaje, setMensaje] = useState(null);
  var [filtros, setFiltros] = useState({ busqueda: "", tipo_hurto: "", estado: "", comuna: "", franja: "", fechaDesde: "", fechaHasta: "" });

  var cargar = useCallback(async function () {
    setCargando(true);
    try {
      var params = { page: page, limit: 10 };
      if (filtros.tipo_hurto) params.tipo_hurto = filtros.tipo_hurto;
      if (filtros.estado) params.estado = filtros.estado;
      if (filtros.comuna) params.comuna = filtros.comuna;
      if (filtros.fechaDesde) params.fechaDesde = filtros.fechaDesde;
      if (filtros.fechaHasta) params.fechaHasta = filtros.fechaHasta;
      if (filtros.busqueda) params.busqueda = filtros.busqueda;
      var res = await getReportesAdmin(params);
      setReportes(res.data || []); setTotal(res.total || 0); setTotalPages(res.totalPages || 1);
    } catch (e) { console.error(e); } finally { setCargando(false); }
  }, [page, filtros]);

  useEffect(function () { cargar(); }, [cargar]);
  useEffect(function () { onCountChange?.(total); }, [total]);

  // Auto-ocultar mensaje
  useEffect(function () {
    if (!mensaje) return;
    var t = setTimeout(function () { setMensaje(null); }, 4000);
    return function () { clearTimeout(t); };
  }, [mensaje]);

  var abrirModal = async function (id, type) {
    try { var data = await getReporteById(id); setDetalle(data); setModalType(type); } catch (e) { console.error(e); }
  };

  var abrirModalEstado = function (r, nuevoEstado) {
    setModalEstado({ id: r.id, tipo_hurto: r.tipo_hurto, fecha: r.fecha_incidente, estadoActual: r.estado, nuevoEstado: nuevoEstado });
  };

  var abrirModalEditar = async function (id) {
    try {
      var data = await getReporteById(id);
      setModalEditar({ id: data.id, tipoActual: data.tipo_hurto, descripcion: data.descripcion });
      setNuevoTipo(data.tipo_hurto);
    } catch (e) { console.error(e); }
  };

  var confirmarEdicion = async function () {
    if (!modalEditar || !nuevoTipo) return;
    setProcesando(true);
    try {
      await editarTipoHurtoReporte(modalEditar.id, nuevoTipo);
      setMensaje({ tipo: "ok", texto: "Tipo de hurto actualizado correctamente" });
      setModalEditar(null);
      cargar();
    } catch (err) {
      setMensaje({ tipo: "error", texto: err.response?.data?.message || "Error al editar" });
    } finally { setProcesando(false); }
  };

  var confirmarCambioEstado = async function () {
    if (!modalEstado) return;
    setProcesando(true);
    try {
      await cambiarEstadoReporte(modalEstado.id, modalEstado.nuevoEstado);
      setMensaje({ tipo: "ok", texto: "Reporte cambiado a \"" + modalEstado.nuevoEstado + "\" correctamente" });
      setModalEstado(null);
      cargar();
    } catch (err) {
      setMensaje({ tipo: "error", texto: err.response?.data?.message || "Error al cambiar estado" });
      setModalEstado(null);
    } finally { setProcesando(false); }
  };

  var [formatoExport, setFormatoExport] = useState("excel");
  var [exportando, setExportando] = useState(false);

  var descargarReportes = async function () {
    setExportando(true);
    try {
      var params = { formato: formatoExport };
      if (filtros.fechaDesde) params.fechaDesde = filtros.fechaDesde;
      if (filtros.fechaHasta) params.fechaHasta = filtros.fechaHasta;
      if (filtros.estado) params.estado = filtros.estado;
      if (filtros.comuna) params.zona = filtros.comuna;

      var response = await api.get("/api/admin/reportes/export", { params: params, responseType: "blob" });

      // Si el backend devuelve JSON (error o sin datos), leerlo
      var contentType = response.headers["content-type"] || "";
      if (contentType.includes("application/json")) {
        var text = await response.data.text();
        var json = JSON.parse(text);
        setMensaje({ tipo: json.success === false ? "error" : "ok", texto: json.message });
        setExportando(false);
        return;
      }

      var ext = formatoExport === "csv" ? "csv" : "xlsx";
      var blob = new Blob([response.data]);
      var url = URL.createObjectURL(blob);
      var a = document.createElement("a");
      a.href = url;
      a.download = "reportes_saferoute_" + new Date().toISOString().split("T")[0] + "." + ext;
      a.click();
      URL.revokeObjectURL(url);
      setMensaje({ tipo: "ok", texto: "Archivo descargado correctamente" });
    } catch (err) {
      setMensaje({ tipo: "error", texto: err.response?.data?.message || "Error al exportar" });
    } finally { setExportando(false); }
  };

  var setFiltro = function (key, val) {
    setFiltros(function (f) { return { ...f, [key]: val }; });
    setPage(1);
  };

  var badgeEstado = function (estado) {
    var c = COLORES_ESTADO[estado] || COLORES_ESTADO.activo;
    return <span style={{ padding: "4px 10px", borderRadius: 12, fontSize: 11, fontWeight: 600, backgroundColor: c.bg, color: c.color }}>{estado.charAt(0).toUpperCase() + estado.slice(1)}</span>;
  };

  /* Opciones de cambio de estado según estado actual */
  var opcionesEstado = function (r) {
    var opciones = [];
    if (r.estado === "activo") {
      opciones.push({ label: "Ocultar", estado: "oculto", color: "#D97706", bg: "#FFFBEB" });
      opciones.push({ label: "Eliminar", estado: "eliminado", color: "#DC2626", bg: "#FEF2F2" });
    } else if (r.estado === "oculto") {
      opciones.push({ label: "Mostrar", estado: "activo", color: "#16A34A", bg: "#F0FDF4" });
      opciones.push({ label: "Eliminar", estado: "eliminado", color: "#DC2626", bg: "#FEF2F2" });
    } else if (r.estado === "eliminado") {
      opciones.push({ label: "Restaurar", estado: "activo", color: "#16A34A", bg: "#F0FDF4" });
    }
    return opciones;
  };

  var labelAccion = function (estadoActual, nuevoEstado) {
    if (nuevoEstado === "oculto") return "ocultar";
    if (nuevoEstado === "eliminado") return "eliminar";
    if (nuevoEstado === "activo" && estadoActual === "oculto") return "mostrar";
    if (nuevoEstado === "activo" && estadoActual === "eliminado") return "restaurar";
    return "cambiar";
  };

  return (
    <div style={{ display: "flex", flexDirection: "column", gap: 16, paddingBottom: 24 }}>
      {/* Toast */}
      {mensaje && (
        <div style={{ position: "fixed", top: 20, right: 20, padding: "12px 20px", borderRadius: 8, fontSize: 13, fontWeight: 600, fontFamily: "'Inter',sans-serif", zIndex: 9999, boxShadow: "0 4px 12px rgba(0,0,0,0.1)", backgroundColor: mensaje.tipo === "ok" ? "#DCFCE7" : "#FEE2E2", color: mensaje.tipo === "ok" ? "#16A34A" : "#DC2626" }}>
          {mensaje.texto}
        </div>
      )}

      {/* Modal cambio de estado */}
      {modalEstado && (
        <ModalBase onClose={function () { setModalEstado(null); }} maxWidth={420}>
          <div style={{ backgroundColor: modalEstado.nuevoEstado === "eliminado" ? "#FEF2F2" : modalEstado.nuevoEstado === "oculto" ? "#FFFBEB" : "#F0FDF4", padding: "16px 20px", borderRadius: "12px 12px 0 0", display: "flex", alignItems: "center", justifyContent: "space-between" }}>
            <h2 style={{ margin: 0, fontSize: 16, fontWeight: 600, color: "#1E293B", fontFamily: "'Inter',sans-serif" }}>Confirmar acción</h2>
            <button onClick={function () { setModalEstado(null); }} style={{ background: "none", border: "none", color: "#64748B", fontSize: 18, cursor: "pointer" }}>✕</button>
          </div>
          <div style={{ padding: "20px 24px" }}>
            <p style={{ color: "#1E293B", fontSize: 14, marginBottom: 16, lineHeight: 1.5 }}>
              ¿Estás seguro de <strong>{labelAccion(modalEstado.estadoActual, modalEstado.nuevoEstado)}</strong> este reporte?
            </p>
            <div style={{ backgroundColor: "#F8FAFC", borderRadius: 8, padding: "10px 14px", display: "flex", flexDirection: "column", gap: 4, marginBottom: 20, border: "0.5px solid #E2E8F0" }}>
              <div style={{ display: "flex", justifyContent: "space-between" }}><span style={{ fontSize: 12, fontWeight: 600, color: "#64748B" }}>ID</span><span style={{ fontSize: 12, color: "#1E293B" }}>{truncId(modalEstado.id)}</span></div>
              <div style={{ display: "flex", justifyContent: "space-between" }}><span style={{ fontSize: 12, fontWeight: 600, color: "#64748B" }}>Tipo</span><span style={{ fontSize: 12, color: "#1E293B" }}>{modalEstado.tipo_hurto ? modalEstado.tipo_hurto.charAt(0).toUpperCase() + modalEstado.tipo_hurto.slice(1) : ""}</span></div>
              <div style={{ display: "flex", justifyContent: "space-between" }}><span style={{ fontSize: 12, fontWeight: 600, color: "#64748B" }}>Estado actual</span>{badgeEstado(modalEstado.estadoActual)}</div>
              <div style={{ display: "flex", justifyContent: "space-between" }}><span style={{ fontSize: 12, fontWeight: 600, color: "#64748B" }}>Nuevo estado</span>{badgeEstado(modalEstado.nuevoEstado)}</div>
            </div>
            <div style={{ display: "flex", gap: 10 }}>
              <button onClick={function () { setModalEstado(null); }} disabled={procesando} style={{ flex: 1, height: 40, borderRadius: 8, border: "1px solid #CBD5E1", backgroundColor: "#fff", color: "#64748B", cursor: "pointer", fontSize: 14, fontWeight: 500 }}>Cancelar</button>
              <button onClick={confirmarCambioEstado} disabled={procesando} style={{ flex: 1, height: 40, borderRadius: 8, border: "none", backgroundColor: modalEstado.nuevoEstado === "eliminado" ? "#DC2626" : modalEstado.nuevoEstado === "oculto" ? "#D97706" : "#16A34A", color: "#fff", cursor: "pointer", fontSize: 14, fontWeight: 600 }}>
                {procesando ? "Procesando..." : "Confirmar"}
              </button>
            </div>
          </div>
        </ModalBase>
      )}

      {/* Filtros */}
      <div style={CARD}>
        <div style={{ display: "flex", alignItems: "center", gap: 10, flexWrap: "wrap" }}>
          <div style={{ flex: "1.5 1 160px", position: "relative" }}>
            <svg width="15" height="15" viewBox="0 0 24 24" fill="none" stroke="#94A3B8" strokeWidth="2" style={{ position: "absolute", left: 10, top: "50%", transform: "translateY(-50%)", pointerEvents: "none" }}><circle cx="11" cy="11" r="8"/><line x1="21" y1="21" x2="16.65" y2="16.65"/></svg>
            <input type="text" placeholder="Buscar..." value={filtros.busqueda} onChange={function (e) { setFiltro("busqueda", e.target.value); }} style={{ ...FI, paddingLeft: 34, width: "100%" }} />
          </div>
          <select value={filtros.estado} onChange={function (e) { setFiltro("estado", e.target.value); }} style={{ ...FI, flex: "1 1 100px" }}>{ESTADOS.map(function (s) { return <option key={s} value={s}>{s ? s.charAt(0).toUpperCase() + s.slice(1) : "Estado"}</option>; })}</select>
          <select value={filtros.comuna} onChange={function (e) { setFiltro("comuna", e.target.value); }} style={{ ...FI, flex: "1 1 100px" }}>{COMUNAS.map(function (c) { return <option key={c} value={c}>{c || "Comuna"}</option>; })}</select>
          <select value={filtros.tipo_hurto} onChange={function (e) { setFiltro("tipo_hurto", e.target.value); }} style={{ ...FI, flex: "1 1 100px" }}>{TIPOS.map(function (t) { return <option key={t} value={t}>{t ? t.charAt(0).toUpperCase() + t.slice(1) : "Tipo"}</option>; })}</select>
          <select value={filtros.franja} onChange={function (e) { setFiltro("franja", e.target.value); }} style={{ ...FI, flex: "1 1 100px" }}>{FRANJAS.map(function (f) { return <option key={f} value={f}>{f || "Horario"}</option>; })}</select>
          <input type="date" value={filtros.fechaDesde} onChange={function (e) { setFiltro("fechaDesde", e.target.value); }} style={{ ...FI, flex: "1 1 120px" }} />
          <input type="date" value={filtros.fechaHasta} onChange={function (e) { setFiltro("fechaHasta", e.target.value); }} style={{ ...FI, flex: "1 1 120px" }} />
          <select value={formatoExport} onChange={function (e) { setFormatoExport(e.target.value); }} style={{ ...FI, flex: "0 0 80px" }}>
            <option value="excel">Excel</option>
            <option value="csv">CSV</option>
          </select>
          <button onClick={descargarReportes} disabled={exportando} style={BTN_EXPORT}>
            {exportando ? (
              <span>Descargando...</span>
            ) : (
              <>
                <svg width="15" height="15" viewBox="0 0 24 24" fill="none" stroke="#fff" strokeWidth="2"><path d="M21 15v4a2 2 0 0 1-2 2H5a2 2 0 0 1-2-2v-4"/><polyline points="7 10 12 15 17 10"/><line x1="12" y1="15" x2="12" y2="3"/></svg>
                <span>Descargar</span>
              </>
            )}
          </button>
          <button onClick={function () { setFiltros({ busqueda: "", tipo_hurto: "", estado: "", comuna: "", franja: "", fechaDesde: "", fechaHasta: "" }); setPage(1); }} style={{ height: 38, padding: "0 14px", borderRadius: 8, border: "1px solid #CBD5E1", backgroundColor: "transparent", color: "#64748B", fontSize: 13, cursor: "pointer", whiteSpace: "nowrap", flexShrink: 0 }}>Limpiar</button>
        </div>
      </div>

      {/* Tabla */}
      {cargando ? (<p style={{ color: "#64748b", textAlign: "center", padding: 40, fontWeight: 300 }}>Cargando...</p>) : (
        <div style={CARD_TABLE}>
          <table style={{ width: "100%", borderCollapse: "collapse", fontSize: 13, fontFamily: "'Inter',sans-serif" }}>
            <thead><tr style={{ backgroundColor: "#2563EB" }}>
              <th style={{ ...TH, borderRadius: "8px 0 0 0" }}>FECHA</th>
              <th style={TH}>COMUNA</th>
              <th style={TH}>TIPO</th>
              <th style={TH}>ESTADO</th>
              <th style={{ ...TH, textAlign: "center", borderRadius: "0 8px 0 0" }}>ACCIONES</th>
            </tr></thead>
            <tbody>
              {reportes.length === 0 ? (
                <tr><td colSpan={5} style={{ padding: 40, textAlign: "center", color: "#94A3B8", fontSize: 14 }}>No se encontraron reportes</td></tr>
              ) : reportes.map(function (r, idx) {
                var bg = idx % 2 === 0 ? "#fff" : "#F8FAFC";
                var tipoColor = COLORES_TIPO[r.tipo_hurto] || "#64748b";
                var ops = opcionesEstado(r);
                return (
                  <tr key={r.id} style={{ backgroundColor: bg, borderBottom: "1px solid #F1F5F9" }}>
                    <td style={TD}>{fmtFecha(r.fecha_incidente)}</td>
                    <td style={TD}>{r.comuna ?? "—"}</td>
                    <td style={TD}><span style={{ backgroundColor: tipoColor + "26", color: tipoColor, padding: "4px 12px", borderRadius: 99, fontSize: 11, fontWeight: 500, fontFamily: "'Montserrat',sans-serif" }}>{r.tipo_hurto?.charAt(0).toUpperCase() + r.tipo_hurto?.slice(1)}</span></td>
                    <td style={TD}>{badgeEstado(r.estado)}</td>
                    <td style={{ ...TD, textAlign: "center" }}>
                      <div style={{ display: "flex", justifyContent: "center", alignItems: "center", gap: 6 }}>
                        <button onClick={function () { abrirModal(r.id, "ver"); }} style={BTN_ICO("#EFF6FF", "#2563EB")} title="Ver detalle"><svg width="15" height="15" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2"><path d="M1 12s4-8 11-8 11 8 11 8-4 8-11 8-11-8-11-8z"/><circle cx="12" cy="12" r="3"/></svg></button>
                        <button onClick={function () { abrirModalEditar(r.id); }} style={BTN_ICO("#FFFBEB", "#D97706")} title="Editar tipo"><svg width="15" height="15" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2"><path d="M17 3a2.83 2.83 0 1 1 4 4L7.5 20.5 2 22l1.5-5.5L17 3z"/></svg></button>
                        {ops.map(function (op) {
                          return <button key={op.estado} onClick={function () { abrirModalEstado(r, op.estado); }} style={BTN_ICO(op.bg, op.color)} title={op.label}>
                            {op.estado === "oculto" && <svg width="15" height="15" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2"><path d="M17.94 17.94A10.07 10.07 0 0 1 12 20c-7 0-11-8-11-8a18.45 18.45 0 0 1 5.06-5.94M9.9 4.24A9.12 9.12 0 0 1 12 4c7 0 11 8 11 8a18.5 18.5 0 0 1-2.16 3.19m-6.72-1.07a3 3 0 1 1-4.24-4.24"/><line x1="1" y1="1" x2="23" y2="23"/></svg>}
                            {op.estado === "eliminado" && <svg width="15" height="15" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2"><polyline points="3 6 5 6 21 6"/><path d="M19 6v14a2 2 0 0 1-2 2H7a2 2 0 0 1-2-2V6m3 0V4a2 2 0 0 1 2-2h4a2 2 0 0 1 2 2v2"/></svg>}
                            {op.estado === "activo" && <svg width="15" height="15" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2"><polyline points="20 6 9 17 4 12"/></svg>}
                          </button>;
                        })}
                      </div>
                    </td>
                  </tr>
                );
              })}
            </tbody>
          </table>
          <div style={{ display: "flex", justifyContent: "space-between", alignItems: "center", padding: "12px 16px", borderTop: "1px solid #F1F5F9" }}>
            <span style={{ color: "#64748b", fontSize: 13, fontWeight: 300 }}>Página {page} de {totalPages} — {total} reportes</span>
            <div style={{ display: "flex", gap: 4 }}>
              <button onClick={function () { setPage(function (p) { return Math.max(1, p - 1); }); }} disabled={page === 1} style={BTN_PAG}>‹</button>
              <button onClick={function () { setPage(function (p) { return Math.min(totalPages, p + 1); }); }} disabled={page === totalPages} style={BTN_PAG}>›</button>
            </div>
          </div>
        </div>
      )}

      {/* Modal Editar tipo de hurto */}
      {modalEditar && (
        <ModalBase onClose={function () { setModalEditar(null); }} maxWidth={420}>
          <div style={{ padding: "20px 24px" }}>
            <h2 style={{ margin: "0 0 16px", fontSize: 16, fontWeight: 600, color: "#1E293B", fontFamily: "'Inter',sans-serif" }}>Editar tipo de hurto</h2>
            <div style={{ backgroundColor: "#F8FAFC", borderRadius: 8, padding: "10px 14px", marginBottom: 16, border: "0.5px solid #E2E8F0" }}>
              <div style={{ display: "flex", justifyContent: "space-between", marginBottom: 4 }}>
                <span style={{ fontSize: 12, fontWeight: 600, color: "#64748B" }}>ID</span>
                <span style={{ fontSize: 12, color: "#1E293B" }}>{truncId(modalEditar.id)}</span>
              </div>
              <div style={{ display: "flex", justifyContent: "space-between" }}>
                <span style={{ fontSize: 12, fontWeight: 600, color: "#64748B" }}>Tipo actual</span>
                <span style={{ fontSize: 12, color: "#1E293B" }}>{modalEditar.tipoActual ? modalEditar.tipoActual.charAt(0).toUpperCase() + modalEditar.tipoActual.slice(1) : ""}</span>
              </div>
            </div>
            {(!modalEditar.descripcion || modalEditar.descripcion.trim().length === 0) && (
              <div style={{ backgroundColor: "#FEF3C7", borderRadius: 8, padding: "10px 14px", marginBottom: 16, border: "0.5px solid #FCD34D", fontSize: 13, color: "#92400E" }}>
                Este reporte no tiene descripción. No se puede editar el tipo de hurto hasta que tenga una.
              </div>
            )}
            <label style={{ fontSize: 12, color: "#64748B", fontWeight: 500, display: "block", marginBottom: 6 }}>Nuevo tipo de hurto</label>
            <select value={nuevoTipo} onChange={function (e) { setNuevoTipo(e.target.value); }} disabled={!modalEditar.descripcion || modalEditar.descripcion.trim().length === 0} style={{ width: "100%", height: 40, padding: "0 12px", borderRadius: 8, border: "0.5px solid #CBD5E1", fontSize: 13, color: "#1E293B", backgroundColor: "#F8FAFC", marginBottom: 20 }}>
              {["atraco", "raponazo", "cosquilleo", "fleteo"].map(function (t) {
                return <option key={t} value={t}>{t.charAt(0).toUpperCase() + t.slice(1)}</option>;
              })}
            </select>
            <div style={{ display: "flex", gap: 10 }}>
              <button onClick={function () { setModalEditar(null); }} style={{ flex: 1, height: 40, borderRadius: 8, border: "1px solid #CBD5E1", backgroundColor: "#fff", color: "#64748B", cursor: "pointer", fontSize: 14, fontWeight: 500 }}>Cancelar</button>
              <button onClick={confirmarEdicion} disabled={procesando || nuevoTipo === modalEditar.tipoActual || !modalEditar.descripcion || modalEditar.descripcion.trim().length === 0} style={{ flex: 1, height: 40, borderRadius: 8, border: "none", backgroundColor: (nuevoTipo === modalEditar.tipoActual || !modalEditar.descripcion) ? "#CBD5E1" : "#2563EB", color: "#fff", cursor: "pointer", fontSize: 14, fontWeight: 600 }}>
                {procesando ? "Guardando..." : "Guardar"}
              </button>
            </div>
          </div>
        </ModalBase>
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
            <Fila label="ID" valor={<span style={{ display: "flex", alignItems: "center", gap: 6 }}>{truncId(detalle.id)}<button onClick={function () { copyId(detalle.id); }} style={{ background: "none", border: "none", cursor: "pointer", padding: 0, color: "#64748B" }} title="Copiar ID"><svg width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2"><rect x="9" y="9" width="13" height="13" rx="2"/><path d="M5 15H4a2 2 0 0 1-2-2V4a2 2 0 0 1 2-2h9a2 2 0 0 1 2 2v1"/></svg></button></span>} />
            <Fila label="Estado" valor={badgeEstado(detalle.estado)} />
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
                <div style={{ borderRadius: 10, overflow: "hidden", border: "0.5px solid #CBD5E1" }}>
                  <img src={"https://api.mapbox.com/styles/v1/mapbox/streets-v12/static/pin-s+B91C1C(" + detalle.longitud + "," + detalle.latitud + ")/" + detalle.longitud + "," + detalle.latitud + ",15,0/440x180@2x?access_token=" + MAPBOX_TOKEN} alt="Ubicación" style={{ width: "100%", height: 180, objectFit: "cover", display: "block" }} />
                </div>
                <div style={{ display: "flex", justifyContent: "center", marginTop: 8 }}>
                  <a href={"https://www.google.com/maps?q=" + detalle.latitud + "," + detalle.longitud} target="_blank" rel="noopener noreferrer" style={{ display: "inline-flex", alignItems: "center", gap: 6, fontSize: 12, color: "#2563EB", textDecoration: "none", fontWeight: 500 }}>
                    <svg width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="#2563EB" strokeWidth="2"><path d="M21 10c0 7-9 13-9 13s-9-6-9-13a9 9 0 0 1 18 0z"/><circle cx="12" cy="10" r="3"/></svg>
                    Ver en Google Maps
                  </a>
                </div>
              </div>
            )}
          </div>
        </ModalBase>
      )}
    </div>
  );
}

function ModalBase(props) {
  return (
    <div style={{ position: "fixed", inset: 0, backgroundColor: "rgba(0,0,0,0.5)", display: "flex", alignItems: "center", justifyContent: "center", zIndex: 1000 }} onClick={props.onClose}>
      <div style={{ backgroundColor: "#fff", borderRadius: 12, width: "100%", maxWidth: props.maxWidth || 480, maxHeight: "85vh", overflowY: "auto", boxShadow: "0 20px 60px rgba(0,0,0,0.3)" }} onClick={function (e) { e.stopPropagation(); }}>
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

function BTN_ICO(bg, color) { return { width: 30, height: 30, borderRadius: 6, border: "none", backgroundColor: bg, cursor: "pointer", display: "flex", alignItems: "center", justifyContent: "center", color: color }; }

var CARD = { backgroundColor: "#fff", borderRadius: 12, padding: 16, border: "0.5px solid #CBD5E1", boxShadow: "0 1px 4px rgba(0,0,0,0.06)" };
var CARD_TABLE = { backgroundColor: "#fff", borderRadius: 12, border: "0.5px solid #CBD5E1", boxShadow: "0 1px 4px rgba(0,0,0,0.06)", overflow: "hidden" };
var FI = { height: 38, padding: "0 10px", borderRadius: 8, border: "0.5px solid #CBD5E1", fontSize: 13, color: "#1E293B", fontFamily: "'Inter',sans-serif", backgroundColor: "#F8FAFC", boxSizing: "border-box" };
var TH = { padding: "12px 16px", textAlign: "left", color: "#fff", fontWeight: 500, fontSize: 12, textTransform: "uppercase", letterSpacing: 0.5, fontFamily: "'Inter',sans-serif" };
var TD = { padding: "12px 16px", color: "#1E293B", fontFamily: "'Inter',sans-serif" };
var BTN_EXPORT = { display: "flex", alignItems: "center", gap: 6, height: 38, padding: "0 16px", borderRadius: 8, border: "none", backgroundColor: "#10B981", color: "#fff", fontFamily: "'Montserrat',sans-serif", fontWeight: 500, fontSize: 13, cursor: "pointer", whiteSpace: "nowrap", flexShrink: 0 };
var BTN_PAG = { width: 32, height: 32, borderRadius: 6, border: "1px solid #E2E8F0", backgroundColor: "#fff", cursor: "pointer", fontSize: 16 };
