-- ========================================
-- 002_create_zonas.sql
-- Crea la tabla de zonas (barrios organizados por comuna)
-- ========================================

CREATE TABLE IF NOT EXISTS public.zonas (
    id      SERIAL      PRIMARY KEY,
    barrio  VARCHAR(80) NOT NULL,
    comuna  INTEGER     NOT NULL CHECK (comuna BETWEEN 1 AND 12),
    CONSTRAINT unique_barrio_comuna UNIQUE (barrio, comuna),
    CONSTRAINT chk_barrio_not_empty CHECK (barrio <> '')
);

-- ========================================
-- FUNCIÓN: búsqueda difusa por nombre de barrio
-- ========================================
CREATE OR REPLACE FUNCTION public.buscar_barrio_similar(texto_usuario TEXT)
RETURNS TABLE (id INTEGER, barrio VARCHAR, comuna INTEGER, similitud INTEGER)
LANGUAGE sql AS $$
    SELECT z.id, z.barrio, z.comuna,
        levenshtein(unaccent(lower(z.barrio)), unaccent(lower(texto_usuario))) AS similitud
    FROM zonas z
    ORDER BY similitud ASC
    LIMIT 5;
$$;
