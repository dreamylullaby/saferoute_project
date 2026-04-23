-- =============================================================
-- Migración 006: Geolocalización de barrios (PostGIS)
-- Sprint 2 — HU-08: Mapa interactivo con geolocalización
-- =============================================================

-- Extensión PostGIS
CREATE EXTENSION IF NOT EXISTS postgis;

-- Columna geom en zonas
ALTER TABLE public.zonas ADD COLUMN geom GEOMETRY(MULTIPOLYGON, 4326);
CREATE INDEX idx_zonas_geom ON public.zonas USING GIST(geom);

-- Nueva tabla secciones_dane
CREATE TABLE public.secciones_dane (
    id          SERIAL PRIMARY KEY,
    secu_ccdgo  VARCHAR(10),
    setu_ccdgo  VARCHAR(10),
    comuna      INTEGER,
    geom        GEOMETRY(MULTIPOLYGON, 4326)
);

CREATE INDEX idx_secciones_geom ON public.secciones_dane USING GIST(geom);

-- Función de búsqueda por coordenadas
CREATE OR REPLACE FUNCTION public.get_zona_por_coordenadas(
    lat DOUBLE PRECISION,
    lng DOUBLE PRECISION
)
RETURNS TABLE(comuna INTEGER, barrios TEXT[])
LANGUAGE sql AS $$
    SELECT
        s.comuna,
        ARRAY_AGG(z.barrio ORDER BY z.barrio) AS barrios
    FROM public.secciones_dane s
    JOIN public.zonas z ON z.comuna = s.comuna
    WHERE ST_Contains(
        s.geom,
        ST_SetSRID(ST_MakePoint(lng, lat), 4326)
    )
    GROUP BY s.comuna
    LIMIT 1;
$$;

-- Trigger asignar_zona_y_comuna ACTUALIZADO
-- (usa coordenadas primero, nombre como fallback)
CREATE OR REPLACE FUNCTION public.asignar_zona_y_comuna()
RETURNS TRIGGER LANGUAGE plpgsql AS $$
DECLARE
    zona_encontrada  INTEGER;
    comuna_encontrada INTEGER;
BEGIN
    -- Intento 1: coordenadas + nombre de barrio
    IF NEW.latitud IS NOT NULL AND NEW.longitud IS NOT NULL THEN
        SELECT z.id, z.comuna INTO zona_encontrada, comuna_encontrada
        FROM public.secciones_dane s
        JOIN public.zonas z ON z.comuna = s.comuna
        WHERE ST_Contains(
            s.geom,
            ST_SetSRID(ST_MakePoint(NEW.longitud::float8, NEW.latitud::float8), 4326)
        )
        AND unaccent(lower(z.barrio)) = unaccent(lower(NEW.barrio_ingresado))
        LIMIT 1;
    END IF;

    -- Intento 2 (fallback): solo por nombre de barrio
    IF zona_encontrada IS NULL AND NEW.barrio_ingresado IS NOT NULL THEN
        SELECT z.id, z.comuna INTO zona_encontrada, comuna_encontrada
        FROM public.zonas z
        WHERE unaccent(lower(z.barrio)) = unaccent(lower(NEW.barrio_ingresado))
        LIMIT 1;
    END IF;

    NEW.zona_id := zona_encontrada;
    NEW.comuna  := comuna_encontrada;
    RETURN NEW;
END;
$$;

-- NOTA: La tabla secciones_dane se pobla con el script
-- cargar_secciones.js que está en la raíz del backend.
-- Ejecutar UNA SOLA VEZ con:
--   node --env-file=.env cargar_secciones.js
-- El archivo pasto_secciones.geojson debe estar en la raíz del backend.
