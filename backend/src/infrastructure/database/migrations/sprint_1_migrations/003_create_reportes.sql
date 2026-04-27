-- ========================================
-- 003_create_reportes.sql
-- Crea la tabla de reportes de hurto
-- Depende de: 001_create_usuarios.sql, 002_create_zonas.sql
-- ========================================

CREATE TABLE IF NOT EXISTS public.reportes (
    id                  UUID        PRIMARY KEY DEFAULT gen_random_uuid(),
    usuario_id          UUID        NOT NULL DEFAULT '645c346d-e56a-4022-b488-e8142e0c96a5',
    tipo_reportante     VARCHAR(20) NOT NULL CHECK (tipo_reportante IN ('victima', 'testigo')),
    fecha_incidente     DATE        NOT NULL,
    franja_horaria      VARCHAR(20) NOT NULL CHECK (franja_horaria IN (
                                        '00:00-05:59', '06:00-11:59',
                                        '12:00-17:59', '18:00-23:59')),
    latitud             NUMERIC(9,6),
    longitud            NUMERIC(9,6),
    direccion           VARCHAR(100),
    tipo_hurto          VARCHAR(30) NOT NULL CHECK (tipo_hurto IN ('atraco', 'raponazo', 'cosquilleo', 'fleteo')),
    descripcion         VARCHAR(300),
    objeto_hurtado      VARCHAR(50) CHECK (objeto_hurtado IN (
                                        'celular', 'dinero', 'tarjetas_documentos',
                                        'articulos_personales', 'dispositivos_electronicos')),
    numero_agresores    VARCHAR(20) CHECK (numero_agresores IN ('1', '2', '3+', 'desconocido')),
    fecha_creacion      TIMESTAMP   NOT NULL DEFAULT now(),
    estado              VARCHAR(20) NOT NULL CHECK (estado IN ('activo', 'oculto', 'eliminado')),
    barrio_ingresado    VARCHAR(80) NOT NULL DEFAULT 'SIN DEFINIR',
    zona_id             INTEGER     REFERENCES public.zonas(id),
    comuna              INTEGER,

    CONSTRAINT fk_usuario FOREIGN KEY (usuario_id)
        REFERENCES public.usuarios(id) ON DELETE SET DEFAULT
);

-- Índices Sprint 1
CREATE INDEX idx_reportes_fecha_incidente ON public.reportes (fecha_incidente);
CREATE INDEX idx_reportes_zona_id         ON public.reportes (zona_id);
CREATE INDEX idx_reportes_comuna          ON public.reportes (comuna);
CREATE INDEX idx_reportes_tipo_hurto      ON public.reportes (tipo_hurto);
CREATE INDEX idx_reportes_estado          ON public.reportes (estado);
CREATE INDEX idx_reportes_usuario_id      ON public.reportes (usuario_id);
