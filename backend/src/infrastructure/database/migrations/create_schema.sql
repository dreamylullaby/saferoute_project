-- =============================================================
-- SafeRoute — Script de creación de base de datos
-- Base: PostgreSQL 17 (Supabase)
-- Extensiones requeridas: uuid-ossp, unaccent, fuzzystrmatch
-- =============================================================

-- Extensiones
CREATE EXTENSION IF NOT EXISTS "uuid-ossp"    WITH SCHEMA extensions;
CREATE EXTENSION IF NOT EXISTS unaccent       WITH SCHEMA public;
CREATE EXTENSION IF NOT EXISTS fuzzystrmatch  WITH SCHEMA public;


-- =============================================================
-- TABLA: zonas
-- Catálogo de barrios con su comuna correspondiente (Pasto)
-- =============================================================
CREATE TABLE public.zonas (
    id      SERIAL      PRIMARY KEY,
    barrio  VARCHAR(80) NOT NULL,
    comuna  INTEGER     NOT NULL,

    CONSTRAINT chk_barrio_not_empty  CHECK (barrio <> ''),
    CONSTRAINT zonas_comuna_check    CHECK (comuna >= 1 AND comuna <= 12),
    CONSTRAINT uniq_barrio_comuna    UNIQUE (barrio, comuna)
);


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

    CONSTRAINT usuarios_rol_check           CHECK (rol           IN ('usuario', 'admin')),
    CONSTRAINT usuarios_auth_provider_check CHECK (auth_provider IN ('local', 'google')),
    CONSTRAINT usuarios_estado_check        CHECK (estado        IN ('activo', 'bloqueado')),
    fcm_token       TEXT
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
-- FOREIGN KEYS
-- =============================================================

-- Reporte → usuario que lo creó (si se elimina el usuario, queda el usuario anónimo)
ALTER TABLE public.reportes
    ADD CONSTRAINT fk_usuario
    FOREIGN KEY (usuario_id) REFERENCES public.usuarios(id) ON DELETE SET DEFAULT;

-- Reporte → usuario admin que lo modificó
ALTER TABLE public.reportes
    ADD CONSTRAINT fk_actualizado_por
    FOREIGN KEY (actualizado_por) REFERENCES public.usuarios(id) ON DELETE SET NULL;

-- Reporte → zona geográfica
ALTER TABLE public.reportes
    ADD CONSTRAINT fk_zona
    FOREIGN KEY (zona_id) REFERENCES public.zonas(id);


-- =============================================================
-- FUNCIÓN: buscar_barrio_similar
-- Busca los 5 barrios más parecidos al texto ingresado
-- usando distancia Levenshtein (sin tildes, minúsculas)
-- =============================================================
CREATE OR REPLACE FUNCTION public.buscar_barrio_similar(texto_usuario TEXT)
RETURNS TABLE(id INTEGER, barrio VARCHAR, comuna INTEGER, similitud INTEGER)
LANGUAGE sql AS $$
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
$$;


-- =============================================================
-- FUNCIÓN: asignar_zona_automatica (trigger)
-- Asigna zona_id buscando el barrio más similar al ingresado
-- =============================================================
CREATE OR REPLACE FUNCTION public.asignar_zona_automatica()
RETURNS TRIGGER LANGUAGE plpgsql AS $$
DECLARE
    zona_encontrada INTEGER;
BEGIN
    SELECT id INTO zona_encontrada
    FROM public.buscar_barrio_similar(NEW.barrio_ingresado)
    LIMIT 1;

    NEW.zona_id = zona_encontrada;
    RETURN NEW;
END;
$$;


-- =============================================================
-- FUNCIÓN: asignar_zona_y_comuna (trigger)
-- Asigna zona_id por coincidencia exacta de barrio,
-- luego deriva la comuna según el rango de zona_id
-- =============================================================
CREATE OR REPLACE FUNCTION public.asignar_zona_y_comuna()
RETURNS TRIGGER LANGUAGE plpgsql AS $$
BEGIN
    -- Buscar zona por nombre exacto (normalizado)
    IF NEW.barrio_ingresado IS NOT NULL THEN
        SELECT z.id INTO NEW.zona_id
        FROM zonas z
        WHERE unaccent(lower(z.barrio)) = unaccent(lower(NEW.barrio_ingresado))
        LIMIT 1;
    END IF;

    -- Derivar comuna según rango de zona_id
    IF NEW.zona_id IS NOT NULL THEN
        NEW.comuna := CASE
            WHEN NEW.zona_id BETWEEN 1   AND 21  THEN 1
            WHEN NEW.zona_id BETWEEN 22  AND 53  THEN 2
            WHEN NEW.zona_id BETWEEN 54  AND 81  THEN 3
            WHEN NEW.zona_id BETWEEN 82  AND 114 THEN 4
            WHEN NEW.zona_id BETWEEN 115 AND 148 THEN 5
            WHEN NEW.zona_id BETWEEN 149 AND 191 THEN 6
            WHEN NEW.zona_id BETWEEN 192 AND 216 THEN 7
            WHEN NEW.zona_id BETWEEN 217 AND 263 THEN 8
            WHEN NEW.zona_id BETWEEN 264 AND 317 THEN 9
            WHEN NEW.zona_id BETWEEN 318 AND 356 THEN 10
            WHEN NEW.zona_id BETWEEN 357 AND 380 THEN 11
            WHEN NEW.zona_id BETWEEN 381 AND 408 THEN 12
            ELSE NULL
        END;
    END IF;

    RETURN NEW;
END;
$$;


-- =============================================================
-- TRIGGERS sobre reportes
-- =============================================================

-- Trigger 1: asigna zona por similitud (solo si zona_id es NULL)
CREATE TRIGGER trigger_asignar_zona
    BEFORE INSERT OR UPDATE ON public.reportes
    FOR EACH ROW
    WHEN (NEW.zona_id IS NULL)
    EXECUTE FUNCTION public.asignar_zona_automatica();

-- Trigger 2: asigna zona y comuna por coincidencia exacta
CREATE TRIGGER trigger_asignar_zona_comuna
    BEFORE INSERT OR UPDATE ON public.reportes
    FOR EACH ROW
    EXECUTE FUNCTION public.asignar_zona_y_comuna();


-- =============================================================
-- TABLA: configuracion_alertas
-- Preferencias de alerta por usuario:
-- radio en metros dentro del cual quiere recibir notificaciones
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
    CONSTRAINT chk_radio_minimo
        CHECK (radio_metros >= 100),
    CONSTRAINT chk_radio_maximo
        CHECK (radio_metros <= 5000)
);


-- =============================================================
-- TABLA: alertas
-- Registro de alertas enviadas a usuarios cuando se reporta
-- un hurto dentro de su radio configurado
-- =============================================================
CREATE TABLE public.alertas (
    id              UUID        PRIMARY KEY DEFAULT gen_random_uuid(),
    usuario_id      UUID        NOT NULL,
    reporte_id      UUID        NOT NULL,
    distancia_metros NUMERIC(8,2),           -- distancia real al momento de la alerta
    leida           BOOLEAN     NOT NULL DEFAULT false,
    fecha_creacion  TIMESTAMP   NOT NULL DEFAULT now(),
    fecha_leida     TIMESTAMP,

    CONSTRAINT fk_alerta_usuario
        FOREIGN KEY (usuario_id) REFERENCES public.usuarios(id) ON DELETE CASCADE,
    CONSTRAINT fk_alerta_reporte
        FOREIGN KEY (reporte_id) REFERENCES public.reportes(id) ON DELETE CASCADE
);


-- =============================================================
-- ÍNDICES — HU-09: filtros por fecha, franja, zona, tipo_hurto
-- Optimizan las consultas del mapa de calor y estadísticas
-- =============================================================

-- Filtro por fecha de incidente (rango de fechas)
CREATE INDEX idx_reportes_fecha_incidente  ON public.reportes (fecha_incidente);

-- Filtro por franja horaria
CREATE INDEX idx_reportes_franja_horaria   ON public.reportes (franja_horaria);

-- Filtro por zona geográfica
CREATE INDEX idx_reportes_zona_id          ON public.reportes (zona_id);

-- Filtro por comuna
CREATE INDEX idx_reportes_comuna           ON public.reportes (comuna);

-- Filtro por tipo de hurto
CREATE INDEX idx_reportes_tipo_hurto       ON public.reportes (tipo_hurto);

-- Filtro por estado (activo/oculto/eliminado) — usado en casi todas las queries
CREATE INDEX idx_reportes_estado           ON public.reportes (estado);

-- Índice compuesto: consultas frecuentes de mapa/estadísticas
CREATE INDEX idx_reportes_estado_fecha     ON public.reportes (estado, fecha_incidente);
CREATE INDEX idx_reportes_estado_zona      ON public.reportes (estado, zona_id);

-- Índices para alertas
CREATE INDEX idx_alertas_usuario_leida     ON public.alertas (usuario_id, leida);
CREATE INDEX idx_alertas_reporte           ON public.alertas (reporte_id);

-- Índices para consultas de mapa (HU-08)
CREATE INDEX idx_reportes_latitud_longitud ON public.reportes (latitud, longitud);
CREATE INDEX idx_reportes_estado_coords    ON public.reportes (estado, latitud, longitud);
CREATE INDEX idx_reportes_fecha_creacion   ON public.reportes (fecha_creacion DESC);
