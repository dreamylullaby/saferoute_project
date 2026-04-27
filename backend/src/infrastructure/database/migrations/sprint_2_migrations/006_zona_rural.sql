-- =============================================================
-- Migración 006: Zona rural — corregimientos y veredas
-- =============================================================

CREATE TABLE public.corregimientos (
    id      SERIAL PRIMARY KEY,
    nombre  VARCHAR(80) NOT NULL,
    geom    GEOMETRY(MULTIPOLYGON, 4326),
    CONSTRAINT chk_corregimiento_not_empty CHECK (nombre <> ''),
    CONSTRAINT uniq_corregimiento UNIQUE (nombre)
);
CREATE INDEX idx_corregimientos_geom ON public.corregimientos USING GIST(geom);

CREATE TABLE public.veredas (
    id                SERIAL PRIMARY KEY,
    nombre            VARCHAR(80) NOT NULL,
    corregimiento_id  INTEGER NOT NULL REFERENCES public.corregimientos(id),
    es_cabecera       BOOLEAN NOT NULL DEFAULT false,
    CONSTRAINT chk_vereda_not_empty CHECK (nombre <> '')
);
CREATE INDEX idx_veredas_corregimiento ON public.veredas (corregimiento_id);

-- Columnas zona rural en reportes
ALTER TABLE public.reportes
    ADD COLUMN zona_tipo VARCHAR(10) NOT NULL DEFAULT 'urbana'
        CHECK (zona_tipo IN ('urbana', 'rural')),
    ADD COLUMN corregimiento_id INTEGER REFERENCES public.corregimientos(id),
    ADD COLUMN vereda_id INTEGER REFERENCES public.veredas(id);

CREATE INDEX idx_reportes_zona_tipo     ON public.reportes (zona_tipo);
CREATE INDEX idx_reportes_corregimiento ON public.reportes (corregimiento_id);
