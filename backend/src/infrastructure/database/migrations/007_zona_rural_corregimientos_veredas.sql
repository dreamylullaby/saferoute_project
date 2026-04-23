-- =============================================================
-- Migración 007: Zona rural — corregimientos y veredas
-- Sprint 3 — Soporte para reportes en zona rural de Pasto
-- =============================================================

-- =============================================================
-- TABLA: corregimientos
-- 17 corregimientos de Pasto (zona rural)
-- =============================================================
CREATE TABLE public.corregimientos (
    id      SERIAL PRIMARY KEY,
    nombre  VARCHAR(80) NOT NULL,
    geom    GEOMETRY(MULTIPOLYGON, 4326),

    CONSTRAINT chk_corregimiento_not_empty CHECK (nombre <> ''),
    CONSTRAINT uniq_corregimiento UNIQUE (nombre)
);

CREATE INDEX idx_corregimientos_geom ON public.corregimientos USING GIST(geom);

-- =============================================================
-- TABLA: veredas
-- Veredas por corregimiento
-- =============================================================
CREATE TABLE public.veredas (
    id                SERIAL PRIMARY KEY,
    nombre            VARCHAR(80) NOT NULL,
    corregimiento_id  INTEGER NOT NULL REFERENCES public.corregimientos(id),
    es_cabecera       BOOLEAN NOT NULL DEFAULT false,

    CONSTRAINT chk_vereda_not_empty CHECK (nombre <> '')
);

CREATE INDEX idx_veredas_corregimiento ON public.veredas (corregimiento_id);

-- =============================================================
-- INSERTAR corregimientos
-- =============================================================
INSERT INTO public.corregimientos (nombre) VALUES
('Buesaquillo'),
('Cabrera'),
('Catambuco'),
('El Encano'),
('El Socorro'),
('Genoy'),
('Gualmatán'),
('Jamondino'),
('Jongovito'),
('La Caldera'),
('La Laguna'),
('Mapachico'),
('Mocondino'),
('Morasurco'),
('Obonuco'),
('San Fernando'),
('Santa Bárbara');

-- =============================================================
-- INSERTAR veredas
-- =============================================================

-- BUESAQUILLO
INSERT INTO public.veredas (nombre, corregimiento_id)
SELECT v.nombre, c.id FROM public.corregimientos c,
(VALUES
    ('Buesaquillo Alto'),('Cuajacal Alto'),('Cuajacal Centro'),
    ('Cuajacal San Isidro'),('El Carmelo'),('La Alianza'),
    ('La Huecada'),('Pejendino Reyes'),('San Francisco'),
    ('San José'),('Tamboloma'),('Villa Julia')
) AS v(nombre)
WHERE c.nombre = 'Buesaquillo';

-- CABRERA
INSERT INTO public.veredas (nombre, corregimiento_id)
SELECT v.nombre, c.id FROM public.corregimientos c,
(VALUES
    ('Buenavista'),('Duarte'),('El Purgatorio'),('La Paz')
) AS v(nombre)
WHERE c.nombre = 'Cabrera';

-- CATAMBUCO
INSERT INTO public.veredas (nombre, corregimiento_id)
SELECT v.nombre, c.id FROM public.corregimientos c,
(VALUES
    ('Alto Casanare'),('Bellavista'),('Botana'),('Botanilla'),
    ('Chavez'),('Cruz de Amarillo'),('Cubijan Alto'),('Cubijan Bajo'),
    ('El Campanero'),('Fray Ezequiel'),('Guadalupe'),('La Merced'),
    ('La Victoria'),('San Antonio de Acuyuyo'),('San Antonio de Casanare'),
    ('San Isidro'),('San José de Casanare'),('San José de Catambuco'),
    ('Santamaría')
) AS v(nombre)
WHERE c.nombre = 'Catambuco';

-- EL ENCANO
INSERT INTO public.veredas (nombre, corregimiento_id)
SELECT v.nombre, c.id FROM public.corregimientos c,
(VALUES
    ('Bellavista'),('Campo Alegre'),('Carrizo'),('Casapamba'),
    ('El Estero'),('El Puerto'),('El Socorro'),('Mojondinoy'),
    ('Motilón'),('Naranjal'),('Ramos'),('Romerillo'),
    ('San José'),('Santa Clara'),('Santa Isabel'),('Santa Lucía'),
    ('Santa Rosa'),('Santa Teresita')
) AS v(nombre)
WHERE c.nombre = 'El Encano';

-- EL SOCORRO
INSERT INTO public.veredas (nombre, corregimiento_id)
SELECT v.nombre, c.id FROM public.corregimientos c,
(VALUES
    ('Bajo Casanare'),('El Carmen'),('El Socorro'),('San Gabriel')
) AS v(nombre)
WHERE c.nombre = 'El Socorro';

-- GENOY
INSERT INTO public.veredas (nombre, corregimiento_id)
SELECT v.nombre, c.id FROM public.corregimientos c,
(VALUES
    ('Aguapamba'),('Bella Vista'),('Castillo Loma'),('Charguayaco'),
    ('El Edén'),('La Cocha'),('Nueva Campiña'),('Pullitopamba')
) AS v(nombre)
WHERE c.nombre = 'Genoy';

-- GUALMATÁN
INSERT INTO public.veredas (nombre, corregimiento_id)
SELECT v.nombre, c.id FROM public.corregimientos c,
(VALUES
    ('Avenida Fátima'),('Gualmatán Alto'),('Gualmatan Bajo'),
    ('Gualmatan Centro'),('Huertecillas'),('Nueva Betania'),('Vocacional')
) AS v(nombre)
WHERE c.nombre = 'Gualmatán';

-- JAMONDINO
INSERT INTO public.veredas (nombre, corregimiento_id)
SELECT v.nombre, c.id FROM public.corregimientos c,
(VALUES
    ('El Rosario'),('Jamondino'),('Santa Helena')
) AS v(nombre)
WHERE c.nombre = 'Jamondino';

-- JONGOVITO
INSERT INTO public.veredas (nombre, corregimiento_id)
SELECT v.nombre, c.id FROM public.corregimientos c,
(VALUES
    ('Armenia'),('Chuquimarca'),('Cruz Loma'),
    ('Josefina'),('San Francisco'),('San Pedro')
) AS v(nombre)
WHERE c.nombre = 'Jongovito';

-- LA CALDERA
INSERT INTO public.veredas (nombre, corregimiento_id)
SELECT v.nombre, c.id FROM public.corregimientos c,
(VALUES
    ('Alto Caldera'),('Arrayán Alto'),('Los Arrayanes'),
    ('Pradera Bajo'),('San Antonio'),('Villa Campiña')
) AS v(nombre)
WHERE c.nombre = 'La Caldera';

-- LA LAGUNA
INSERT INTO public.veredas (nombre, corregimiento_id)
SELECT v.nombre, c.id FROM public.corregimientos c,
(VALUES
    ('Aguapamba'),('Alto San Pedro'),('Dolores Centro'),
    ('El Barbero Y La Playa'),('San Fernando Alto'),
    ('San Fernando Bajo'),('San Luis')
) AS v(nombre)
WHERE c.nombre = 'La Laguna';

-- MAPACHICO
INSERT INTO public.veredas (nombre, corregimiento_id)
SELECT v.nombre, c.id FROM public.corregimientos c,
(VALUES
    ('Anganoy'),('Briceño'),('El Rosal'),('La Victoria'),
    ('Los Lirios'),('San Cayetano'),('San Francisco Briceño'),
    ('San Juan de Anganoy'),('Villa María')
) AS v(nombre)
WHERE c.nombre = 'Mapachico';

-- MOCONDINO
INSERT INTO public.veredas (nombre, corregimiento_id)
SELECT v.nombre, c.id FROM public.corregimientos c,
(VALUES
    ('Canchala'),('Dolores'),('Mocondino'),('Puerres')
) AS v(nombre)
WHERE c.nombre = 'Mocondino';

-- MORASURCO (Daza es cabecera)
INSERT INTO public.veredas (nombre, corregimiento_id, es_cabecera)
SELECT 'Daza', c.id, true FROM public.corregimientos c
WHERE c.nombre = 'Morasurco';

INSERT INTO public.veredas (nombre, corregimiento_id)
SELECT v.nombre, c.id FROM public.corregimientos c,
(VALUES
    ('Chachatoy'),('La Josefina'),('Pinasaco'),
    ('San Antonio de Aranda'),('San Juan Alto'),('San Juan Bajo'),
    ('Tescual'),('Tosoabí')
) AS v(nombre)
WHERE c.nombre = 'Morasurco';

-- OBONUCO
INSERT INTO public.veredas (nombre, corregimiento_id)
SELECT v.nombre, c.id FROM public.corregimientos c,
(VALUES
    ('Bellavista'),('La Playa'),('Mosquera'),('San Antonio'),
    ('San Felipe Alto'),('San Felipe Bajo'),('Santander')
) AS v(nombre)
WHERE c.nombre = 'Obonuco';

-- SAN FERNANDO
INSERT INTO public.veredas (nombre, corregimiento_id)
SELECT v.nombre, c.id FROM public.corregimientos c,
(VALUES
    ('Alto San Fernando'),('Camino Real'),('Caracolito'),
    ('Dolores Retén'),('El Común'),('La Cadena')
) AS v(nombre)
WHERE c.nombre = 'San Fernando';

-- SANTA BÁRBARA
INSERT INTO public.veredas (nombre, corregimiento_id)
SELECT v.nombre, c.id FROM public.corregimientos c,
(VALUES
    ('Cerotal'),('Concepción'),('Jurado'),('La Esperanza'),
    ('Las Encinas'),('Las Iglesias'),('Los Alisales'),
    ('Los Ángeles'),('Santa Bárbara')
) AS v(nombre)
WHERE c.nombre = 'Santa Bárbara';

-- =============================================================
-- MODIFICAR tabla reportes para zona rural
-- =============================================================
ALTER TABLE public.reportes
    ADD COLUMN zona_tipo        VARCHAR(10) NOT NULL DEFAULT 'urbana'
        CHECK (zona_tipo IN ('urbana', 'rural')),
    ADD COLUMN corregimiento_id INTEGER REFERENCES public.corregimientos(id),
    ADD COLUMN vereda_id        INTEGER REFERENCES public.veredas(id);

-- Latitud y longitud opcionales para zona rural
ALTER TABLE public.reportes
    ALTER COLUMN latitud  DROP NOT NULL,
    ALTER COLUMN longitud DROP NOT NULL;

-- Índices
CREATE INDEX idx_reportes_zona_tipo       ON public.reportes (zona_tipo);
CREATE INDEX idx_reportes_corregimiento   ON public.reportes (corregimiento_id);

-- NOTAS:
-- zona_tipo DEFAULT 'urbana' — todos los reportes existentes quedan como urbanos automáticamente
-- corregimiento_id y vereda_id son nullable (solo se llenan en zona rural)
-- Los polígonos de corregimientos (geom) se cargarán a futuro desde
-- MGN_RUR_SECTOR.geojson y MGN_RUR_SECCION.geojson del DANE
-- con un script similar a cargar_secciones.js
