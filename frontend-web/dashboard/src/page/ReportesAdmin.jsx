import { useState, useEffect, useCallback } from "react";
import { getReportesAdmin, getReporteById } from "../services/reportService";
import ReporteDetalle from "./ReporteDetalle";

const TIPOS   = ["", "atraco", "raponazo", "cosquilleo", "fleteo"];
const ESTADOS = ["", "activo", "oculto"];

const colores = {
  atraco:     "#b91c1c",
  raponazo:   "#0891b2",
  fleteo:     "#d946ef",
  cosquilleo: "#7c3aed",
};

export default function ReportesAdmin() {
  const [reportes,    setReportes]    = useState([]);
  const [total,       setTotal]       = useState(0);
  const [page,        setPage]        = useState(1);
  const [totalPages,  setTotalPages]  = useState(1);
  const [cargando,    setCargando]    = useState(true);
  const [detalle,     setDetalle]     = useState(null);

  const [filtros, setFiltros] = useState({
    tipo_hurto: "", estado: "", fechaDesde: "", fechaHasta: "", comuna: "",
  });

  const cargar = useCallback(async () => {
    setCargando(true);
    try {
      const params = { page, limit: 10 };
      if (filtros.tipo_hurto) params.tipo_hurto = filtros.tipo_hurto;
      if (filtros.estado)     params.estado     = filtros.estado;
      if (filtros.fechaDesde) params.fechaDesde = filtros.fechaDesde;
      if (filtros.fechaHasta) params.fechaHasta = filtros.fechaHasta;
      if (filtros.comuna)     params.comuna     = filtros.comuna;

      const res = await getReportesAdmin(params);
      setReportes(res.data);
      setTotal(res.total);
      setTotalPages(res.totalPages);
    } catch (e) {
      console.error(e);
    } finally {
      setCargando(false);
    }
  }, [page, filtros]);

  useEffect(() => { cargar(); }, [cargar]);

  const abrirDetalle = async (id) => {
    try {
      const data = await getReporteById(id);
      setDetalle(data);
    } catch (e) {
      console.error(e);
    }
  };

  const aplicarFiltros = (e) => {
    e.preventDefault();
    setPage(1);
    cargar();
  };

  const limpiarFiltros = () => {
    setFiltros({ tipo_hurto: "", estado: "", fechaDesde: "", fechaHasta: "", comuna: "" });
    setPage(1);
  };

  return (
    <div>
      {/* Filtros */}
      <form onSubmit={aplicarFiltros} style={styles.filtrosForm}>
        <select
          value={filtros.tipo_hurto}
          onChange={(e) => setFiltros(f => ({ ...f, tipo_hurto: e.target.value }))}
          style={styles.select}
        >
          {TIPOS.map(t => <option key={t} value={t}>{t || "Todos los tipos"}</option>)}
        </select>

        <select
          value={filtros.estado}
          onChange={(e) => setFiltros(f => ({ ...f, estado: e.target.value }))}
          style={styles.select}
        >
          {ESTADOS.map(e => <option key={e} value={e}>{e || "Todos los estados"}</option>)}
        </select>

        <input
          type="number" placeholder="Comuna (1-12)"
          value={filtros.comuna} min="1" max="12"
          onChange={(e) => setFiltros(f => ({ ...f, comuna: e.target.value }))}
          style={styles.input}
        />

        <input
          type="date" value={filtros.fechaDesde}
          onChange={(e) => setFiltros(f => ({ ...f, fechaDesde: e.target.value }))}
          style={styles.input}
        />

        <input
          type="date" value={filtros.fechaHasta}
          onChange={(e) => setFiltros(f => ({ ...f, fechaHasta: e.target.value }))}
          style={styles.input}
        />

        <button type="submit" style={styles.btnAplicar}>Filtrar</button>
        <button type="button" onClick={limpiarFiltros} style={styles.btnLimpiar}>Limpiar</button>
      </form>

      {/* Contador */}
      <p style={styles.contador}>{total} reporte(s) encontrado(s)</p>

      {/* Tabla */}
      {cargando ? (
        <p style={{ color: "#64748b" }}>Cargando...</p>
      ) : (
        <div style={styles.tableWrapper}>
          <table style={styles.table}>
            <thead>
              <tr style={styles.thead}>
                <th style={styles.th}>Tipo</th>
                <th style={styles.th}>Barrio</th>
                <th style={styles.th}>Comuna</th>
                <th style={styles.th}>Fecha</th>
                <th style={styles.th}>Franja</th>
                <th style={styles.th}>Estado</th>
              </tr>
            </thead>
            <tbody>
              {reportes.map((r) => (
                <tr
                  key={r.id}
                  style={styles.tr}
                  onClick={() => abrirDetalle(r.id)}
                >
                  <td style={styles.td}>
                    <span style={styles.badge(r.tipo_hurto)}>{r.tipo_hurto}</span>
                  </td>
                  <td style={styles.td}>{r.barrio_ingresado}</td>
                  <td style={styles.td}>{r.comuna ?? "—"}</td>
                  <td style={styles.td}>{r.fecha_incidente}</td>
                  <td style={styles.td}>{r.franja_horaria}</td>
                  <td style={styles.td}>
                    <span style={styles.estadoBadge(r.estado)}>{r.estado}</span>
                  </td>
                </tr>
              ))}
            </tbody>
          </table>
        </div>
      )}

      {/* Paginación */}
      <div style={styles.paginacion}>
        <button
          onClick={() => setPage(p => Math.max(1, p - 1))}
          disabled={page === 1}
          style={styles.btnPag(page === 1)}
        >
          ← Anterior
        </button>
        <span style={styles.paginaInfo}>Página {page} de {totalPages}</span>
        <button
          onClick={() => setPage(p => Math.min(totalPages, p + 1))}
          disabled={page === totalPages}
          style={styles.btnPag(page === totalPages)}
        >
          Siguiente →
        </button>
      </div>

      {/* Modal detalle */}
      {detalle && <ReporteDetalle reporte={detalle} onClose={() => setDetalle(null)} />}
    </div>
  );
}

const styles = {
  filtrosForm: {
    display: "flex", flexWrap: "wrap", gap: "8px",
    marginBottom: "16px", alignItems: "center",
  },
  select: {
    padding: "8px 12px", borderRadius: "8px",
    border: "1px solid #cbd5e1", fontSize: "13px", color: "#1e293b",
  },
  input: {
    padding: "8px 12px", borderRadius: "8px",
    border: "1px solid #cbd5e1", fontSize: "13px", color: "#1e293b",
  },
  btnAplicar: {
    padding: "8px 16px", borderRadius: "8px",
    backgroundColor: "#2563eb", color: "#fff",
    border: "none", cursor: "pointer", fontSize: "13px",
  },
  btnLimpiar: {
    padding: "8px 16px", borderRadius: "8px",
    backgroundColor: "#f1f5f9", color: "#64748b",
    border: "1px solid #cbd5e1", cursor: "pointer", fontSize: "13px",
  },
  contador: { color: "#64748b", fontSize: "13px", marginBottom: "8px" },
  tableWrapper: { overflowX: "auto" },
  table: { width: "100%", borderCollapse: "collapse", fontSize: "13px" },
  thead: { backgroundColor: "#f8fafc" },
  th: {
    padding: "10px 14px", textAlign: "left",
    color: "#64748b", fontWeight: "600",
    borderBottom: "2px solid #e2e8f0",
  },
  tr: {
    cursor: "pointer",
    transition: "background 0.15s",
    borderBottom: "1px solid #f1f5f9",
  },
  td: { padding: "10px 14px", color: "#1e293b" },
  badge: (tipo) => ({
    padding: "3px 10px", borderRadius: "12px",
    backgroundColor: colores[tipo] || "#64748b",
    color: "#fff", fontSize: "11px", fontWeight: "600",
  }),
  estadoBadge: (estado) => ({
    padding: "3px 10px", borderRadius: "12px",
    backgroundColor: estado === "activo" ? "#dcfce7" : "#fef9c3",
    color: estado === "activo" ? "#166534" : "#854d0e",
    fontSize: "11px", fontWeight: "600",
  }),
  paginacion: {
    display: "flex", alignItems: "center", gap: "16px",
    marginTop: "16px", justifyContent: "center",
  },
  paginaInfo: { color: "#64748b", fontSize: "13px" },
  btnPag: (disabled) => ({
    padding: "8px 16px", borderRadius: "8px",
    backgroundColor: disabled ? "#f1f5f9" : "#2563eb",
    color: disabled ? "#94a3b8" : "#fff",
    border: "none", cursor: disabled ? "not-allowed" : "pointer",
    fontSize: "13px",
  }),
};
