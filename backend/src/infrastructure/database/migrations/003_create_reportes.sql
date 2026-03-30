-- ========================================
-- 003_create_reportes.sql
-- Crea la tabla de reportes de hurto
-- Depende de: 001_create_usuarios.sql, 002_create_zonas.sql
-- ========================================

CREATE TABLE IF NOT EXISTS public.reportes (
    id                  UUID        PRIMARY KEY DEFAULT gen_random_uuid(),
    usuario_id          UUID        NOT NULL REFERENCES public.usuarios(id),
    tipo_reportante     VARCHAR     NOT NULL CHECK (tipo_reportante IN ('victima', 'testigo')),
    fecha_incidente     DATE        NOT NULL,
    franja_horaria      VARCHAR     NOT NULL CHECK (franja_horaria IN (
                                        '00:00-05:59',
                                        '06:00-11:59',
                                        '12:00-17:59',
                                        '18:00-23:59'
                                    )),
    latitud             NUMERIC     NOT NULL,
    longitud            NUMERIC     NOT NULL,
    direccion           VARCHAR,
    tipo_hurto          VARCHAR     NOT NULL CHECK (tipo_hurto IN ('atraco', 'raponazo', 'cosquilleo', 'fleteo')),
    descripcion         VARCHAR,
    objeto_hurtado      VARCHAR     CHECK (objeto_hurtado IN (
                                        'celular',
                                        'dinero',
                                        'tarjetas_documentos',
                                        'articulos_personales',
                                        'dispositivos_electronicos'
                                    )),
    numero_agresores    VARCHAR     CHECK (numero_agresores IN ('1', '2', '3+', 'desconocido')),
    fecha_creacion      TIMESTAMP   NOT NULL DEFAULT now(),
    fecha_actualizacion TIMESTAMP,
    actualizado_por     UUID        REFERENCES public.usuarios(id),
    estado              VARCHAR     NOT NULL CHECK (estado IN ('activo', 'oculto', 'eliminado')),

    -- Texto original escrito por el usuario
    barrio_ingresado    VARCHAR     NOT NULL,

    -- Referencia al barrio validado por búsqueda difusa
    zona_id             INTEGER     REFERENCES public.zonas(id)
);

-- Índice para búsqueda por zona
CREATE INDEX idx_reportes_zona ON reportes (zona_id);

-- Insert de prueba
INSERT INTO public.reportes (
    usuario_id, tipo_reportante, fecha_incidente, franja_horaria,
    latitud, longitud, direccion, tipo_hurto, descripcion,
    objeto_hurtado, numero_agresores, estado, barrio_ingresado
)
VALUES (
    (SELECT id FROM public.usuarios WHERE username = 'vigilante1'),
    'victima',
    CURRENT_DATE,
    '12:00-17:59',
    1.234567,
    -76.543210,
    'Calle Falsa 123',
    'raponazo',
    'Me robaron el celular mientras caminaba',
    'celular',
    '1',
    'activo',
    'El Poblado'
);
