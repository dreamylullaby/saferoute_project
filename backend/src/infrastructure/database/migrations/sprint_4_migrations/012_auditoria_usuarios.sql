-- Migración 012: Tabla auditoria_usuarios (HU-14)

CREATE TABLE IF NOT EXISTS public.auditoria_usuarios (
    id          UUID        PRIMARY KEY DEFAULT gen_random_uuid(),
    admin_id    UUID        NOT NULL REFERENCES public.usuarios(id) ON DELETE SET NULL,
    usuario_id  UUID        NOT NULL REFERENCES public.usuarios(id) ON DELETE CASCADE,
    accion      VARCHAR(30) NOT NULL,
    fecha       TIMESTAMP   NOT NULL DEFAULT now(),
    detalle     TEXT,
    CONSTRAINT chk_auditoria_usuarios_accion
        CHECK (accion IN ('ver', 'bloquear', 'desbloquear', 'reactivar', 'eliminar'))
);

CREATE INDEX idx_auditoria_usuarios_estado_fecha ON public.auditoria_usuarios (admin_id, fecha DESC);
CREATE INDEX idx_auditoria_usuarios_usuario      ON public.auditoria_usuarios (usuario_id, fecha DESC);
