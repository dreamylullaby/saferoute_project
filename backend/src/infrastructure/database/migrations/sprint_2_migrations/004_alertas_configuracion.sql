-- =============================================================
-- Migración 004: Alertas y configuración de alertas (HU-07)
-- =============================================================

-- TABLA: configuracion_alertas
CREATE TABLE IF NOT EXISTS public.configuracion_alertas (
    id                  UUID        PRIMARY KEY DEFAULT gen_random_uuid(),
    usuario_id          UUID        NOT NULL UNIQUE,
    radio_metros        INTEGER     NOT NULL DEFAULT 500,
    activo              BOOLEAN     NOT NULL DEFAULT true,
    fecha_creacion      TIMESTAMP   NOT NULL DEFAULT now(),
    fecha_actualizacion TIMESTAMP,
    CONSTRAINT fk_config_usuario FOREIGN KEY (usuario_id) REFERENCES public.usuarios(id) ON DELETE CASCADE,
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
    CONSTRAINT fk_alerta_usuario FOREIGN KEY (usuario_id) REFERENCES public.usuarios(id) ON DELETE CASCADE,
    CONSTRAINT fk_alerta_reporte FOREIGN KEY (reporte_id) REFERENCES public.reportes(id) ON DELETE CASCADE
);

-- TABLA: password_resets (HU-13)
CREATE TABLE IF NOT EXISTS public.password_resets (
    id              UUID        PRIMARY KEY DEFAULT gen_random_uuid(),
    usuario_id      UUID        NOT NULL REFERENCES public.usuarios(id) ON DELETE CASCADE,
    token           TEXT        NOT NULL,
    expiration      TIMESTAMP   NOT NULL,
    usado           BOOLEAN     NOT NULL DEFAULT false,
    fecha_creacion  TIMESTAMP   NOT NULL DEFAULT now()
);

-- Índices alertas
CREATE INDEX idx_alertas_usuario_leida ON public.alertas (usuario_id, leida);
CREATE INDEX idx_alertas_reporte       ON public.alertas (reporte_id);

-- Índices password_resets
CREATE INDEX idx_password_resets_token   ON public.password_resets (token);
CREATE INDEX idx_password_resets_usuario ON public.password_resets (usuario_id);
