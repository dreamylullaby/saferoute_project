-- =============================================================
-- SafeRoute — Script completo de base de datos
-- Base: PostgreSQL 17 (Supabase)
-- Extensiones requeridas: uuid-ossp, unaccent, fuzzystrmatch, postgis
-- Sprint 3: HU-10, HU-11, HU-12, HU-13 + zonas de riesgo
-- Sprint 4: Geolocalización de barrios (PostGIS + secciones DANE)
-- =============================================================

-- Extensiones
CREATE EXTENSION IF NOT EXISTS "uuid-ossp"    WITH SCHEMA extensions;
CREATE EXTENSION IF NOT EXISTS unaccent       WITH SCHEMA public;
CREATE EXTENSION IF NOT EXISTS fuzzystrmatch  WITH SCHEMA public;
CREATE EXTENSION IF NOT EXISTS postgis;


-- =============================================================
-- TABLA: zonas
-- Catálogo de barrios con su comuna correspondiente (Pasto)
-- =============================================================
CREATE TABLE public.zonas (
    id      SERIAL      PRIMARY KEY,
    barrio  VARCHAR(80) NOT NULL,
    comuna  INTEGER     NOT NULL,
    geom    GEOMETRY(MULTIPOLYGON, 4326),

    CONSTRAINT chk_barrio_not_empty  CHECK (barrio <> ''),
    CONSTRAINT zonas_comuna_check    CHECK (comuna >= 1 AND comuna <= 12),
    CONSTRAINT uniq_barrio_comuna    UNIQUE (barrio, comuna)
);

CREATE INDEX idx_zonas_geom ON public.zonas USING GIST(geom);


-- =============================================================
-- TABLA: secciones_dane
-- Polígonos del DANE por sección urbana (geolocalización)
-- Se pobla con: node --env-file=.env cargar_secciones.js
-- (ejecutar una sola vez desde la raíz del backend,
--  con pasto_secciones.geojson en la misma carpeta)
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
    fcm_token       TEXT,

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
    fecha_actualizacion TIMESTAMP,
    actualizado_por     UUID,

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
    ADD CONSTRAINT fk_actualizado_por
    FOREIGN KEY (actualizado_por) REFERENCES public.usuarios(id) ON DELETE SET NULL;

ALTER TABLE public.reportes
    ADD CONSTRAINT fk_zona
    FOREIGN KEY (zona_id) REFERENCES public.zonas(id);


-- =============================================================
-- TABLA: configuracion_alertas (HU-07)
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
-- TABLA: alertas (HU-07)
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
-- TABLA: password_resets (HU-13)
-- Tokens de recuperación de contraseña
-- =============================================================
CREATE TABLE public.password_resets (
    id              UUID        PRIMARY KEY DEFAULT gen_random_uuid(),
    usuario_id      UUID        NOT NULL REFERENCES public.usuarios(id) ON DELETE CASCADE,
    token           TEXT        NOT NULL,
    expiration      TIMESTAMP   NOT NULL,
    usado           BOOLEAN     NOT NULL DEFAULT false,
    fecha_creacion  TIMESTAMP   NOT NULL DEFAULT now()
);


-- =============================================================
-- TABLA: zonas_riesgo (Persistencia de heatmap)
-- Clusters de reportes calculados periódicamente
-- =============================================================
CREATE TABLE public.zonas_riesgo (
    id                  UUID        PRIMARY KEY DEFAULT gen_random_uuid(),
    latitud_centro      NUMERIC(9,6) NOT NULL,
    longitud_centro     NUMERIC(9,6) NOT NULL,
    radio               INTEGER     NOT NULL DEFAULT 200,
    nivel_riesgo        VARCHAR(20) NOT NULL CHECK (nivel_riesgo IN ('seguro', 'medio', 'alto', 'peligroso')),
    cantidad_reportes   INTEGER     NOT NULL DEFAULT 0,
    comuna              INTEGER,
    fecha_calculo       TIMESTAMP   NOT NULL DEFAULT now(),

    CONSTRAINT chk_radio_positivo CHECK (radio > 0),
    CONSTRAINT chk_comuna_valida CHECK (comuna IS NULL OR (comuna >= 1 AND comuna <= 12))
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

-- Obtiene comuna y barrios a partir de coordenadas (geolocalización)
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

-- Asigna zona y comuna usando coordenadas (primero) y nombre como fallback
CREATE OR REPLACE FUNCTION public.asignar_zona_y_comuna()
RETURNS TRIGGER LANGUAGE plpgsql AS $
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
$;

-- Calcula nivel de riesgo según cantidad de reportes (heatmap)
-- seguro: 0-3 | medio: 4-7 | alto: 8-10 | peligroso: >10
CREATE OR REPLACE FUNCTION public.calcular_nivel_riesgo(cantidad INTEGER)
RETURNS VARCHAR(20)
LANGUAGE sql IMMUTABLE AS $$
    SELECT CASE
        WHEN cantidad <= 3  THEN 'seguro'
        WHEN cantidad <= 7  THEN 'medio'
        WHEN cantidad <= 10 THEN 'alto'
        ELSE 'peligroso'
    END;
$$;


-- =============================================================
-- TRIGGERS sobre reportes
-- =============================================================
CREATE TRIGGER trigger_asignar_zona_comuna
    BEFORE INSERT OR UPDATE ON public.reportes
    FOR EACH ROW
    EXECUTE FUNCTION public.asignar_zona_y_comuna();


-- =============================================================
-- ÍNDICES — Filtros generales (HU-09)
-- =============================================================
CREATE INDEX idx_reportes_fecha_incidente  ON public.reportes (fecha_incidente);
CREATE INDEX idx_reportes_franja_horaria   ON public.reportes (franja_horaria);
CREATE INDEX idx_reportes_zona_id          ON public.reportes (zona_id);
CREATE INDEX idx_reportes_comuna           ON public.reportes (comuna);
CREATE INDEX idx_reportes_tipo_hurto       ON public.reportes (tipo_hurto);
CREATE INDEX idx_reportes_estado           ON public.reportes (estado);
CREATE INDEX idx_reportes_estado_fecha     ON public.reportes (estado, fecha_incidente);
CREATE INDEX idx_reportes_estado_zona      ON public.reportes (estado, zona_id);

-- =============================================================
-- ÍNDICES — Alertas
-- =============================================================
CREATE INDEX idx_alertas_usuario_leida     ON public.alertas (usuario_id, leida);
CREATE INDEX idx_alertas_reporte           ON public.alertas (reporte_id);

-- =============================================================
-- ÍNDICES — Mapa interactivo (HU-08)
-- =============================================================
CREATE INDEX idx_reportes_latitud_longitud ON public.reportes (latitud, longitud);
CREATE INDEX idx_reportes_estado_coords    ON public.reportes (estado, latitud, longitud);
CREATE INDEX idx_reportes_fecha_creacion   ON public.reportes (fecha_creacion DESC);

-- =============================================================
-- ÍNDICES — Panel de administración (HU-10)
-- =============================================================
CREATE INDEX idx_reportes_estado_fecha_comuna
    ON public.reportes (estado, fecha_incidente, comuna);

CREATE INDEX idx_reportes_estado_comuna_tipo
    ON public.reportes (estado, comuna, tipo_hurto);

CREATE INDEX idx_reportes_estado_fecha_zona
    ON public.reportes (estado, fecha_incidente, zona_id);

CREATE INDEX idx_reportes_usuario_id
    ON public.reportes (usuario_id);

CREATE INDEX idx_reportes_actualizado_por
    ON public.reportes (actualizado_por)
    WHERE actualizado_por IS NOT NULL;

-- =============================================================
-- ÍNDICES — password_resets (HU-13)
-- =============================================================
CREATE INDEX idx_password_resets_token     ON public.password_resets (token);
CREATE INDEX idx_password_resets_usuario   ON public.password_resets (usuario_id);

-- =============================================================
-- ÍNDICES — zonas_riesgo (Heatmap persistido)
-- =============================================================
CREATE INDEX idx_zonas_riesgo_coords       ON public.zonas_riesgo (latitud_centro, longitud_centro);
CREATE INDEX idx_zonas_riesgo_fecha        ON public.zonas_riesgo (fecha_calculo DESC);
CREATE INDEX idx_zonas_riesgo_nivel        ON public.zonas_riesgo (nivel_riesgo);
CREATE INDEX idx_zonas_riesgo_nivel_fecha  ON public.zonas_riesgo (nivel_riesgo, fecha_calculo DESC);
CREATE INDEX idx_zonas_riesgo_comuna       ON public.zonas_riesgo (comuna) WHERE comuna IS NOT NULL;


-- =============================================================
-- VISTA: vw_estadisticas_basicas (HU-11)
-- Estadísticas generales de reportes activos
-- =============================================================
CREATE OR REPLACE VIEW public.vw_estadisticas_basicas AS
WITH reportes_activos AS (
    SELECT
        id,
        fecha_incidente,
        franja_horaria,
        tipo_hurto,
        comuna,
        zona_id,
        fecha_creacion
    FROM public.reportes
    WHERE estado = 'activo'
),
total AS (
    SELECT COUNT(*) AS total_reportes FROM reportes_activos
),
por_dia AS (
    SELECT
        fecha_incidente,
        COUNT(*) AS cantidad
    FROM reportes_activos
    GROUP BY fecha_incidente
),
por_franja AS (
    SELECT
        franja_horaria,
        COUNT(*) AS cantidad
    FROM reportes_activos
    GROUP BY franja_horaria
)
SELECT
    t.total_reportes,
    pd.fecha_incidente,
    pd.cantidad AS reportes_dia,
    pf.franja_horaria,
    pf.cantidad AS reportes_franja
FROM total t
CROSS JOIN por_dia pd
CROSS JOIN por_franja pf;

-- =============================================================
-- VISTA: vw_estadisticas_por_periodo (HU-11)
-- Comparación entre periodos (agrupado por semana ISO)
-- =============================================================
CREATE OR REPLACE VIEW public.vw_estadisticas_por_periodo AS
SELECT
    DATE_TRUNC('week', fecha_incidente)::DATE AS semana_inicio,
    COUNT(*)                                  AS total_reportes,
    COUNT(DISTINCT fecha_incidente)           AS dias_con_reportes,
    ROUND(COUNT(*)::NUMERIC /
        NULLIF(COUNT(DISTINCT fecha_incidente), 0), 2) AS promedio_diario
FROM public.reportes
WHERE estado = 'activo'
GROUP BY DATE_TRUNC('week', fecha_incidente)
ORDER BY semana_inicio DESC;

-- =============================================================
-- VISTA: vw_top_zonas_hurtos (HU-12)
-- Ranking de comunas con más hurtos + tipo más frecuente
-- =============================================================
CREATE OR REPLACE VIEW public.vw_top_zonas_hurtos AS
WITH conteo_comuna AS (
    SELECT
        r.comuna,
        COUNT(*)            AS total_reportes,
        MAX(r.fecha_incidente) AS ultimo_reporte
    FROM public.reportes r
    WHERE r.estado = 'activo'
      AND r.comuna IS NOT NULL
    GROUP BY r.comuna
),
tipo_frecuente AS (
    SELECT DISTINCT ON (r.comuna)
        r.comuna,
        r.tipo_hurto,
        COUNT(*) AS cantidad_tipo
    FROM public.reportes r
    WHERE r.estado = 'activo'
      AND r.comuna IS NOT NULL
    GROUP BY r.comuna, r.tipo_hurto
    ORDER BY r.comuna, cantidad_tipo DESC
)
SELECT
    cc.comuna,
    cc.total_reportes,
    cc.ultimo_reporte,
    tf.tipo_hurto       AS tipo_hurto_frecuente,
    tf.cantidad_tipo    AS cantidad_tipo_frecuente
FROM conteo_comuna cc
LEFT JOIN tipo_frecuente tf ON cc.comuna = tf.comuna
ORDER BY cc.total_reportes DESC;

-- =============================================================
-- VISTA: vw_top_barrios_hurtos (HU-12)
-- Ranking de barrios con más hurtos (detalle por barrio)
-- =============================================================
CREATE OR REPLACE VIEW public.vw_top_barrios_hurtos AS
SELECT
    r.comuna,
    z.barrio,
    r.zona_id,
    COUNT(*)                    AS total_reportes,
    MAX(r.fecha_incidente)      AS ultimo_reporte
FROM public.reportes r
INNER JOIN public.zonas z ON r.zona_id = z.id
WHERE r.estado = 'activo'
  AND r.zona_id IS NOT NULL
GROUP BY r.comuna, z.barrio, r.zona_id
ORDER BY total_reportes DESC;
