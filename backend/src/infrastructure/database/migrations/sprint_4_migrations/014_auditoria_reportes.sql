-- Migración 014: Tabla auditoria_reportes (HU-16)

CREATE TABLE IF NOT EXISTS public.auditoria_reportes (
    id          UUID        PRIMARY KEY DEFAULT gen_random_uuid(),
    admin_id    UUID        NOT NULL REFERENCES public.usuarios(id) ON DELETE SET NULL,
    reporte_id  UUID        NOT NULL REFERENCES public.reportes(id) ON DELETE CASCADE,
    accion      VARCHAR(30) NOT NULL,
    fecha       TIMESTAMP   NOT NULL DEFAULT now(),
    detalle     TEXT,
    CONSTRAINT chk_auditoria_reportes_accion
        CHECK (accion IN ('ocultar', 'eliminar', 'restaurar', 'marcar_duplicado', 'marcar_fraudulento'))
);

CREATE INDEX idx_auditoria_reportes_estado  ON public.auditoria_reportes (accion, fecha DESC);
CREATE INDEX idx_auditoria_reportes_reporte ON public.auditoria_reportes (reporte_id, fecha DESC);
CREATE INDEX idx_auditoria_reportes_admin   ON public.auditoria_reportes (admin_id, fecha DESC);
