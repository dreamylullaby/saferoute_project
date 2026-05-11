-- =============================================================
-- Migración 007: Tabla incidentes y deduplicación automática
-- Actualizado: Mayo 2026 — soporte rural (corregimiento/vereda)
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
    corregimiento_id     INTEGER,
    vereda_id            INTEGER,
    cantidad_reportes    INTEGER     NOT NULL DEFAULT 1,
    tiene_coordenadas    BOOLEAN     NOT NULL DEFAULT true,
    fecha_creacion       TIMESTAMP   NOT NULL DEFAULT now(),
    CONSTRAINT fk_reporte_principal FOREIGN KEY (reporte_principal_id) REFERENCES public.reportes(id) ON DELETE RESTRICT,
    CONSTRAINT fk_incidente_zona FOREIGN KEY (zona_id) REFERENCES public.zonas(id),
    CONSTRAINT fk_incidente_corregimiento FOREIGN KEY (corregimiento_id) REFERENCES public.corregimientos(id),
    CONSTRAINT fk_incidente_vereda FOREIGN KEY (vereda_id) REFERENCES public.veredas(id),
    CONSTRAINT incidentes_tipo_hurto_check CHECK (tipo_hurto IN ('atraco', 'raponazo', 'cosquilleo', 'fleteo')),
    CONSTRAINT incidentes_franja_horaria_check CHECK (franja_horaria IN ('00:00-05:59', '06:00-11:59', '12:00-17:59', '18:00-23:59')),
    CONSTRAINT chk_incidente_comuna CHECK (comuna IS NULL OR (comuna >= 1 AND comuna <= 12))
);

CREATE INDEX idx_incidentes_tipo_hurto ON public.incidentes (tipo_hurto);
CREATE INDEX idx_incidentes_fecha      ON public.incidentes (fecha_incidente);
CREATE INDEX idx_incidentes_zona       ON public.incidentes (zona_id);
CREATE INDEX idx_incidentes_coords     ON public.incidentes (latitud_centro, longitud_centro);
CREATE INDEX idx_incidentes_comuna     ON public.incidentes (comuna);
CREATE INDEX idx_incidentes_corregimiento ON public.incidentes (corregimiento_id);
CREATE INDEX idx_incidentes_vereda     ON public.incidentes (vereda_id);
CREATE INDEX idx_incidentes_tiene_coords ON public.incidentes (tiene_coordenadas);

-- Columnas en reportes
ALTER TABLE public.reportes
    ADD COLUMN incidente_id UUID,
    ADD COLUMN coordenadas_exactas BOOLEAN NOT NULL DEFAULT true,
    ADD CONSTRAINT fk_reporte_incidente FOREIGN KEY (incidente_id) REFERENCES public.incidentes(id) ON DELETE SET NULL;
CREATE INDEX idx_reportes_incidente_id ON public.reportes (incidente_id);
CREATE INDEX idx_reportes_coordenadas_exactas ON public.reportes (coordenadas_exactas);

-- Función de deduplicación automática (3 caminos: GPS, rural sin GPS, huérfano)
CREATE OR REPLACE FUNCTION public.asignar_o_crear_incidente()
RETURNS TRIGGER LANGUAGE plpgsql AS $$
DECLARE
    incidente_existente UUID;
    centroide_lat       NUMERIC(9,6);
    centroide_lng       NUMERIC(9,6);
    RADIO_METROS        CONSTANT NUMERIC := 150;
BEGIN
    -- CAMINO A: Reporte CON coordenadas GPS (urbano o rural con GPS)
    IF NEW.latitud IS NOT NULL AND NEW.longitud IS NOT NULL THEN
        SELECT i.id INTO incidente_existente
        FROM public.incidentes i
        WHERE i.tipo_hurto        = NEW.tipo_hurto
          AND i.fecha_incidente   = NEW.fecha_incidente
          AND i.franja_horaria    = NEW.franja_horaria
          AND i.tiene_coordenadas = true
          AND (6371000 * acos(LEAST(1.0,
              cos(radians(i.latitud_centro::float8)) * cos(radians(NEW.latitud::float8))
              * cos(radians(NEW.longitud::float8) - radians(i.longitud_centro::float8))
              + sin(radians(i.latitud_centro::float8)) * sin(radians(NEW.latitud::float8))
          ))) <= RADIO_METROS
        ORDER BY i.fecha_creacion ASC LIMIT 1;

        IF incidente_existente IS NOT NULL THEN
            NEW.incidente_id := incidente_existente;
            UPDATE public.incidentes i
            SET cantidad_reportes = i.cantidad_reportes + 1,
                latitud_centro  = (i.latitud_centro * i.cantidad_reportes + NEW.latitud) / (i.cantidad_reportes + 1),
                longitud_centro = (i.longitud_centro * i.cantidad_reportes + NEW.longitud) / (i.cantidad_reportes + 1),
                reporte_principal_id = CASE WHEN NEW.tipo_reportante = 'victima' THEN NEW.id ELSE i.reporte_principal_id END
            WHERE i.id = incidente_existente;
        ELSE
            INSERT INTO public.incidentes (
                reporte_principal_id, tipo_hurto, fecha_incidente, franja_horaria,
                latitud_centro, longitud_centro, zona_id, comuna,
                corregimiento_id, vereda_id, cantidad_reportes, tiene_coordenadas
            ) VALUES (
                NEW.id, NEW.tipo_hurto, NEW.fecha_incidente, NEW.franja_horaria,
                NEW.latitud, NEW.longitud, NEW.zona_id, NEW.comuna,
                NEW.corregimiento_id, NEW.vereda_id, 1, true
            ) RETURNING id INTO NEW.incidente_id;
        END IF;

    -- CAMINO B: Rural SIN GPS pero con vereda conocida
    ELSIF NEW.zona_tipo = 'rural' AND NEW.vereda_id IS NOT NULL THEN
        SELECT i.id INTO incidente_existente
        FROM public.incidentes i
        WHERE i.tipo_hurto        = NEW.tipo_hurto
          AND i.fecha_incidente   = NEW.fecha_incidente
          AND i.franja_horaria    = NEW.franja_horaria
          AND i.vereda_id         = NEW.vereda_id
          AND i.tiene_coordenadas = false
        ORDER BY i.fecha_creacion ASC LIMIT 1;

        -- Centroide del polígono del corregimiento
        SELECT ST_Y(ST_Centroid(c.geom)), ST_X(ST_Centroid(c.geom))
        INTO centroide_lat, centroide_lng
        FROM public.veredas v
        JOIN public.corregimientos c ON c.id = v.corregimiento_id
        WHERE v.id = NEW.vereda_id AND c.geom IS NOT NULL;

        IF centroide_lat IS NOT NULL THEN
            NEW.latitud             := centroide_lat;
            NEW.longitud            := centroide_lng;
            NEW.coordenadas_exactas := false;
        END IF;

        IF incidente_existente IS NOT NULL THEN
            NEW.incidente_id := incidente_existente;
            UPDATE public.incidentes
            SET cantidad_reportes = cantidad_reportes + 1,
                reporte_principal_id = CASE WHEN NEW.tipo_reportante = 'victima' THEN NEW.id ELSE reporte_principal_id END
            WHERE id = incidente_existente;
        ELSE
            INSERT INTO public.incidentes (
                reporte_principal_id, tipo_hurto, fecha_incidente, franja_horaria,
                latitud_centro, longitud_centro, corregimiento_id, vereda_id,
                cantidad_reportes, tiene_coordenadas
            ) VALUES (
                NEW.id, NEW.tipo_hurto, NEW.fecha_incidente, NEW.franja_horaria,
                centroide_lat, centroide_lng, NEW.corregimiento_id, NEW.vereda_id,
                1, false
            ) RETURNING id INTO NEW.incidente_id;
        END IF;

    -- CAMINO C: Sin GPS y sin vereda — incidente huérfano
    ELSE
        INSERT INTO public.incidentes (
            reporte_principal_id, tipo_hurto, fecha_incidente, franja_horaria,
            latitud_centro, longitud_centro, cantidad_reportes, tiene_coordenadas
        ) VALUES (
            NEW.id, NEW.tipo_hurto, NEW.fecha_incidente, NEW.franja_horaria,
            NULL, NULL, 1, false
        ) RETURNING id INTO NEW.incidente_id;
    END IF;

    RETURN NEW;
END;
$$;

CREATE TRIGGER trigger_asignar_incidente
    BEFORE INSERT ON public.reportes
    FOR EACH ROW EXECUTE FUNCTION public.asignar_o_crear_incidente();
