-- =============================================================
-- Migración 005: PostGIS, secciones DANE y geolocalización (HU-08)
-- =============================================================

CREATE EXTENSION IF NOT EXISTS postgis;

-- Columna geom en zonas
ALTER TABLE public.zonas ADD COLUMN geom GEOMETRY(MULTIPOLYGON, 4326);
CREATE INDEX idx_zonas_geom ON public.zonas USING GIST(geom);

-- Tabla secciones_dane
CREATE TABLE public.secciones_dane (
    id          SERIAL PRIMARY KEY,
    secu_ccdgo  VARCHAR(10),
    setu_ccdgo  VARCHAR(10),
    comuna      INTEGER,
    geom        GEOMETRY(MULTIPOLYGON, 4326)
);
CREATE INDEX idx_secciones_geom ON public.secciones_dane USING GIST(geom);

-- Columnas de auditoría en reportes
ALTER TABLE public.reportes ADD COLUMN fecha_actualizacion TIMESTAMP;
ALTER TABLE public.reportes ADD COLUMN actualizado_por UUID;
ALTER TABLE public.reportes ADD CONSTRAINT fk_actualizado_por
    FOREIGN KEY (actualizado_por) REFERENCES public.usuarios(id) ON DELETE SET NULL;

-- Función de búsqueda por coordenadas
CREATE OR REPLACE FUNCTION public.get_zona_por_coordenadas(lat DOUBLE PRECISION, lng DOUBLE PRECISION)
RETURNS TABLE(comuna INTEGER, barrios TEXT[])
LANGUAGE sql AS $$
    SELECT s.comuna, ARRAY_AGG(z.barrio ORDER BY z.barrio) AS barrios
    FROM public.secciones_dane s
    JOIN public.zonas z ON z.comuna = s.comuna
    WHERE ST_Contains(s.geom, ST_SetSRID(ST_MakePoint(lng, lat), 4326))
    GROUP BY s.comuna LIMIT 1;
$$;

-- Trigger: asignación automática de zona y comuna
CREATE OR REPLACE FUNCTION public.asignar_zona_y_comuna()
RETURNS TRIGGER LANGUAGE plpgsql AS $$
DECLARE
    zona_encontrada INTEGER;
    comuna_encontrada INTEGER;
BEGIN
    IF NEW.latitud IS NOT NULL AND NEW.longitud IS NOT NULL THEN
        SELECT z.id, z.comuna INTO zona_encontrada, comuna_encontrada
        FROM public.secciones_dane s
        JOIN public.zonas z ON z.comuna = s.comuna
        WHERE ST_Contains(s.geom, ST_SetSRID(ST_MakePoint(NEW.longitud::float8, NEW.latitud::float8), 4326))
          AND unaccent(lower(z.barrio)) = unaccent(lower(NEW.barrio_ingresado))
        LIMIT 1;
    END IF;

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

CREATE TRIGGER trigger_asignar_zona_comuna
    BEFORE INSERT OR UPDATE ON public.reportes
    FOR EACH ROW EXECUTE FUNCTION public.asignar_zona_y_comuna();

-- Trigger fallback: asignación por similitud Levenshtein
CREATE OR REPLACE FUNCTION public.asignar_zona_automatica()
RETURNS TRIGGER LANGUAGE plpgsql AS $$
DECLARE
    zona_encontrada INTEGER;
BEGIN
    SELECT id INTO zona_encontrada
    FROM buscar_barrio_similar(NEW.barrio_ingresado) LIMIT 1;
    NEW.zona_id = zona_encontrada;
    RETURN NEW;
END;
$$;

CREATE TRIGGER trigger_asignar_zona
    BEFORE INSERT OR UPDATE ON public.reportes
    FOR EACH ROW WHEN (NEW.zona_id IS NULL)
    EXECUTE FUNCTION public.asignar_zona_automatica();

-- Índices mapa y filtros
CREATE INDEX idx_reportes_franja_horaria   ON public.reportes (franja_horaria);
CREATE INDEX idx_reportes_latitud_longitud ON public.reportes (latitud, longitud);
CREATE INDEX idx_reportes_estado_coords    ON public.reportes (estado, latitud, longitud);
CREATE INDEX idx_reportes_fecha_creacion   ON public.reportes (fecha_creacion DESC);
CREATE INDEX idx_reportes_estado_fecha     ON public.reportes (estado, fecha_incidente);
CREATE INDEX idx_reportes_estado_zona      ON public.reportes (estado, zona_id);
CREATE INDEX idx_reportes_actualizado_por  ON public.reportes (actualizado_por) WHERE (actualizado_por IS NOT NULL);
