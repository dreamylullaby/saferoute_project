-- =============================================================
-- SafeRoute — Script de base de datos: Sprint 1 + Sprint 2
-- Sprint 1 (HU-01 a HU-06): Registro, login, reportes de hurto
-- Sprint 2 (HU-07 a HU-09): Alertas, mapa interactivo, filtros
-- Base: PostgreSQL 17 (Supabase)
-- Extensiones requeridas: uuid-ossp, unaccent, fuzzystrmatch, postgis
--
-- Las adiciones del Sprint 2 están marcadas con:
--   -- [Sprint 2]
-- =============================================================

-- Extensiones
CREATE EXTENSION IF NOT EXISTS "uuid-ossp"    WITH SCHEMA extensions;
CREATE EXTENSION IF NOT EXISTS unaccent       WITH SCHEMA public;
CREATE EXTENSION IF NOT EXISTS fuzzystrmatch  WITH SCHEMA public;
CREATE EXTENSION IF NOT EXISTS postgis;                                -- [Sprint 2] HU-08 geolocalización


-- =============================================================
-- TABLA: zonas
-- Catálogo de barrios con su comuna correspondiente (Pasto)
-- =============================================================
CREATE TABLE public.zonas (
    id      SERIAL      PRIMARY KEY,
    barrio  VARCHAR(80) NOT NULL,
    comuna  INTEGER     NOT NULL,
    geom    GEOMETRY(MULTIPOLYGON, 4326),                              -- [Sprint 2] HU-08 geometría para geolocalización

    CONSTRAINT chk_barrio_not_empty  CHECK (barrio <> ''),
    CONSTRAINT zonas_comuna_check    CHECK (comuna >= 1 AND comuna <= 12),
    CONSTRAINT uniq_barrio_comuna    UNIQUE (barrio, comuna)
);

CREATE INDEX idx_zonas_geom ON public.zonas USING GIST(geom);          -- [Sprint 2] HU-08


-- =============================================================
-- TABLA: secciones_dane                                    [Sprint 2] HU-08
-- Polígonos del DANE por sección urbana (geolocalización)
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
-- TABLA: usuarios
-- Usuarios registrados (local o Google)
-- =============================================================
CREATE TABLE public.usuarios (
    id              UUID        PRIMARY KEY DEFAULT gen_random_uuid(),
    username        VARCHAR(50) UNIQUE,
    correo          VARCHAR(150) NOT NULL UNIQUE,
    password_hash   TEXT,
    foto_url        TEXT,
    rol             VARCHAR(20) NOT NULL,
    auth_provider   VARCHAR(20) NOT NULL,
    google_id       VARCHAR(255) UNIQUE,
    fecha_creacion  TIMESTAMP   NOT NULL DEFAULT now(),
    estado          VARCHAR(20) NOT NULL,
    fcm_token       TEXT,                                              -- [Sprint 2] HU-07 token para push notifications

    CONSTRAINT usuarios_rol_check           CHECK (rol           IN ('usuario', 'admin')),
    CONSTRAINT usuarios_auth_provider_check CHECK (auth_provider IN ('local', 'google')),
    CONSTRAINT usuarios_estado_check        CHECK (estado        IN ('activo', 'bloqueado'))
);


-- =============================================================
-- TABLA: reportes
-- Reportes de incidentes de hurto registrados por usuarios
-- =============================================================
CREATE TABLE public.reportes (
    id                  UUID        PRIMARY KEY DEFAULT gen_random_uuid(),
    usuario_id          UUID        NOT NULL DEFAULT '00000000-0000-0000-0000-000000000001',
    tipo_reportante     VARCHAR(20) NOT NULL,
    fecha_incidente     DATE        NOT NULL,
    franja_horaria      VARCHAR(20) NOT NULL,
    latitud             NUMERIC(9,6) NOT NULL,
    longitud            NUMERIC(9,6) NOT NULL,
    direccion           VARCHAR(100),
    tipo_hurto          VARCHAR(30) NOT NULL,
    descripcion         VARCHAR(300),
    objeto_hurtado      VARCHAR(50),
    numero_agresores    VARCHAR(20),
    barrio_ingresado    VARCHAR(80) NOT NULL DEFAULT 'SIN DEFINIR',
    zona_id             INTEGER,
    comuna              INTEGER,
    estado              VARCHAR(20) NOT NULL,
    fecha_creacion      TIMESTAMP   NOT NULL DEFAULT now(),
    fecha_actualizacion TIMESTAMP,                                     -- [Sprint 2] auditoría de edición
    actualizado_por     UUID,                                          -- [Sprint 2] auditoría de edición

    CONSTRAINT reportes_tipo_reportante_check  CHECK (tipo_reportante  IN ('victima', 'testigo')),
    CONSTRAINT reportes_franja_horaria_check   CHECK (franja_horaria   IN ('00:00-05:59', '06:00-11:59', '12:00-17:59', '18:00-23:59')),
    CONSTRAINT reportes_tipo_hurto_check       CHECK (tipo_hurto       IN ('atraco', 'raponazo', 'cosquilleo', 'fleteo')),
    CONSTRAINT reportes_objeto_hurtado_check   CHECK (objeto_hurtado   IN ('celular', 'dinero', 'tarjetas_documentos', 'articulos_personales', 'dispositivos_electronicos')),
    CONSTRAINT reportes_numero_agresores_check CHECK (numero_agresores IN ('1', '2', '3+', 'desconocido')),
    CONSTRAINT reportes_estado_check           CHECK (estado           IN ('activo', 'oculto', 'eliminado'))
);


-- =============================================================
-- FOREIGN KEYS — reportes
-- =============================================================
ALTER TABLE public.reportes
    ADD CONSTRAINT fk_usuario
    FOREIGN KEY (usuario_id) REFERENCES public.usuarios(id) ON DELETE SET DEFAULT;

ALTER TABLE public.reportes
    ADD CONSTRAINT fk_actualizado_por                                  -- [Sprint 2] auditoría
    FOREIGN KEY (actualizado_por) REFERENCES public.usuarios(id) ON DELETE SET NULL;

ALTER TABLE public.reportes
    ADD CONSTRAINT fk_zona
    FOREIGN KEY (zona_id) REFERENCES public.zonas(id);


-- =============================================================
-- TABLA: configuracion_alertas                             [Sprint 2] HU-07
-- =============================================================
CREATE TABLE public.configuracion_alertas (
    id              UUID        PRIMARY KEY DEFAULT gen_random_uuid(),
    usuario_id      UUID        NOT NULL UNIQUE,
    radio_metros    INTEGER     NOT NULL DEFAULT 500,
    activo          BOOLEAN     NOT NULL DEFAULT true,
    fecha_creacion  TIMESTAMP   NOT NULL DEFAULT now(),
    fecha_actualizacion TIMESTAMP,

    CONSTRAINT fk_config_usuario
        FOREIGN KEY (usuario_id) REFERENCES public.usuarios(id) ON DELETE CASCADE,
    CONSTRAINT chk_radio_minimo CHECK (radio_metros >= 100),
    CONSTRAINT chk_radio_maximo CHECK (radio_metros <= 5000)
);


-- =============================================================
-- TABLA: alertas                                           [Sprint 2] HU-07
-- =============================================================
CREATE TABLE public.alertas (
    id              UUID        PRIMARY KEY DEFAULT gen_random_uuid(),
    usuario_id      UUID        NOT NULL,
    reporte_id      UUID        NOT NULL,
    distancia_metros NUMERIC(8,2),
    leida           BOOLEAN     NOT NULL DEFAULT false,
    fecha_creacion  TIMESTAMP   NOT NULL DEFAULT now(),
    fecha_leida     TIMESTAMP,

    CONSTRAINT fk_alerta_usuario
        FOREIGN KEY (usuario_id) REFERENCES public.usuarios(id) ON DELETE CASCADE,
    CONSTRAINT fk_alerta_reporte
        FOREIGN KEY (reporte_id) REFERENCES public.reportes(id) ON DELETE CASCADE
);


-- =============================================================
-- FUNCIONES
-- =============================================================

-- Búsqueda difusa de barrios por Levenshtein
CREATE OR REPLACE FUNCTION public.buscar_barrio_similar(texto_usuario TEXT)
RETURNS TABLE(id INTEGER, barrio VARCHAR, comuna INTEGER, similitud INTEGER)
LANGUAGE sql AS $
    SELECT
        z.id,
        z.barrio,
        z.comuna,
        levenshtein(
            unaccent(lower(z.barrio)),
            unaccent(lower(texto_usuario))
        ) AS similitud
    FROM zonas z
    ORDER BY similitud ASC
    LIMIT 5;
$;

-- Geolocalización: obtener comuna y barrios por coordenadas  [Sprint 2] HU-08
CREATE OR REPLACE FUNCTION public.get_zona_por_coordenadas(
    lat DOUBLE PRECISION,
    lng DOUBLE PRECISION
)
RETURNS TABLE(comuna INTEGER, barrios TEXT[])
LANGUAGE sql AS $
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
$;

-- Asignación automática de zona y comuna al insertar/actualizar reporte
CREATE OR REPLACE FUNCTION public.asignar_zona_y_comuna()
RETURNS TRIGGER LANGUAGE plpgsql AS $
DECLARE
    zona_encontrada  INTEGER;
    comuna_encontrada INTEGER;
BEGIN
    -- Intento 1: coordenadas + nombre de barrio                       [Sprint 2] HU-08
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
$;

CREATE TRIGGER trigger_asignar_zona_comuna
    BEFORE INSERT OR UPDATE ON public.reportes
    FOR EACH ROW
    EXECUTE FUNCTION public.asignar_zona_y_comuna();


-- =============================================================
-- ÍNDICES — Sprint 1
-- =============================================================
CREATE INDEX idx_reportes_fecha_incidente  ON public.reportes (fecha_incidente);
CREATE INDEX idx_reportes_zona_id          ON public.reportes (zona_id);
CREATE INDEX idx_reportes_comuna           ON public.reportes (comuna);
CREATE INDEX idx_reportes_tipo_hurto       ON public.reportes (tipo_hurto);
CREATE INDEX idx_reportes_estado           ON public.reportes (estado);

-- =============================================================
-- ÍNDICES — Sprint 2: HU-09 Filtros
-- =============================================================
CREATE INDEX idx_reportes_franja_horaria   ON public.reportes (franja_horaria);
CREATE INDEX idx_reportes_estado_fecha     ON public.reportes (estado, fecha_incidente);
CREATE INDEX idx_reportes_estado_zona      ON public.reportes (estado, zona_id);

-- =============================================================
-- ÍNDICES — Sprint 2: HU-08 Mapa interactivo
-- =============================================================
CREATE INDEX idx_reportes_latitud_longitud ON public.reportes (latitud, longitud);
CREATE INDEX idx_reportes_estado_coords    ON public.reportes (estado, latitud, longitud);
CREATE INDEX idx_reportes_fecha_creacion   ON public.reportes (fecha_creacion DESC);

-- =============================================================
-- ÍNDICES — Sprint 2: HU-07 Alertas
-- =============================================================
CREATE INDEX idx_alertas_usuario_leida     ON public.alertas (usuario_id, leida);
CREATE INDEX idx_alertas_reporte           ON public.alertas (reporte_id);
