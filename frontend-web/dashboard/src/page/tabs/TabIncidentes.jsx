import { useState, useEffect, useCallback } from "react";
import { getReportesAdmin, getReporteById } from "../../services/reportService";

const TIPOS = ["", "atraco", "raponazo", "cosquilleo", "fleteo"];
const COMUNAS = ["", ...Array.from({ length: 12 }, (_, i) => String(i + 1))];
const FRANJAS = ["", "00:00-05:59", "06:00-11:59", "12:00-17:59", "18:00-23:59"];

const COLORES_TIPO = {
  atraco: "#B91C1C",
  raponazo: "#9D174D",
  fleteo: "#D946EF",
  cosquilleo: "#8A2BE2",
};

export default function TabIncidentes({ onCountChange }) {
  const [reportes, setReportes] = useState([]);
  const [total, setTotal] = useState(0);
  const [page, setPage] = useState(1);
  const [totalPages, setTotalPages] = useState(1);
  const [cargando, setCargando] = useState(true);
  const [detalle, setDetalle] = useState(null);
  const [modalType, setModalType] = useState(null); // 'ver' | 'editar' | 'eliminar'

  const [filtros, setFiltros] = useState({
    busqueda: "", tipo_hurto: "", comuna: "", franja: "",
    fechaDesde: "", fechaHasta: "",
  });

  const cargar = useCallback(async () => {
    setCargando(true);
    try {
      const params = { page, limit: 10 };
      if (filtros.tipo_hurto) params.tipo_hurto = filtros.tipo_hurto;
      if (filtros.comuna) params.comuna = filtros.comuna;
      if (filtros.fechaDesde) params.fechaDesde = filtros.fechaDesde;
      if (filtros.fechaHasta) params.fechaHasta = filtros.fechaHasta;
      if (filtros.busqueda) params.busqueda = filtros.busqueda;

      const res = await getReportesAdmin(params);
      setReportes(res.data || []);
      setTotal(res.total || 0);
      setTotalPages(res.totalPages || 1);
      onCountChange?.(res.total || 0);
    } catch (e) {
      console.error(e);
    } finally {
      setCargando(false);
    }
  }, [page, filtros, onCountChange]);

  useEffect(() => { cargar(); }, [cargar]);

  const abrirModal = async (id, type) => {
    try {
      const data = await getReporteById(id);
      setDetalle(data);
      setModalType(type);
    } catch (e) { console.error(e); }
  };

  const exportarExcel = () => {
    const headers = ["Fecha", "Comuna", "Tipo", "Barrio", "Franja", "Usuario", "Estado"];
    const rows = reportes.map(r => [
      r.fecha_incidente, r.comuna ?? "", r.tipo_hurto,
      r.barrio_ingresado, r.franja_horaria,
      r.usuarios?.username ?? r.usuario_id, r.estado,
    ]);
    const csv = [headers, ...rows].map(r => r.join(",")).join("\n");
    const bom = "\uFEFF";
    const blob = new Blob([bom + csv], { type: "text/csv;charset=utf-8;" });
    const url = URL.createObjectURL(blob);
    const a = document.createElement("a");
    a.href = url;
    a.download = `incidentes_saferoute_${new Date().toISOString().split("T")[0]}.csv`;
    a.click();
    URL.revokeObjectURL(url);
  };

  const limpiarFiltros = () => {
    setFiltros({ busqueda: "", tipo_hurto: "", comuna: "", franja: "", fechaDesde: "", fechaHasta: "" });
    setPage(1);
  };

  return (
    <div>
      {/* Filtros */}
      <div style={styles.filtrosCard}>
        <h3 style={styles.filtrosTitulo}>Filtros</h3>
        <input
          type="text" placeholder="🔍 Buscar..."
          value={filtros.busqueda}
          onChange={(e) => setFiltros(f => ({ ...f, busqueda: e.target.value }))}
          style={{ ...styles.input, width: "100%", marginBottom: "8px" }}
        />
        <div style={styles.filtrosRow}>
          <select value={filtros.comuna} onChange={(e) => setFiltros(f => ({ ...f, comuna: e.target.value }))} style={styles.select}>
            {COMUNAS.map(c => <option key={c} value={c}>{c || "Todas las comunas"}</option>)}
          </select>
          <select value={filtros.tipo_hurto} onChange={(e) => setFiltros(f => ({ ...f, tipo_hurto: e.target.value }))} style={styles.select}>
            {TIPOS.map(t => <option key={t} value={t}>{t ? t.charAt(0).toUpperCase() + t.slice(1) : "Todos los tipos"}</option>)}
          </select>
        </div>
        <select value={filtros.franja} onChange={(e) => setFiltros(f => ({ ...f, franja: e.target.value }))} style={{ ...styles.select, width: "100%", marginBottom: "8px" }}>
          {FRANJAS.map(f => <option key={f} value={f}>{f || "Todos los horarios"}</option>)}
        </select>
        <div style={styles.filtrosRow}>
          <input type="date" value={filtros.fechaDesde} onChange={(e) => setFiltros(f => ({ ...f, fechaDesde: e.target.value }))} style={styles.input} placeholder="Desde" />
          <input type="date" value={filtros.fechaHasta} onChange={(e) => setFiltros(f => ({ ...f, fechaHasta: e.target.value }))} style={styles.input} placeholder="Hasta" />
        </div>
        <button onClick={exportarExcel} style={styles.btnExportar}>📥 Exportar a Excel</button>
      </div>

      {/* Tabla */}
      {cargando ? (
        <p style={{ color: "#64748b", textAlign: "center", padding: "40px" }}>Cargando...</p>
      ) : (
        <div style={styles.tableCard}>
          <table style={styles.table}>
            <thead>
              <tr>
                {["FECHA", "COMUNA", "TIPO", "USUARIO", "ACCIONES"].map(h => (
                  <th key={h} style={styles.th}>{h}</th>
                ))}
              </tr>
            </thead>
            <tbody>
              {reportes.map((r) => (
                <tr key={r.id} style={styles.tr}>
                  <td style={styles.td}>{r.fecha_incidente}</td>
                  <td style={styles.td}>{r.comuna ?? "—"}</td>
                  <td style={styles.td}>
                    <span style={{ ...styles.badge, backgroundColor: COLORES_TIPO[r.tipo_hurto] || "#64748b" }}>
                      {r.tipo_hurto?.charAt(0).toUpperCase() + r.tipo_hurto?.slice(1)}
                    </span>
                  </td>
                  <td style={styles.td}>{r.usuarios?.username ?? "—"}</td>
                  <td style={styles.td}>
                    <div style={styles.acciones}>
                      <button onClick={() => abrirModal(r.id, "ver")} style={styles.btnAccion} title="Ver">👁️</button>
                      <button onClick={() => abrirModal(r.id, "editar")} style={{ ...styles.btnAccion, color: "#2563EB" }} title="Editar">✏️</button>
                      <button onClick={() => abrirModal(r.id, "eliminar")} style={{ ...styles.btnAccion, color: "#EF4444" }} title="Eliminar">🗑️</button>
                    </div>
                  </td>
                </tr>
              ))}
            </tbody>
          </table>

          {/* Paginación */}
          <div style={styles.paginacion}>
            <span style={styles.pagInfo}>Página {page} de {totalPages}</span>
            <div style={styles.pagBtns}>
              <button onClick={() => setPage(p => Math.max(1, p - 1))} disabled={page === 1} style={styles.pagBtn}>‹</button>
              <button onClick={() => setPage(p => Math.min(totalPages, p + 1))} disabled={page === totalPages} style={styles.pagBtn}>›</button>
            </div>
          </div>
        </div>
      )}

      {/* Modal Ver Detalle */}
      {detalle && modalType === "ver" && (
        <ModalOverlay onClose={() => setDetalle(null)}>
          <h2 style={styles.modalTitle}>Detalle del Incidente</h2>
          <div style={{ ...styles.badge, backgroundColor: COLORES_TIPO[detalle.tipo_hurto] || "#64748b", marginBottom: "16px" }}>
            {detalle.tipo_hurto?.toUpperCase()}
          </div>
          <Campo label="ID" valor={detalle.id} />
          <Campo label="Estado" valor={detalle.estado} />
          <Campo label="Tipo reportante" valor={detalle.tipo_reportante} />
          <Campo label="Fecha incidente" valor={detalle.fecha_incidente} />
          <Campo label="Franja horaria" valor={detalle.franja_horaria} />
          <Campo label="Barrio" valor={detalle.barrio_ingresado} />
          <Campo label="Comuna" valor={detalle.comuna ? `Comuna ${detalle.comuna}` : null} />
          <Campo label="Coordenadas" valor={detalle.latitud ? `${detalle.latitud}, ${detalle.longitud}` : null} />
          <Campo label="Objeto hurtado" valor={detalle.objeto_hurtado} />
          <Campo label="N° agresores" valor={detalle.numero_agresores} />
          <Campo label="Descripción" valor={detalle.descripcion} />
        </ModalOverlay>
      )}

      {/* Modal Editar — placeholder hasta que lleguen los endpoints */}
      {detalle && modalType === "editar" && (
        <ModalOverlay onClose={() => setDetalle(null)}>
          <h2 style={styles.modalTitle}>Editar Incidente</h2>
          <p style={{ color: "#64748b", fontSize: "14px" }}>
            Los endpoints de edición se conectarán próximamente.
          </p>
          <Campo label="ID" valor={detalle.id} />
          <Campo label="Tipo hurto" valor={detalle.tipo_hurto} />
          <Campo label="Estado" valor={detalle.estado} />
        </ModalOverlay>
      )}

      {/* Modal Eliminar — placeholder hasta que lleguen los endpoints */}
      {detalle && modalType === "eliminar" && (
        <ModalOverlay onClose={() => setDetalle(null)}>
          <h2 style={{ ...styles.modalTitle, color: "#EF4444" }}>Eliminar Incidente</h2>
          <p style={{ color: "#64748b", fontSize: "14px", marginBottom: "16px" }}>
            ¿Estás seguro de que deseas ocultar este incidente? Esta acción cambiará su estado a "oculto".
          </p>
          <Campo label="ID" valor={detalle.id} />
          <Campo label="Tipo" valor={detalle.tipo_hurto} />
          <Campo label="Fecha" valor={detalle.fecha_incidente} />
          <div style={{ display: "flex", gap: "8px", marginTop: "16px" }}>
            <button onClick={() => setDetalle(null)} style={styles.btnCancelar}>Cancelar</button>
            <button onClick={() => { /* TODO: conectar DELETE */ setDetalle(null); }} style={styles.btnEliminar}>Confirmar</button>
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
  filtrosCard: {
    backgroundColor: "#fff", borderRadius: "12px", padding: "20px",
    boxShadow: "0 1px 4px rgba(0,0,0,0.06)", marginBottom: "16px",
  },
  filtrosTitulo: { margin: "0 0 12px", fontSize: "15px", color: "#2563EB", fontWeight: "600" },
  filtrosRow: { display: "flex", gap: "8px", marginBottom: "8px" },
  select: {
    flex: 1, padding: "10px 12px", borderRadius: "8px",
    border: "1px solid #cbd5e1", fontSize: "13px", color: "#1e293b",
    backgroundColor: "#fff",
  },
  input: {
    flex: 1, padding: "10px 12px", borderRadius: "8px",
    border: "1px solid #cbd5e1", fontSize: "13px", color: "#1e293b",
  },
  btnExportar: {
    width: "100%", padding: "12px", borderRadius: "8px",
    backgroundColor: "#22C55E", color: "#fff",
    border: "none", cursor: "pointer", fontSize: "14px", fontWeight: "600",
    marginTop: "4px",
  },
  tableCard: {
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
  tr: { borderBottom: "1px solid #f1f5f9", transition: "background 0.15s" },
  td: { padding: "12px 16px", color: "#1e293b" },
  badge: {
    display: "inline-block", padding: "4px 12px", borderRadius: "20px",
    color: "#fff", fontSize: "11px", fontWeight: "600",
  },
  acciones: { display: "flex", gap: "4px" },
  btnAccion: {
    width: "32px", height: "32px", borderRadius: "6px",
    border: "1px solid #e2e8f0", backgroundColor: "#fff",
    cursor: "pointer", fontSize: "14px",
    display: "flex", alignItems: "center", justifyContent: "center",
  },
  paginacion: {
    display: "flex", justifyContent: "space-between", alignItems: "center",
    padding: "12px 16px", borderTop: "1px solid #f1f5f9",
  },
  pagInfo: { color: "#64748b", fontSize: "13px" },
  pagBtns: { display: "flex", gap: "4px" },
  pagBtn: {
    width: "32px", height: "32px", borderRadius: "6px",
    border: "1px solid #e2e8f0", backgroundColor: "#fff",
    cursor: "pointer", fontSize: "16px",
  },
  overlay: {
    position: "fixed", inset: 0, backgroundColor: "rgba(0,0,0,0.5)",
    display: "flex", alignItems: "center", justifyContent: "center", zIndex: 1000,
  },
  modal: {
    backgroundColor: "#fff", borderRadius: "12px", width: "100%", maxWidth: "520px",
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
