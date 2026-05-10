/**
 * Modal con el detalle completo de un reporte de hurto.
 */
export default function ReporteDetalle({ reporte, onClose }) {
  if (!reporte) return null;

  const campo = (label, valor) =>
    valor ? (
      <div style={styles.campo}>
        <span style={styles.label}>{label}</span>
        <span style={styles.valor}>{valor}</span>
      </div>
    ) : null;

  return (
    <div style={styles.overlay} onClick={onClose}>
      <div style={styles.modal} onClick={(e) => e.stopPropagation()}>
        <div style={styles.header}>
          <h2 style={styles.titulo}>Detalle del reporte</h2>
          <button style={styles.cerrar} onClick={onClose}>✕</button>
        </div>

        <div style={styles.body}>
          <div style={styles.badge(reporte.tipo_hurto)}>
            {reporte.tipo_hurto?.toUpperCase()}
          </div>

          {campo("ID",               reporte.id)}
          {campo("Estado",           reporte.estado)}
          {campo("Tipo reportante",  reporte.tipo_reportante)}
          {campo("Fecha incidente",  reporte.fecha_incidente)}
          {campo("Franja horaria",   reporte.franja_horaria)}
          {campo("Barrio",           reporte.barrio_ingresado)}
          {campo("Comuna",           reporte.comuna ? `Comuna ${reporte.comuna}` : null)}
          {campo("Coordenadas",      reporte.latitud ? `${reporte.latitud}, ${reporte.longitud}` : null)}
          {campo("Objeto hurtado",   reporte.objeto_hurtado)}
          {campo("N° agresores",     reporte.numero_agresores)}
          {campo("Descripción",      reporte.descripcion)}
          {campo("Fecha creación",   reporte.fecha_creacion ? new Date(reporte.fecha_creacion).toLocaleString("es-CO") : null)}
        </div>
      </div>
    </div>
  );
}

const colores = {
  atraco:     "#b91c1c",
  raponazo:   "#0891b2",
  fleteo:     "#d946ef",
  cosquilleo: "#7c3aed",
};

const styles = {
  overlay: {
    position: "fixed", inset: 0,
    backgroundColor: "rgba(0,0,0,0.5)",
    display: "flex", alignItems: "center", justifyContent: "center",
    zIndex: 1000,
  },
  modal: {
    backgroundColor: "#fff",
    borderRadius: "12px",
    width: "100%", maxWidth: "520px",
    maxHeight: "85vh", overflowY: "auto",
    boxShadow: "0 20px 60px rgba(0,0,0,0.3)",
  },
  header: {
    display: "flex", justifyContent: "space-between", alignItems: "center",
    padding: "20px 24px 16px",
    borderBottom: "1px solid #e2e8f0",
  },
  titulo: { margin: 0, fontSize: "18px", color: "#1e293b" },
  cerrar: {
    background: "none", border: "none",
    fontSize: "18px", cursor: "pointer", color: "#64748b",
  },
  body: { padding: "20px 24px" },
  badge: (tipo) => ({
    display: "inline-block",
    padding: "4px 12px",
    borderRadius: "20px",
    backgroundColor: colores[tipo] || "#64748b",
    color: "#fff",
    fontSize: "12px",
    fontWeight: "600",
    marginBottom: "16px",
  }),
  campo: {
    display: "flex", justifyContent: "space-between",
    padding: "8px 0",
    borderBottom: "1px solid #f1f5f9",
  },
  label: { color: "#64748b", fontSize: "13px" },
  valor: { color: "#1e293b", fontSize: "13px", fontWeight: "500", textAlign: "right", maxWidth: "60%" },
};
