-- =============================================================
-- SafeRoute — Script BD: Sprint 3 (HU-10, HU-11, HU-12)
-- Base: PostgreSQL 17 (Supabase)
-- Requiere: Sprint 1 y Sprint 2 ejecutados previamente
-- =============================================================

-- =============================================================
-- TABLA: incidentes (agrupación de reportes cercanos)
-- =============================================================
CREATE TABLE public.incidentes (
    id                      UUID        PRIMARY KEY DEFAULT gen_random_uuid(),
    reporte_principal_id    UUID        NOT NULL,
    tipo_hurto              VARCHAR(30) NOT NULL,
    fecha_incidente         DATE        NOT NULL,
    franja_horaria          VARCHAR(20) NOT NULL,
    latitud_centro          NUMERIC(9,6),
    longitud_centro         NUMERIC(9,6),
    zona_id                 INTEGER,
    comuna                  INTEGER,
    cantidad_reportes       INTEGER     NOT NULL DEFAULT 1,
    fecha_creacion          TIMESTAMP   NOT NULL DEFAULT now(),
    CONSTRAINT chk_incidente_comuna CHECK (comuna IS NULL OR (comuna >= 1 AND comuna <= 12)),
    CONSTRAINT incidentes_franja_horaria_check CHECK (franja_horaria IN ('00:00-05:59', '06:00-11:59', '12:00-17:59', '18:00-23:59')),
    CONSTRAINT incidentes_tipo_hurto_check CHECK (tipo_hurto IN ('atraco', 'raponazo', 'cosquilleo', 'fleteo'))
);

-- Columna incidente_id en reportes
ALTER TABLE public.reportes ADD COLUMN incidente_id UUID;

-- Foreign Keys de incidentes
ALTER TABLE public.incidentes
    ADD CONSTRAINT fk_reporte_principal FOREIGN KEY (reporte_principal_id) REFERENCES public.reportes(id) ON DELETE RESTRICT;
ALTER TABLE public.incidentes
    ADD CONSTRAINT fk_incidente_zona FOREIGN KEY (zona_id) REFERENCES public.zonas(id);
ALTER TABLE public.reportes
    ADD CONSTRAINT fk_reporte_incidente FOREIGN KEY (incidente_id) REFERENCES public.incidentes(id) ON DELETE SET NULL;

-- =============================================================
-- Función: calcular nivel de riesgo
-- =============================================================
CREATE OR REPLACE FUNCTION public.calcular_nivel_riesgo(cantidad INTEGER)
RETURNS VARCHAR
LANGUAGE sql IMMUTABLE AS $$
    SELECT CASE
        WHEN cantidad <= 3  THEN 'seguro'
        WHEN cantidad <= 7  THEN 'medio'
        WHEN cantidad <= 10 THEN 'alto'
        ELSE 'peligroso'
    END;
$$;

-- =============================================================
-- Función + Trigger: asignar o crear incidente automáticamente
-- =============================================================
CREATE OR REPLACE FUNCTION public.asignar_o_crear_incidente()
RETURNS TRIGGER LANGUAGE plpgsql AS $$
DECLARE
    incidente_existente UUID;
    nuevo_incidente_id  UUID;
    RADIO_METROS        CONSTANT NUMERIC := 150;
BEGIN
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
        UPDATE public.incidentes i
        SET cantidad_reportes = i.cantidad_reportes + 1,
            latitud_centro  = (i.latitud_centro * i.cantidad_reportes + NEW.latitud) / (i.cantidad_reportes + 1),
            longitud_centro = (i.longitud_centro * i.cantidad_reportes + NEW.longitud) / (i.cantidad_reportes + 1),
            reporte_principal_id = CASE
                WHEN NEW.tipo_reportante = 'victima' THEN NEW.id
                ELSE i.reporte_principal_id
            END
        WHERE i.id = incidente_existente;
        nuevo_incidente_id := incidente_existente;
    ELSE
        INSERT INTO public.incidentes (
            reporte_principal_id, tipo_hurto, fecha_incidente,
            franja_horaria, latitud_centro, longitud_centro,
            zona_id, comuna, cantidad_reportes
        ) VALUES (
            NEW.id, NEW.tipo_hurto, NEW.fecha_incidente,
            NEW.franja_horaria, NEW.latitud, NEW.longitud,
            NEW.zona_id, NEW.comuna, 1
        )
        RETURNING id INTO nuevo_incidente_id;
    END IF;

    UPDATE public.reportes SET incidente_id = nuevo_incidente_id WHERE id = NEW.id;
    RETURN NEW;
END;
$$;

CREATE TRIGGER trigger_asignar_incidente
    AFTER INSERT ON public.reportes
    FOR EACH ROW EXECUTE FUNCTION public.asignar_o_crear_incidente();

-- =============================================================
-- HU-11: Vista de estadísticas básicas para usuario
-- =============================================================
CREATE OR REPLACE VIEW public.vw_estadisticas_basicas AS
WITH reportes_activos AS (
    SELECT id, fecha_incidente, franja_horaria, tipo_hurto, comuna, zona_id, fecha_creacion
    FROM public.reportes WHERE estado = 'activo'
), total AS (
    SELECT count(*) AS total_reportes FROM reportes_activos
), por_dia AS (
    SELECT fecha_incidente, count(*) AS cantidad FROM reportes_activos GROUP BY fecha_incidente
), por_franja AS (
    SELECT franja_horaria, count(*) AS cantidad FROM reportes_activos GROUP BY franja_horaria
)
SELECT t.total_reportes, pd.fecha_incidente, pd.cantidad AS reportes_dia,
    pf.franja_horaria, pf.cantidad AS reportes_franja
FROM total t CROSS JOIN por_dia pd CROSS JOIN por_franja pf;

-- =============================================================
-- HU-12: Vista de top zonas con más hurtos (por comuna)
-- =============================================================
CREATE OR REPLACE VIEW public.vw_top_zonas_hurtos AS
WITH conteo_comuna AS (
    SELECT i.comuna, count(*) AS total_incidentes,
        sum(i.cantidad_reportes) AS total_reportes_vinculados,
        max(i.fecha_incidente) AS ultimo_incidente
    FROM public.incidentes i
    JOIN public.reportes r ON r.id = i.reporte_principal_id
    WHERE r.estado = 'activo' AND i.comuna IS NOT NULL
    GROUP BY i.comuna
), tipo_frecuente AS (
    SELECT DISTINCT ON (i.comuna) i.comuna, i.tipo_hurto,
        count(*) AS cantidad_tipo
    FROM public.incidentes i
    JOIN public.reportes r ON r.id = i.reporte_principal_id
    WHERE r.estado = 'activo' AND i.comuna IS NOT NULL
    GROUP BY i.comuna, i.tipo_hurto
    ORDER BY i.comuna, count(*) DESC
)
SELECT cc.comuna, cc.total_incidentes, cc.total_reportes_vinculados,
    cc.ultimo_incidente, tf.tipo_hurto AS tipo_hurto_frecuente,
    tf.cantidad_tipo AS cantidad_tipo_frecuente
FROM conteo_comuna cc
LEFT JOIN tipo_frecuente tf ON cc.comuna = tf.comuna
ORDER BY cc.total_incidentes DESC;

-- Vista de top barrios con más hurtos
CREATE OR REPLACE VIEW public.vw_top_barrios_hurtos AS
SELECT i.comuna, z.barrio, i.zona_id,
    count(*) AS total_incidentes,
    sum(i.cantidad_reportes) AS total_reportes_vinculados,
    max(i.fecha_incidente) AS ultimo_incidente
FROM public.incidentes i
JOIN public.zonas z ON i.zona_id = z.id
JOIN public.reportes r ON r.id = i.reporte_principal_id
WHERE r.estado = 'activo' AND i.zona_id IS NOT NULL
GROUP BY i.comuna, z.barrio, i.zona_id
ORDER BY count(*) DESC;

-- =============================================================
-- HU-10: Vista dashboard de incidentes (panel admin)
-- =============================================================
CREATE OR REPLACE VIEW public.vw_dashboard_incidentes AS
SELECT i.id, i.tipo_hurto, i.fecha_incidente,
    (EXTRACT(year FROM i.fecha_incidente))::integer AS anio,
    (EXTRACT(month FROM i.fecha_incidente))::integer AS mes,
    to_char(i.fecha_incidente::timestamp with time zone, 'TMMonth') AS nombre_mes,
    i.franja_horaria,
    (i.comuna)::text AS comuna,
    z.barrio,
    i.cantidad_reportes,
    i.latitud_centro, i.longitud_centro,
    public.calcular_nivel_riesgo(i.cantidad_reportes) AS nivel_riesgo,
    (SELECT count(*) FROM public.reportes r2
     WHERE r2.incidente_id = i.id AND r2.tipo_reportante = 'victima' AND r2.estado = 'activo') AS victimas,
    (SELECT count(*) FROM public.reportes r3
     WHERE r3.incidente_id = i.id AND r3.tipo_reportante = 'testigo' AND r3.estado = 'activo') AS testigos,
    i.fecha_creacion
FROM public.incidentes i
LEFT JOIN public.zonas z ON i.zona_id = z.id
JOIN public.reportes r ON r.id = i.reporte_principal_id
WHERE r.estado = 'activo';

-- =============================================================
-- ÍNDICES Sprint 3
-- =============================================================

-- Incidentes
CREATE INDEX idx_incidentes_fecha      ON public.incidentes (fecha_incidente);
CREATE INDEX idx_incidentes_tipo_hurto ON public.incidentes (tipo_hurto);
CREATE INDEX idx_incidentes_zona       ON public.incidentes (zona_id);
CREATE INDEX idx_incidentes_comuna     ON public.incidentes (comuna);
CREATE INDEX idx_incidentes_coords     ON public.incidentes (latitud_centro, longitud_centro);

-- Reportes (compuestos para filtros HU-10)
CREATE INDEX idx_reportes_incidente_id       ON public.reportes (incidente_id);
CREATE INDEX idx_reportes_estado_tipo_hurto  ON public.reportes (estado, tipo_hurto);
CREATE INDEX idx_reportes_estado_comuna_tipo ON public.reportes (estado, comuna, tipo_hurto);
CREATE INDEX idx_reportes_fecha_zona_tipo    ON public.reportes (fecha_incidente, zona_id, tipo_hurto);
