-- =============================================================
-- Migración 011: Vista dashboard de incidentes (HU-10)
-- =============================================================

CREATE OR REPLACE VIEW public.vw_dashboard_incidentes AS
SELECT i.id, i.tipo_hurto, i.fecha_incidente,
    (EXTRACT(year FROM i.fecha_incidente))::integer AS anio,
    (EXTRACT(month FROM i.fecha_incidente))::integer AS mes,
    to_char(i.fecha_incidente::timestamp with time zone, 'TMMonth') AS nombre_mes,
    i.franja_horaria,
    (i.comuna)::text AS comuna,
    z.barrio,
    i.cantidad_reportes,
    i.latitud_centro, i.longitud_centro,
    public.calcular_nivel_riesgo(i.cantidad_reportes) AS nivel_riesgo,
    (SELECT count(*) FROM public.reportes r2
     WHERE r2.incidente_id = i.id AND r2.tipo_reportante = 'victima' AND r2.estado = 'activo') AS victimas,
    (SELECT count(*) FROM public.reportes r3
     WHERE r3.incidente_id = i.id AND r3.tipo_reportante = 'testigo' AND r3.estado = 'activo') AS testigos,
    i.fecha_creacion
FROM public.incidentes i
LEFT JOIN public.zonas z ON i.zona_id = z.id
JOIN public.reportes r ON r.id = i.reporte_principal_id
WHERE r.estado = 'activo';

-- Índices de soporte para panel admin
CREATE INDEX IF NOT EXISTS idx_reportes_estado_tipo_hurto  ON public.reportes (estado, tipo_hurto);
CREATE INDEX IF NOT EXISTS idx_reportes_estado_comuna_tipo ON public.reportes (estado, comuna, tipo_hurto);
CREATE INDEX IF NOT EXISTS idx_reportes_fecha_zona_tipo    ON public.reportes (fecha_incidente, zona_id, tipo_hurto);
