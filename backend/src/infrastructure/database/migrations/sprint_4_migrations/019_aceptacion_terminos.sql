-- Migración 019: Aceptación de términos y condiciones

CREATE TABLE public.aceptacion_terminos (
    id                  UUID        PRIMARY KEY DEFAULT gen_random_uuid(),
    usuario_id          UUID        NOT NULL REFERENCES public.usuarios(id) ON DELETE CASCADE,
    version_terminos    VARCHAR(10) NOT NULL DEFAULT 'v1.0',
    fecha_aceptacion    TIMESTAMP   NOT NULL DEFAULT now(),
    ip_origen           VARCHAR(45)
);

CREATE INDEX idx_aceptacion_usuario ON public.aceptacion_terminos (usuario_id);
CREATE INDEX idx_aceptacion_version ON public.aceptacion_terminos (version_terminos);
