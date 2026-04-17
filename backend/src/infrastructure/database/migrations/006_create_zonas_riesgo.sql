-- ========================================
-- 006_create_zonas_riesgo.sql
-- Persistencia de zonas de calor / riesgo
-- Almacena clusters de reportes calculados periódicamente
-- ========================================

CREATE TABLE IF NOT EXISTS public.zonas_riesgo (
    id                  UUID        PRIMARY KEY DEFAULT gen_random_uuid(),
    latitud_centro      NUMERIC(9,6) NOT NULL,
    longitud_centro     NUMERIC(9,6) NOT NULL,
    radio               INTEGER     NOT NULL DEFAULT 200,  -- en metros
    nivel_riesgo        VARCHAR(20) NOT NULL CHECK (nivel_riesgo IN ('seguro', 'medio', 'alto', 'peligroso')),
    cantidad_reportes   INTEGER     NOT NULL DEFAULT 0,
    comuna              INTEGER,    -- comuna derivada del centro del cluster (opcional)
    fecha_calculo       TIMESTAMP   NOT NULL DEFAULT now(),

    -- Restricción: el radio debe ser positivo
    CONSTRAINT chk_radio_positivo CHECK (radio > 0),
    CONSTRAINT chk_comuna_valida CHECK (comuna IS NULL OR (comuna >= 1 AND comuna <= 12))
);

-- Índice geográfico para consultas por ubicación (bounding box)
CREATE INDEX idx_zonas_riesgo_coords
    ON public.zonas_riesgo (latitud_centro, longitud_centro);

-- Índice por fecha de cálculo para comparar evolución en el tiempo
CREATE INDEX idx_zonas_riesgo_fecha
    ON public.zonas_riesgo (fecha_calculo DESC);

-- Índice por nivel de riesgo para filtrar zonas peligrosas rápidamente
CREATE INDEX idx_zonas_riesgo_nivel
    ON public.zonas_riesgo (nivel_riesgo);

-- Índice compuesto: nivel + fecha (consulta frecuente: "zonas peligrosas recientes")
CREATE INDEX idx_zonas_riesgo_nivel_fecha
    ON public.zonas_riesgo (nivel_riesgo, fecha_calculo DESC);

-- Índice por comuna para filtrar zonas de riesgo por comuna
CREATE INDEX idx_zonas_riesgo_comuna
    ON public.zonas_riesgo (comuna)
    WHERE comuna IS NOT NULL;

-- ========================================
-- FUNCIÓN: calcular_nivel_riesgo
-- Determina el nivel según la cantidad de reportes
-- Lógica del heatmap:
--   0-3  → seguro (verde)
--   4-7  → medio (amarillo)
--   8-10 → alto (rojo)
--   >10  → peligroso (magenta)
-- ========================================
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
