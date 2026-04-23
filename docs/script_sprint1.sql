-- =============================================================
-- SafeRoute — Script de base de datos: Sprint 1
-- HU-01: Registrar incidente de hurto
-- HU-02: Iniciar sesión con correo
-- HU-03: Registrarse con correo y contraseña
-- HU-04: Registrarse/iniciar sesión con Google
-- HU-05: Cerrar sesión
-- HU-06: Especificar modalidad del hurto y descripción
-- Base: PostgreSQL 17 (Supabase)
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
ALTER TABLE public.reportes
    ADD CONSTRAINT fk_usuario
    FOREIGN KEY (usuario_id) REFERENCES public.usuarios(id) ON DELETE SET DEFAULT;

ALTER TABLE public.reportes
    ADD CONSTRAINT fk_zona
    FOREIGN KEY (zona_id) REFERENCES public.zonas(id);


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


-- =============================================================
-- ÍNDICES
-- =============================================================
CREATE INDEX idx_reportes_fecha_incidente  ON public.reportes (fecha_incidente);
CREATE INDEX idx_reportes_zona_id          ON public.reportes (zona_id);
CREATE INDEX idx_reportes_comuna           ON public.reportes (comuna);
CREATE INDEX idx_reportes_tipo_hurto       ON public.reportes (tipo_hurto);
CREATE INDEX idx_reportes_estado           ON public.reportes (estado);
