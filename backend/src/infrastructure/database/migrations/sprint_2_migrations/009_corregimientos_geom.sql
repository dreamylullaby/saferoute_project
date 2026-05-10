-- Migración 009: Función de geolocalización para corregimientos (zona rural)
-- Los polígonos de corregimientos se cargan con:
--   node --env-file=.env secciones-pasto/cargar_corregimientos.js
-- (ejecutar una sola vez, pasto_rural_sector.geojson debe estar en secciones-pasto/)

CREATE OR REPLACE FUNCTION public.get_corregimiento_por_coordenadas(
    lat DOUBLE PRECISION,
    lng DOUBLE PRECISION
)
RETURNS TABLE(corregimiento_id INTEGER, corregimiento TEXT, veredas TEXT[])
LANGUAGE sql AS $$
    SELECT c.id, c.nombre,
        ARRAY_AGG(v.nombre ORDER BY v.nombre) AS veredas
    FROM public.corregimientos c
    JOIN public.veredas v ON v.corregimiento_id = c.id
    WHERE ST_Contains(c.geom, ST_SetSRID(ST_MakePoint(lng, lat), 4326))
    GROUP BY c.id, c.nombre
    LIMIT 1;
$$;
