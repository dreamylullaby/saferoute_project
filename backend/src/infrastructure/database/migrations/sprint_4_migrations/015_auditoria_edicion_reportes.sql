-- Migración 015: Tabla auditoria_edicion_reportes (HU-17)

CREATE TABLE IF NOT EXISTS public.auditoria_edicion_reportes (
    id                  UUID        PRIMARY KEY DEFAULT gen_random_uuid(),
    admin_id            UUID        NOT NULL REFERENCES public.usuarios(id) ON DELETE SET NULL,
    reporte_id          UUID        NOT NULL REFERENCES public.reportes(id) ON DELETE CASCADE,
    campos_modificados  TEXT[]      NOT NULL,
    valores_anteriores  JSONB,
    fecha               TIMESTAMP   NOT NULL DEFAULT now()
);

CREATE INDEX idx_auditoria_edicion_reporte_id ON public.auditoria_edicion_reportes (reporte_id, fecha DESC);
CREATE INDEX idx_auditoria_edicion_admin      ON public.auditoria_edicion_reportes (admin_id, fecha DESC);
