-- =============================================================
-- Migración 004: Alertas e índices para filtros
-- HU-07: configuración y registro de alertas por proximidad
-- HU-09: índices para filtros de mapa y estadísticas
-- =============================================================

-- TABLA: configuracion_alertas
CREATE TABLE IF NOT EXISTS public.configuracion_alertas (
    id                  UUID        PRIMARY KEY DEFAULT gen_random_uuid(),
    usuario_id          UUID        NOT NULL UNIQUE,
    radio_metros        INTEGER     NOT NULL DEFAULT 500,
    activo              BOOLEAN     NOT NULL DEFAULT true,
    fecha_creacion      TIMESTAMP   NOT NULL DEFAULT now(),
    fecha_actualizacion TIMESTAMP,

    CONSTRAINT fk_config_usuario
        FOREIGN KEY (usuario_id) REFERENCES public.usuarios(id) ON DELETE CASCADE,
    CONSTRAINT chk_radio_minimo CHECK (radio_metros >= 100),
    CONSTRAINT chk_radio_maximo CHECK (radio_metros <= 5000)
);

-- TABLA: alertas
CREATE TABLE IF NOT EXISTS public.alertas (
    id               UUID        PRIMARY KEY DEFAULT gen_random_uuid(),
    usuario_id       UUID        NOT NULL,
    reporte_id       UUID        NOT NULL,
    distancia_metros NUMERIC(8,2),
    leida            BOOLEAN     NOT NULL DEFAULT false,
    fecha_creacion   TIMESTAMP   NOT NULL DEFAULT now(),
    fecha_leida      TIMESTAMP,

    CONSTRAINT fk_alerta_usuario
        FOREIGN KEY (usuario_id) REFERENCES public.usuarios(id) ON DELETE CASCADE,
    CONSTRAINT fk_alerta_reporte
        FOREIGN KEY (reporte_id) REFERENCES public.reportes(id) ON DELETE CASCADE
);

-- ÍNDICES para filtros (HU-09)
CREATE INDEX IF NOT EXISTS idx_reportes_fecha_incidente ON public.reportes (fecha_incidente);
CREATE INDEX IF NOT EXISTS idx_reportes_franja_horaria  ON public.reportes (franja_horaria);
CREATE INDEX IF NOT EXISTS idx_reportes_zona_id         ON public.reportes (zona_id);
CREATE INDEX IF NOT EXISTS idx_reportes_comuna          ON public.reportes (comuna);
CREATE INDEX IF NOT EXISTS idx_reportes_tipo_hurto      ON public.reportes (tipo_hurto);
CREATE INDEX IF NOT EXISTS idx_reportes_estado          ON public.reportes (estado);
CREATE INDEX IF NOT EXISTS idx_reportes_estado_fecha    ON public.reportes (estado, fecha_incidente);
CREATE INDEX IF NOT EXISTS idx_reportes_estado_zona     ON public.reportes (estado, zona_id);

-- ÍNDICES para alertas
CREATE INDEX IF NOT EXISTS idx_alertas_usuario_leida    ON public.alertas (usuario_id, leida);
CREATE INDEX IF NOT EXISTS idx_alertas_reporte          ON public.alertas (reporte_id);

-- ÍNDICES para consultas de mapa (HU-08)
-- Optimizan la carga de marcadores por ubicación y estado

-- Índice compuesto latitud/longitud para queries de bounding box del mapa
CREATE INDEX IF NOT EXISTS idx_reportes_latitud_longitud
    ON public.reportes (latitud, longitud);

-- Índice compuesto: estado + coordenadas (query principal del mapa: activos en área visible)
CREATE INDEX IF NOT EXISTS idx_reportes_estado_coords
    ON public.reportes (estado, latitud, longitud);

-- Índice por fecha_creacion para actualización automática cada minuto (HU-08)
CREATE INDEX IF NOT EXISTS idx_reportes_fecha_creacion
    ON public.reportes (fecha_creacion DESC);
