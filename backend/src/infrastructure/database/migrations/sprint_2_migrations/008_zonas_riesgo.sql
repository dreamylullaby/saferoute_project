-- =============================================================
-- Migración 008: Zonas de riesgo y función calcular_nivel_riesgo
-- =============================================================

CREATE TABLE IF NOT EXISTS public.zonas_riesgo (
    id                  UUID        PRIMARY KEY DEFAULT gen_random_uuid(),
    latitud_centro      NUMERIC(9,6) NOT NULL,
    longitud_centro     NUMERIC(9,6) NOT NULL,
    radio               INTEGER     NOT NULL DEFAULT 200,
    nivel_riesgo        VARCHAR(20) NOT NULL CHECK (nivel_riesgo IN ('seguro', 'medio', 'alto', 'peligroso')),
    cantidad_reportes   INTEGER     NOT NULL DEFAULT 0,
    fecha_calculo       TIMESTAMP   NOT NULL DEFAULT now(),
    comuna              INTEGER,
    CONSTRAINT chk_radio_positivo CHECK (radio > 0),
    CONSTRAINT chk_comuna_valida CHECK (comuna IS NULL OR (comuna >= 1 AND comuna <= 12))
);

CREATE INDEX idx_zonas_riesgo_coords     ON public.zonas_riesgo (latitud_centro, longitud_centro);
CREATE INDEX idx_zonas_riesgo_fecha      ON public.zonas_riesgo (fecha_calculo DESC);
CREATE INDEX idx_zonas_riesgo_nivel      ON public.zonas_riesgo (nivel_riesgo);
CREATE INDEX idx_zonas_riesgo_nivel_fecha ON public.zonas_riesgo (nivel_riesgo, fecha_calculo DESC);
CREATE INDEX idx_zonas_riesgo_comuna     ON public.zonas_riesgo (comuna) WHERE comuna IS NOT NULL;

CREATE OR REPLACE FUNCTION public.calcular_nivel_riesgo(cantidad INTEGER)
RETURNS VARCHAR(20) LANGUAGE sql IMMUTABLE AS $$
    SELECT CASE
        WHEN cantidad <= 3  THEN 'seguro'
        WHEN cantidad <= 7  THEN 'medio'
        WHEN cantidad <= 10 THEN 'alto'
        ELSE 'peligroso'
    END;
$$;
