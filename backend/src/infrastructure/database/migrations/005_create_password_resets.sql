-- ========================================
-- 005_create_password_resets.sql
-- Tabla para recuperación de contraseña (HU-13)
-- Depende de: 001_create_usuarios.sql
-- ========================================

CREATE TABLE IF NOT EXISTS public.password_resets (
    id              UUID        PRIMARY KEY DEFAULT gen_random_uuid(),
    usuario_id      UUID        NOT NULL REFERENCES public.usuarios(id) ON DELETE CASCADE,
    token           TEXT        NOT NULL,
    expiration      TIMESTAMP   NOT NULL,
    usado           BOOLEAN     NOT NULL DEFAULT false,
    fecha_creacion  TIMESTAMP   NOT NULL DEFAULT now()
);

-- Índice por token para búsqueda rápida al validar el enlace
CREATE INDEX idx_password_resets_token ON public.password_resets (token);

-- Índice para limpiar tokens expirados o buscar por usuario
CREATE INDEX idx_password_resets_usuario ON public.password_resets (usuario_id);
