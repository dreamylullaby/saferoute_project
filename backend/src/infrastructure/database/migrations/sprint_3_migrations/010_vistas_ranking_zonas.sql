-- =============================================================
-- Migración 010: Vistas de ranking de zonas (HU-12)
-- =============================================================

CREATE OR REPLACE VIEW public.vw_top_zonas_hurtos AS
WITH conteo_comuna AS (
    SELECT i.comuna, COUNT(*) AS total_incidentes,
        SUM(i.cantidad_reportes) AS total_reportes_vinculados,
        MAX(i.fecha_incidente) AS ultimo_incidente
    FROM public.incidentes i
    JOIN public.reportes r ON r.id = i.reporte_principal_id
    WHERE r.estado = 'activo' AND i.comuna IS NOT NULL
    GROUP BY i.comuna
), tipo_frecuente AS (
    SELECT DISTINCT ON (i.comuna) i.comuna, i.tipo_hurto, COUNT(*) AS cantidad_tipo
    FROM public.incidentes i
    JOIN public.reportes r ON r.id = i.reporte_principal_id
    WHERE r.estado = 'activo' AND i.comuna IS NOT NULL
    GROUP BY i.comuna, i.tipo_hurto
    ORDER BY i.comuna, COUNT(*) DESC
)
SELECT cc.comuna, cc.total_incidentes, cc.total_reportes_vinculados,
    cc.ultimo_incidente, tf.tipo_hurto AS tipo_hurto_frecuente,
    tf.cantidad_tipo AS cantidad_tipo_frecuente
FROM conteo_comuna cc
LEFT JOIN tipo_frecuente tf ON cc.comuna = tf.comuna
ORDER BY cc.total_incidentes DESC;

CREATE OR REPLACE VIEW public.vw_top_barrios_hurtos AS
SELECT i.comuna, z.barrio, i.zona_id,
    COUNT(*) AS total_incidentes,
    SUM(i.cantidad_reportes) AS total_reportes_vinculados,
    MAX(i.fecha_incidente) AS ultimo_incidente
FROM public.incidentes i
JOIN public.zonas z ON i.zona_id = z.id
JOIN public.reportes r ON r.id = i.reporte_principal_id
WHERE r.estado = 'activo' AND i.zona_id IS NOT NULL
GROUP BY i.comuna, z.barrio, i.zona_id
ORDER BY COUNT(*) DESC;
