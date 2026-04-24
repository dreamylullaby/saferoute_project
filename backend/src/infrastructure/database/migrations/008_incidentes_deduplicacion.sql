-- =============================================================
-- Migración 008: Tabla incidentes y deduplicación automática
-- Sprint 3 — Agrupación de reportes del mismo hecho físico
-- =============================================================

-- =============================================================
-- TABLA: incidentes
-- Agrupa reportes del mismo hecho físico
-- =============================================================
CREATE TABLE public.incidentes (
    id                   UUID        PRIMARY KEY DEFAULT gen_random_uuid(),
    reporte_principal_id UUID        NOT NULL,
    tipo_hurto           VARCHAR(30) NOT NULL,
    fecha_incidente      DATE        NOT NULL,
    franja_horaria       VARCHAR(20) NOT NULL,
    latitud_centro       NUMERIC(9,6),
    longitud_centro      NUMERIC(9,6),
    zona_id              INTEGER,
    comuna               INTEGER,
    cantidad_reportes    INTEGER     NOT NULL DEFAULT 1,
    fecha_creacion       TIMESTAMP   NOT NULL DEFAULT now(),

    CONSTRAINT fk_reporte_principal
        FOREIGN KEY (reporte_principal_id) REFERENCES public.reportes(id) ON DELETE RESTRICT,
    CONSTRAINT fk_incidente_zona
        FOREIGN KEY (zona_id) REFERENCES public.zonas(id),
    CONSTRAINT incidentes_tipo_hurto_check
        CHECK (tipo_hurto IN ('atraco', 'raponazo', 'cosquilleo', 'fleteo')),
    CONSTRAINT incidentes_franja_horaria_check
        CHECK (franja_horaria IN ('00:00-05:59', '06:00-11:59', '12:00-17:59', '18:00-23:59')),
    CONSTRAINT chk_incidente_comuna
        CHECK (comuna IS NULL OR (comuna >= 1 AND comuna <= 12))
);

CREATE INDEX idx_incidentes_tipo_hurto ON public.incidentes (tipo_hurto);
CREATE INDEX idx_incidentes_fecha      ON public.incidentes (fecha_incidente);
CREATE INDEX idx_incidentes_zona       ON public.incidentes (zona_id);
CREATE INDEX idx_incidentes_coords     ON public.incidentes (latitud_centro, longitud_centro);
CREATE INDEX idx_incidentes_comuna     ON public.incidentes (comuna);

-- =============================================================
-- Columna incidente_id en reportes
-- =============================================================
ALTER TABLE public.reportes
    ADD COLUMN incidente_id UUID,
    ADD CONSTRAINT fk_reporte_incidente
        FOREIGN KEY (incidente_id) REFERENCES public.incidentes(id) ON DELETE SET NULL;

CREATE INDEX idx_reportes_incidente_id ON public.reportes (incidente_id);

-- =============================================================
-- Función de deduplicación automática
-- Criterios: mismo tipo_hurto + misma fecha + misma franja_horaria
--            + dentro de 150 metros
-- Solo deduplica si hay coordenadas (zona urbana)
-- =============================================================
CREATE OR REPLACE FUNCTION public.asignar_o_crear_incidente()
RETURNS TRIGGER LANGUAGE plpgsql AS $$
DECLARE
    incidente_existente UUID;
    nuevo_incidente_id  UUID;
    RADIO_METROS        CONSTANT NUMERIC := 150;
BEGIN
    -- Solo deduplicar si hay coordenadas (zona urbana)
    IF NEW.latitud IS NOT NULL AND NEW.longitud IS NOT NULL THEN
        SELECT i.id INTO incidente_existente
        FROM public.incidentes i
        WHERE i.tipo_hurto      = NEW.tipo_hurto
          AND i.fecha_incidente = NEW.fecha_incidente
          AND i.franja_horaria  = NEW.franja_horaria
          AND i.latitud_centro  IS NOT NULL
          AND (
              6371000 * acos(
                  LEAST(1.0,
                      cos(radians(i.latitud_centro::float8))
                      * cos(radians(NEW.latitud::float8))
                      * cos(radians(NEW.longitud::float8) - radians(i.longitud_centro::float8))
                      + sin(radians(i.latitud_centro::float8))
                      * sin(radians(NEW.latitud::float8))
                  )
              )
          ) <= RADIO_METROS
        ORDER BY i.fecha_creacion ASC
        LIMIT 1;
    END IF;

    IF incidente_existente IS NOT NULL THEN
        -- Vincular al incidente existente
        UPDATE public.incidentes i
        SET
            cantidad_reportes = i.cantidad_reportes + 1,
            latitud_centro  = (i.latitud_centro  * i.cantidad_reportes + NEW.latitud)
                              / (i.cantidad_reportes + 1),
            longitud_centro = (i.longitud_centro * i.cantidad_reportes + NEW.longitud)
                              / (i.cantidad_reportes + 1),
            reporte_principal_id = CASE
                WHEN NEW.tipo_reportante = 'victima' THEN NEW.id
                ELSE i.reporte_principal_id
            END
        WHERE i.id = incidente_existente;

        nuevo_incidente_id := incidente_existente;
    ELSE
        -- Crear nuevo incidente (el reporte ya existe porque es AFTER INSERT)
        INSERT INTO public.incidentes (
            reporte_principal_id,
            tipo_hurto,
            fecha_incidente,
            franja_horaria,
            latitud_centro,
            longitud_centro,
            zona_id,
            comuna,
            cantidad_reportes
        ) VALUES (
            NEW.id,
            NEW.tipo_hurto,
            NEW.fecha_incidente,
            NEW.franja_horaria,
            NEW.latitud,
            NEW.longitud,
            NEW.zona_id,
            NEW.comuna,
            1
        )
        RETURNING id INTO nuevo_incidente_id;
    END IF;

    -- Asignar incidente_id al reporte (AFTER INSERT, no podemos modificar NEW)
    UPDATE public.reportes
    SET incidente_id = nuevo_incidente_id
    WHERE id = NEW.id;

    RETURN NEW;
END;
$$;

-- =============================================================
-- Trigger de deduplicación
-- NOTA: El orden de triggers en PostgreSQL es alfabético.
-- trigger_asignar_incidente corre DESPUÉS de trigger_asignar_zona_comuna
-- =============================================================
CREATE TRIGGER trigger_asignar_incidente
    AFTER INSERT ON public.reportes
    FOR EACH ROW
    EXECUTE FUNCTION public.asignar_o_crear_incidente();

-- =============================================================
-- Vistas reemplazadas (ahora cuentan incidentes únicos)
-- =============================================================
DROP VIEW IF EXISTS public.vw_top_zonas_hurtos;
DROP VIEW IF EXISTS public.vw_top_barrios_hurtos;

-- Ranking de comunas con más incidentes + tipo más frecuente
CREATE OR REPLACE VIEW public.vw_top_zonas_hurtos AS
WITH conteo_comuna AS (
    SELECT
        i.comuna,
        COUNT(*)                 AS total_incidentes,
        SUM(i.cantidad_reportes) AS total_reportes_vinculados,
        MAX(i.fecha_incidente)   AS ultimo_incidente
    FROM public.incidentes i
    INNER JOIN public.reportes r ON r.id = i.reporte_principal_id
    WHERE r.estado = 'activo'
      AND i.comuna IS NOT NULL
    GROUP BY i.comuna
),
tipo_frecuente AS (
    SELECT DISTINCT ON (i.comuna)
        i.comuna,
        i.tipo_hurto,
        COUNT(*) AS cantidad_tipo
    FROM public.incidentes i
    INNER JOIN public.reportes r ON r.id = i.reporte_principal_id
    WHERE r.estado = 'activo'
      AND i.comuna IS NOT NULL
    GROUP BY i.comuna, i.tipo_hurto
    ORDER BY i.comuna, cantidad_tipo DESC
)
SELECT
    cc.comuna,
    cc.total_incidentes,
    cc.total_reportes_vinculados,
    cc.ultimo_incidente,
    tf.tipo_hurto    AS tipo_hurto_frecuente,
    tf.cantidad_tipo AS cantidad_tipo_frecuente
FROM conteo_comuna cc
LEFT JOIN tipo_frecuente tf ON cc.comuna = tf.comuna
ORDER BY cc.total_incidentes DESC;

-- Ranking de barrios con más incidentes (detalle por barrio)
CREATE OR REPLACE VIEW public.vw_top_barrios_hurtos AS
SELECT
    i.comuna,
    z.barrio,
    i.zona_id,
    COUNT(*)                 AS total_incidentes,
    SUM(i.cantidad_reportes) AS total_reportes_vinculados,
    MAX(i.fecha_incidente)   AS ultimo_incidente
FROM public.incidentes i
INNER JOIN public.zonas z ON i.zona_id = z.id
INNER JOIN public.reportes r ON r.id = i.reporte_principal_id
WHERE r.estado = 'activo'
  AND i.zona_id IS NOT NULL
GROUP BY i.comuna, z.barrio, i.zona_id
ORDER BY total_incidentes DESC;
