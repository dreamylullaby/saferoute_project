-- ========================================
-- 002_create_zonas.sql
-- Crea la tabla de zonas (barrios organizados por comuna)
-- y los índices para búsqueda eficiente
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

-- Índices para búsqueda eficiente
CREATE INDEX idx_zonas_barrio ON zonas (barrio);
CREATE INDEX idx_zonas_comuna ON zonas (comuna);

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
