-- Migración 018: Solicitudes de eliminación de reportes

CREATE TABLE public.solicitudes_eliminacion (
    id                  UUID        PRIMARY KEY DEFAULT gen_random_uuid(),
    reporte_id          UUID        NOT NULL REFERENCES public.reportes(id) ON DELETE CASCADE,
    usuario_id          UUID        NOT NULL REFERENCES public.usuarios(id) ON DELETE CASCADE,
    estado_solicitud    VARCHAR(20) NOT NULL DEFAULT 'pendiente'
        CHECK (estado_solicitud IN ('pendiente', 'aprobada', 'rechazada')),
    motivo              TEXT,
    fecha_solicitud     TIMESTAMP   NOT NULL DEFAULT now(),
    fecha_resolucion    TIMESTAMP,
    admin_id            UUID        REFERENCES public.usuarios(id) ON DELETE SET NULL
);

CREATE INDEX idx_solicitudes_estado   ON public.solicitudes_eliminacion (estado_solicitud);
CREATE INDEX idx_solicitudes_reporte  ON public.solicitudes_eliminacion (reporte_id);
CREATE INDEX idx_solicitudes_usuario  ON public.solicitudes_eliminacion (usuario_id);

-- Un reporte no puede tener múltiples solicitudes pendientes simultáneamente
CREATE UNIQUE INDEX uniq_solicitud_pendiente_por_reporte
    ON public.solicitudes_eliminacion (reporte_id)
    WHERE estado_solicitud = 'pendiente';
