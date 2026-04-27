-- Migración 016: Índice perfil (HU-19) + función eliminar cuenta (HU-20)

CREATE INDEX IF NOT EXISTS idx_configuracion_alertas_usuario_id
    ON public.configuracion_alertas (usuario_id);

CREATE OR REPLACE FUNCTION public.eliminar_cuenta_usuario(p_usuario_id UUID)
RETURNS VOID LANGUAGE plpgsql AS $$
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM public.usuarios WHERE id = p_usuario_id AND estado = 'activo'
    ) THEN
        RAISE EXCEPTION 'Usuario no encontrado o ya inactivo: %', p_usuario_id;
    END IF;

    UPDATE public.usuarios SET
        estado = 'eliminado', username = NULL,
        correo = 'eliminado_' || p_usuario_id || '@saferoute.invalid',
        password_hash = NULL, foto_url = NULL, fcm_token = NULL, google_id = NULL
    WHERE id = p_usuario_id;

    DELETE FROM public.configuracion_alertas WHERE usuario_id = p_usuario_id;
    DELETE FROM public.password_resets WHERE usuario_id = p_usuario_id;
END;
$$;
