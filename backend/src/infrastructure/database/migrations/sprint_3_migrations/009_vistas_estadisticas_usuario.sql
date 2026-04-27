-- =============================================================
-- Migración 009: Vistas de estadísticas para usuario (HU-11)
-- =============================================================

CREATE OR REPLACE VIEW public.vw_estadisticas_basicas AS
WITH reportes_activos AS (
    SELECT id, fecha_incidente, franja_horaria, tipo_hurto, comuna, zona_id, fecha_creacion
    FROM public.reportes WHERE estado = 'activo'
), total AS (
    SELECT COUNT(*) AS total_reportes FROM reportes_activos
), por_dia AS (
    SELECT fecha_incidente, COUNT(*) AS cantidad FROM reportes_activos GROUP BY fecha_incidente
), por_franja AS (
    SELECT franja_horaria, COUNT(*) AS cantidad FROM reportes_activos GROUP BY franja_horaria
)
SELECT t.total_reportes, pd.fecha_incidente, pd.cantidad AS reportes_dia,
    pf.franja_horaria, pf.cantidad AS reportes_franja
FROM total t CROSS JOIN por_dia pd CROSS JOIN por_franja pf;

CREATE OR REPLACE VIEW public.vw_estadisticas_por_periodo AS
SELECT
    DATE_TRUNC('week', fecha_incidente)::DATE AS semana_inicio,
    COUNT(*) AS total_reportes,
    COUNT(DISTINCT fecha_incidente) AS dias_con_reportes,
    ROUND(COUNT(*)::NUMERIC / NULLIF(COUNT(DISTINCT fecha_incidente), 0)::NUMERIC, 2) AS promedio_diario
FROM public.reportes
WHERE estado = 'activo'
GROUP BY DATE_TRUNC('week', fecha_incidente)
ORDER BY semana_inicio DESC;
