-- =============================================================
-- Migración 007: Tabla incidentes y deduplicación automática
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
    CONSTRAINT fk_reporte_principal FOREIGN KEY (reporte_principal_id) REFERENCES public.reportes(id) ON DELETE RESTRICT,
    CONSTRAINT fk_incidente_zona FOREIGN KEY (zona_id) REFERENCES public.zonas(id),
    CONSTRAINT incidentes_tipo_hurto_check CHECK (tipo_hurto IN ('atraco', 'raponazo', 'cosquilleo', 'fleteo')),
    CONSTRAINT incidentes_franja_horaria_check CHECK (franja_horaria IN ('00:00-05:59', '06:00-11:59', '12:00-17:59', '18:00-23:59')),
    CONSTRAINT chk_incidente_comuna CHECK (comuna IS NULL OR (comuna >= 1 AND comuna <= 12))
);

CREATE INDEX idx_incidentes_tipo_hurto ON public.incidentes (tipo_hurto);
CREATE INDEX idx_incidentes_fecha      ON public.incidentes (fecha_incidente);
CREATE INDEX idx_incidentes_zona       ON public.incidentes (zona_id);
CREATE INDEX idx_incidentes_coords     ON public.incidentes (latitud_centro, longitud_centro);
CREATE INDEX idx_incidentes_comuna     ON public.incidentes (comuna);

-- Columna incidente_id en reportes
ALTER TABLE public.reportes
    ADD COLUMN incidente_id UUID,
    ADD CONSTRAINT fk_reporte_incidente FOREIGN KEY (incidente_id) REFERENCES public.incidentes(id) ON DELETE SET NULL;
CREATE INDEX idx_reportes_incidente_id ON public.reportes (incidente_id);

-- Función de deduplicación automática
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
          AND (6371000 * acos(LEAST(1.0,
              cos(radians(i.latitud_centro::float8)) * cos(radians(NEW.latitud::float8))
              * cos(radians(NEW.longitud::float8) - radians(i.longitud_centro::float8))
              + sin(radians(i.latitud_centro::float8)) * sin(radians(NEW.latitud::float8))
          ))) <= RADIO_METROS
        ORDER BY i.fecha_creacion ASC LIMIT 1;
    END IF;

    IF incidente_existente IS NOT NULL THEN
        UPDATE public.incidentes i
        SET cantidad_reportes = i.cantidad_reportes + 1,
            latitud_centro  = (i.latitud_centro * i.cantidad_reportes + NEW.latitud) / (i.cantidad_reportes + 1),
            longitud_centro = (i.longitud_centro * i.cantidad_reportes + NEW.longitud) / (i.cantidad_reportes + 1),
            reporte_principal_id = CASE WHEN NEW.tipo_reportante = 'victima' THEN NEW.id ELSE i.reporte_principal_id END
        WHERE i.id = incidente_existente;
        nuevo_incidente_id := incidente_existente;
    ELSE
        INSERT INTO public.incidentes (
            reporte_principal_id, tipo_hurto, fecha_incidente, franja_horaria,
            latitud_centro, longitud_centro, zona_id, comuna, cantidad_reportes
        ) VALUES (
            NEW.id, NEW.tipo_hurto, NEW.fecha_incidente, NEW.franja_horaria,
            NEW.latitud, NEW.longitud, NEW.zona_id, NEW.comuna, 1
        ) RETURNING id INTO nuevo_incidente_id;
    END IF;

    UPDATE public.reportes SET incidente_id = nuevo_incidente_id WHERE id = NEW.id;
    RETURN NEW;
END;
$$;

CREATE TRIGGER trigger_asignar_incidente
    AFTER INSERT ON public.reportes
    FOR EACH ROW EXECUTE FUNCTION public.asignar_o_crear_incidente();
