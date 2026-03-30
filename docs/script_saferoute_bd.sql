-- ========================================
-- SCRIPT COMPLETO SAFEROUTE BD
-- Orden de ejecución: extensiones → usuarios → zonas → reportes
-- ========================================

-- ========================================
-- EXTENSIONES NECESARIAS
-- ========================================

-- Para UUID
CREATE EXTENSION IF NOT EXISTS "pgcrypto";

-- Para búsquedas sin acentos (backend fuzzy search)
CREATE EXTENSION IF NOT EXISTS unaccent;

-- Para distancia entre palabras (Levenshtein)
CREATE EXTENSION IF NOT EXISTS fuzzystrmatch;

-- ========================================
-- TABLA USUARIOS
-- ========================================
CREATE TABLE IF NOT EXISTS public.usuarios (
    id              uuid        PRIMARY KEY DEFAULT gen_random_uuid(),
    username        VARCHAR     NOT NULL UNIQUE,
    correo          VARCHAR     NOT NULL UNIQUE,
    password_hash   TEXT,
    foto_url        TEXT,
    rol             VARCHAR     NOT NULL CHECK (rol IN ('usuario', 'admin')),
    auth_provider   VARCHAR     NOT NULL CHECK (auth_provider IN ('local', 'google')),
    google_id       VARCHAR     UNIQUE,
    fecha_creacion  TIMESTAMP   NOT NULL DEFAULT now(),
    estado          VARCHAR     NOT NULL CHECK (estado IN ('activo', 'bloqueado'))
);

-- ========================================
-- TABLA ZONAS (barrios organizados por comuna)
-- ========================================
CREATE TABLE IF NOT EXISTS public.zonas (
    id      SERIAL      PRIMARY KEY,
    barrio  VARCHAR(80) NOT NULL,
    comuna  INTEGER     NOT NULL CHECK (comuna BETWEEN 1 AND 12),

    -- Evita duplicados del mismo barrio en la misma comuna
    CONSTRAINT unique_barrio_comuna UNIQUE (barrio, comuna),

    -- Evita strings vacíos
    CONSTRAINT chk_barrio_not_empty CHECK (barrio <> '')
);

-- ========================================
-- TABLA REPORTES
-- ========================================
CREATE TABLE IF NOT EXISTS public.reportes (
    id                  UUID        PRIMARY KEY DEFAULT gen_random_uuid(),
    usuario_id          UUID        NOT NULL REFERENCES public.usuarios(id),
    tipo_reportante     VARCHAR     NOT NULL CHECK (tipo_reportante IN ('victima', 'testigo')),
    fecha_incidente     DATE        NOT NULL,
    franja_horaria      VARCHAR     NOT NULL CHECK (franja_horaria IN (
                                        '00:00-05:59',
                                        '06:00-11:59',
                                        '12:00-17:59',
                                        '18:00-23:59'
                                    )),
    latitud             NUMERIC     NOT NULL,
    longitud            NUMERIC     NOT NULL,
    direccion           VARCHAR,
    tipo_hurto          VARCHAR     NOT NULL CHECK (tipo_hurto IN ('atraco', 'raponazo', 'cosquilleo', 'fleteo')),
    descripcion         VARCHAR,
    objeto_hurtado      VARCHAR     CHECK (objeto_hurtado IN (
                                        'celular',
                                        'dinero',
                                        'tarjetas_documentos',
                                        'articulos_personales',
                                        'dispositivos_electronicos'
                                    )),
    numero_agresores    VARCHAR     CHECK (numero_agresores IN ('1', '2', '3+', 'desconocido')),
    fecha_creacion      TIMESTAMP   NOT NULL DEFAULT now(),
    fecha_actualizacion TIMESTAMP,
    actualizado_por     UUID        REFERENCES public.usuarios(id),
    estado              VARCHAR     NOT NULL CHECK (estado IN ('activo', 'oculto', 'eliminado')),

    -- Texto original escrito por el usuario
    barrio_ingresado    VARCHAR     NOT NULL,

    -- Referencia al barrio validado por búsqueda difusa
    zona_id             INTEGER     REFERENCES public.zonas(id)
);

-- ========================================
-- ÍNDICES ÚTILES PARA BÚSQUEDA
-- ========================================
CREATE INDEX idx_zonas_barrio  ON zonas (barrio);
CREATE INDEX idx_zonas_comuna  ON zonas (comuna);
CREATE INDEX idx_reportes_zona ON reportes (zona_id);

-- ========================================
-- FUNCIÓN DE APOYO PARA BÚSQUEDA DIFUSA
-- Usada por el backend para validar el barrio ingresado por el usuario
-- Retorna los 5 barrios más similares usando distancia Levenshtein
-- ========================================
CREATE OR REPLACE FUNCTION buscar_barrio_similar(texto_usuario TEXT)
RETURNS TABLE (
    id          INTEGER,
    barrio      VARCHAR,
    comuna      INTEGER,
    similitud   INTEGER
)
LANGUAGE sql
AS $$
    SELECT
        z.id,
        z.barrio,
        z.comuna,
        levenshtein(unaccent(lower(z.barrio)), unaccent(lower(texto_usuario))) AS similitud
    FROM zonas z
    ORDER BY similitud ASC
    LIMIT 5;
$$;
