-- =============================================================
-- SafeRoute — Script BD: Sprint 2 (HU-07, HU-08, HU-09, HU-13)
-- Base: PostgreSQL 17 (Supabase)
-- Requiere: Sprint 1 ejecutado previamente
-- =============================================================

-- Extensión PostGIS (HU-08)
CREATE EXTENSION IF NOT EXISTS postgis;

-- =============================================================
-- Columna geom en zonas (HU-08)
-- =============================================================
ALTER TABLE public.zonas ADD COLUMN geom GEOMETRY(MULTIPOLYGON, 4326);
CREATE INDEX idx_zonas_geom ON public.zonas USING GIST(geom);

-- =============================================================
-- TABLA: secciones_dane (HU-08)
-- =============================================================
CREATE TABLE public.secciones_dane (
    id          SERIAL PRIMARY KEY,
    secu_ccdgo  VARCHAR(10),
    setu_ccdgo  VARCHAR(10),
    comuna      INTEGER,
    geom        GEOMETRY(MULTIPOLYGON, 4326)
);
CREATE INDEX idx_secciones_geom ON public.secciones_dane USING GIST(geom);

-- =============================================================
-- TABLA: corregimientos (zonas rurales)
-- =============================================================
CREATE TABLE public.corregimientos (
    id      SERIAL      PRIMARY KEY,
    nombre  VARCHAR(80) NOT NULL,
    geom    GEOMETRY(MULTIPOLYGON, 4326),
    CONSTRAINT chk_corregimiento_not_empty CHECK (nombre <> ''),
    CONSTRAINT uniq_corregimiento UNIQUE (nombre)
);
CREATE INDEX idx_corregimientos_geom ON public.corregimientos USING GIST(geom);

-- =============================================================
-- TABLA: veredas (dentro de corregimientos)
-- =============================================================
CREATE TABLE public.veredas (
    id                  SERIAL      PRIMARY KEY,
    nombre              VARCHAR(80) NOT NULL,
    corregimiento_id    INTEGER     NOT NULL,
    es_cabecera         BOOLEAN     NOT NULL DEFAULT false,
    CONSTRAINT chk_vereda_not_empty CHECK (nombre <> ''),
    CONSTRAINT veredas_corregimiento_id_fkey
        FOREIGN KEY (corregimiento_id) REFERENCES public.corregimientos(id)
);
CREATE INDEX idx_veredas_corregimiento ON public.veredas (corregimiento_id);

-- =============================================================
-- Columnas nuevas en reportes
-- =============================================================
ALTER TABLE public.reportes ADD COLUMN fecha_actualizacion TIMESTAMP;
ALTER TABLE public.reportes ADD COLUMN actualizado_por UUID;
ALTER TABLE public.reportes ADD COLUMN zona_tipo VARCHAR(10) NOT NULL DEFAULT 'urbana';
ALTER TABLE public.reportes ADD COLUMN corregimiento_id INTEGER;
ALTER TABLE public.reportes ADD COLUMN vereda_id INTEGER;

ALTER TABLE public.reportes ADD CONSTRAINT fk_actualizado_por
    FOREIGN KEY (actualizado_por) REFERENCES public.usuarios(id) ON DELETE SET NULL;
ALTER TABLE public.reportes ADD CONSTRAINT reportes_corregimiento_id_fkey
    FOREIGN KEY (corregimiento_id) REFERENCES public.corregimientos(id);
ALTER TABLE public.reportes ADD CONSTRAINT reportes_vereda_id_fkey
    FOREIGN KEY (vereda_id) REFERENCES public.veredas(id);
ALTER TABLE public.reportes ADD CONSTRAINT reportes_zona_tipo_check
    CHECK (zona_tipo IN ('urbana', 'rural'));

-- Columna fcm_token en usuarios (HU-07)
ALTER TABLE public.usuarios ADD COLUMN fcm_token TEXT;

-- =============================================================
-- TABLA: configuracion_alertas (HU-07)
-- =============================================================
CREATE TABLE public.configuracion_alertas (
    id                  UUID        PRIMARY KEY DEFAULT gen_random_uuid(),
    usuario_id          UUID        NOT NULL UNIQUE,
    radio_metros        INTEGER     NOT NULL DEFAULT 500,
    activo              BOOLEAN     NOT NULL DEFAULT true,
    fecha_creacion      TIMESTAMP   NOT NULL DEFAULT now(),
    fecha_actualizacion TIMESTAMP,
    CONSTRAINT fk_config_usuario FOREIGN KEY (usuario_id) REFERENCES public.usuarios(id) ON DELETE CASCADE,
    CONSTRAINT chk_radio_minimo CHECK (radio_metros >= 100),
    CONSTRAINT chk_radio_maximo CHECK (radio_metros <= 5000)
);

-- =============================================================
-- TABLA: alertas (HU-07)
-- =============================================================
CREATE TABLE public.alertas (
    id                  UUID        PRIMARY KEY DEFAULT gen_random_uuid(),
    usuario_id          UUID        NOT NULL,
    reporte_id          UUID        NOT NULL,
    distancia_metros    NUMERIC(8,2),
    leida               BOOLEAN     NOT NULL DEFAULT false,
    fecha_creacion      TIMESTAMP   NOT NULL DEFAULT now(),
    fecha_leida         TIMESTAMP,
    CONSTRAINT fk_alerta_usuario FOREIGN KEY (usuario_id) REFERENCES public.usuarios(id) ON DELETE CASCADE,
    CONSTRAINT fk_alerta_reporte FOREIGN KEY (reporte_id) REFERENCES public.reportes(id) ON DELETE CASCADE
);

-- =============================================================
-- TABLA: password_resets (HU-13)
-- =============================================================
CREATE TABLE public.password_resets (
    id              UUID        PRIMARY KEY DEFAULT gen_random_uuid(),
    usuario_id      UUID        NOT NULL,
    token           TEXT        NOT NULL,
    expiration      TIMESTAMP   NOT NULL,
    usado           BOOLEAN     NOT NULL DEFAULT false,
    fecha_creacion  TIMESTAMP   NOT NULL DEFAULT now(),
    CONSTRAINT password_resets_usuario_id_fkey
        FOREIGN KEY (usuario_id) REFERENCES public.usuarios(id) ON DELETE CASCADE
);

-- =============================================================
-- Función: geolocalización por coordenadas (HU-08)
-- =============================================================
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
    FROM buscar_barrio_similar(NEW.barrio_ingresado)
    LIMIT 1;

    NEW.zona_id = zona_encontrada;
    RETURN NEW;
END;
$$;

CREATE TRIGGER trigger_asignar_zona
    BEFORE INSERT OR UPDATE ON public.reportes
    FOR EACH ROW
    WHEN (NEW.zona_id IS NULL)
    EXECUTE FUNCTION public.asignar_zona_automatica();

-- =============================================================
-- ÍNDICES Sprint 2
-- =============================================================

-- HU-09 Filtros
CREATE INDEX idx_reportes_franja_horaria   ON public.reportes (franja_horaria);
CREATE INDEX idx_reportes_estado_fecha     ON public.reportes (estado, fecha_incidente);
CREATE INDEX idx_reportes_estado_zona      ON public.reportes (estado, zona_id);

-- HU-08 Mapa interactivo
CREATE INDEX idx_reportes_latitud_longitud ON public.reportes (latitud, longitud);
CREATE INDEX idx_reportes_estado_coords    ON public.reportes (estado, latitud, longitud);
CREATE INDEX idx_reportes_fecha_creacion   ON public.reportes (fecha_creacion DESC);
CREATE INDEX idx_reportes_corregimiento    ON public.reportes (corregimiento_id);
CREATE INDEX idx_reportes_zona_tipo        ON public.reportes (zona_tipo);
CREATE INDEX idx_reportes_actualizado_por  ON public.reportes (actualizado_por) WHERE (actualizado_por IS NOT NULL);

-- HU-07 Alertas
CREATE INDEX idx_alertas_usuario_leida     ON public.alertas (usuario_id, leida);
CREATE INDEX idx_alertas_reporte           ON public.alertas (reporte_id);

-- HU-13 Password resets
CREATE INDEX idx_password_resets_token     ON public.password_resets (token);
CREATE INDEX idx_password_resets_usuario   ON public.password_resets (usuario_id);
