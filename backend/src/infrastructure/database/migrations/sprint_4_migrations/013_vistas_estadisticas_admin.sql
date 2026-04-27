-- Migración 013: Vistas de estadísticas avanzadas admin (HU-15)

CREATE OR REPLACE VIEW public.vw_estadisticas_admin AS
SELECT
    r.comuna, z.barrio, r.tipo_hurto, r.franja_horaria,
    r.estado AS estado_reporte,
    DATE_TRUNC('month', r.fecha_incidente)::DATE AS mes,
    COUNT(*) AS total_reportes,
    COUNT(DISTINCT r.incidente_id) AS total_incidentes,
    MIN(r.fecha_incidente) AS primer_incidente,
    MAX(r.fecha_incidente) AS ultimo_incidente
FROM public.reportes r
LEFT JOIN public.zonas z ON r.zona_id = z.id
GROUP BY r.comuna, z.barrio, r.tipo_hurto, r.franja_horaria, r.estado, DATE_TRUNC('month', r.fecha_incidente)
ORDER BY total_reportes DESC;

CREATE OR REPLACE VIEW public.vw_tendencias_zona_tipo AS
SELECT
    r.comuna, z.barrio, r.tipo_hurto,
    DATE_TRUNC('week', r.fecha_incidente)::DATE AS semana_inicio,
    COUNT(*) AS total_reportes,
    COUNT(DISTINCT r.incidente_id) AS total_incidentes
FROM public.reportes r
LEFT JOIN public.zonas z ON r.zona_id = z.id
WHERE r.estado = 'activo'
GROUP BY r.comuna, z.barrio, r.tipo_hurto, DATE_TRUNC('week', r.fecha_incidente)
ORDER BY semana_inicio DESC, total_reportes DESC;

CREATE OR REPLACE VIEW public.vw_conteo_estado_reportes AS
SELECT estado, COUNT(*) AS total, COUNT(DISTINCT usuario_id) AS usuarios_distintos,
    MIN(fecha_creacion) AS primer_reporte, MAX(fecha_creacion) AS ultimo_reporte
FROM public.reportes GROUP BY estado;
