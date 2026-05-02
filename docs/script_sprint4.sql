-- =============================================================
-- SafeRoute — Script BD: Sprint 4 (HU-14 a HU-21)
-- Base: PostgreSQL 17 (Supabase)
-- Requiere: Sprint 1, 2 y 3 ejecutados previamente
-- =============================================================


-- =============================================================
-- HU-14: Gestión de cuentas de usuarios (admin)
-- =============================================================

CREATE TABLE public.auditoria_usuarios (
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


-- =============================================================
-- HU-15: Estadísticas avanzadas para administrador
-- =============================================================

-- Vista principal de estadísticas admin
CREATE OR REPLACE VIEW public.vw_estadisticas_admin AS
SELECT
    r.comuna, z.barrio, r.tipo_hurto, r.franja_horaria,
    r.estado AS estado_reporte,
    DATE_TRUNC('month', r.fecha_incidente)::DATE AS mes,
    COUNT(*) AS total_reportes,
    COUNT(DISTINCT r.incidente_id) AS total_incidentes,
    MIN(r.fecha_incidente) AS primer_incidente,
    MAX(r.fecha_incidente) AS ultimo_incidente
FROM public.reportes r
LEFT JOIN public.zonas z ON r.zona_id = z.id
GROUP BY r.comuna, z.barrio, r.tipo_hurto, r.franja_horaria, r.estado,
    DATE_TRUNC('month', r.fecha_incidente)
ORDER BY total_reportes DESC;

-- Vista de tendencias por zona y tipo de hurto
CREATE OR REPLACE VIEW public.vw_tendencias_zona_tipo AS
SELECT
    r.comuna, z.barrio, r.tipo_hurto,
    DATE_TRUNC('week', r.fecha_incidente)::DATE AS semana_inicio,
    COUNT(*) AS total_reportes,
    COUNT(DISTINCT r.incidente_id) AS total_incidentes
FROM public.reportes r
LEFT JOIN public.zonas z ON r.zona_id = z.id
WHERE r.estado = 'activo'
GROUP BY r.comuna, z.barrio, r.tipo_hurto, DATE_TRUNC('week', r.fecha_incidente)
ORDER BY semana_inicio DESC, total_reportes DESC;

-- Vista de conteo por estado
CREATE OR REPLACE VIEW public.vw_conteo_estado_reportes AS
SELECT
    estado,
    COUNT(*) AS total,
    COUNT(DISTINCT usuario_id) AS usuarios_distintos,
    MIN(fecha_creacion) AS primer_reporte,
    MAX(fecha_creacion) AS ultimo_reporte
FROM public.reportes
GROUP BY estado;

-- Vista de estadísticas por periodo semanal
CREATE OR REPLACE VIEW public.vw_estadisticas_por_periodo AS
SELECT
    DATE_TRUNC('week', fecha_incidente)::DATE AS semana_inicio,
    COUNT(*) AS total_reportes,
    COUNT(DISTINCT fecha_incidente) AS dias_con_reportes,
    ROUND(COUNT(*)::NUMERIC / NULLIF(COUNT(DISTINCT fecha_incidente), 0)::NUMERIC, 2) AS promedio_diario
FROM public.reportes
WHERE estado = 'activo'
GROUP BY DATE_TRUNC('week', fecha_incidente)
ORDER BY semana_inicio DESC;


-- =============================================================
-- HU-16: Eliminar reportes fraudulentos o duplicados (admin)
-- =============================================================

CREATE TABLE public.auditoria_reportes (
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


-- =============================================================
-- HU-17: Editar reportes (admin)
-- =============================================================

CREATE TABLE public.auditoria_edicion_reportes (
    id                  UUID        PRIMARY KEY DEFAULT gen_random_uuid(),
    admin_id            UUID        NOT NULL REFERENCES public.usuarios(id) ON DELETE SET NULL,
    reporte_id          UUID        NOT NULL REFERENCES public.reportes(id) ON DELETE CASCADE,
    campos_modificados  TEXT[]      NOT NULL,
    valores_anteriores  JSONB,
    fecha               TIMESTAMP   NOT NULL DEFAULT now()
);

CREATE INDEX idx_auditoria_edicion_reporte_id ON public.auditoria_edicion_reportes (reporte_id, fecha DESC);
CREATE INDEX idx_auditoria_edicion_admin      ON public.auditoria_edicion_reportes (admin_id, fecha DESC);


-- =============================================================
-- HU-19: Perfil de usuario — configuración personal
-- =============================================================

CREATE INDEX IF NOT EXISTS idx_configuracion_alertas_usuario_id
    ON public.configuracion_alertas (usuario_id);


-- =============================================================
-- HU-20: Eliminación de cuenta (usuario ciudadano)
-- =============================================================

CREATE OR REPLACE FUNCTION public.eliminar_cuenta_usuario(p_usuario_id UUID)
RETURNS VOID LANGUAGE plpgsql AS $$
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM public.usuarios
        WHERE id = p_usuario_id AND estado = 'activo'
    ) THEN
        RAISE EXCEPTION 'Usuario no encontrado o ya inactivo: %', p_usuario_id;
    END IF;

    UPDATE public.usuarios
    SET estado        = 'eliminado',
        username      = NULL,
        correo        = 'eliminado_' || p_usuario_id || '@saferoute.invalid',
        password_hash = NULL,
        foto_url      = NULL,
        fcm_token     = NULL,
        google_id     = NULL
    WHERE id = p_usuario_id;

    DELETE FROM public.configuracion_alertas WHERE usuario_id = p_usuario_id;
    DELETE FROM public.password_resets WHERE usuario_id = p_usuario_id;
END;
$$;


-- =============================================================
-- HU-21: Exportación masiva de reportes (admin)
-- =============================================================

-- Índices de soporte para exportación
CREATE INDEX idx_reportes_estado_fecha_export  ON public.reportes (estado, fecha_incidente DESC);
CREATE INDEX idx_reportes_zona_estado_fecha    ON public.reportes (zona_id, estado, fecha_incidente DESC);
CREATE INDEX idx_reportes_comuna_estado_fecha  ON public.reportes (comuna, estado, fecha_incidente DESC);
CREATE INDEX idx_reportes_estado_fecha_zona    ON public.reportes (estado, fecha_incidente, zona_id);
CREATE INDEX idx_reportes_estado_fecha_comuna  ON public.reportes (estado, fecha_incidente, comuna);

-- Vista de exportación admin
CREATE OR REPLACE VIEW public.vw_export_reportes_admin AS
SELECT
    r.id AS reporte_id, r.fecha_incidente, r.franja_horaria, r.tipo_hurto,
    r.tipo_reportante, r.objeto_hurtado, r.numero_agresores, r.descripcion,
    r.direccion, r.barrio_ingresado,
    z.barrio AS barrio_normalizado, r.comuna, r.zona_tipo,
    c.nombre AS corregimiento, v.nombre AS vereda,
    r.latitud, r.longitud, r.estado,
    r.fecha_creacion, r.fecha_actualizacion,
    u_autor.correo AS correo_reportante,
    u_admin.correo AS actualizado_por_correo,
    r.incidente_id
FROM public.reportes r
LEFT JOIN public.zonas z          ON r.zona_id          = z.id
LEFT JOIN public.corregimientos c ON r.corregimiento_id = c.id
LEFT JOIN public.veredas v        ON r.vereda_id        = v.id
LEFT JOIN public.usuarios u_autor ON r.usuario_id       = u_autor.id
LEFT JOIN public.usuarios u_admin ON r.actualizado_por  = u_admin.id
ORDER BY r.fecha_incidente DESC, r.fecha_creacion DESC;


-- =============================================================
-- TABLA: zonas_riesgo (cálculo de zonas de riesgo)
-- =============================================================

CREATE TABLE public.zonas_riesgo (
    id                  UUID        PRIMARY KEY DEFAULT gen_random_uuid(),
    latitud_centro      NUMERIC(9,6) NOT NULL,
    longitud_centro     NUMERIC(9,6) NOT NULL,
    radio               INTEGER     NOT NULL DEFAULT 200,
    nivel_riesgo        VARCHAR(20) NOT NULL,
    cantidad_reportes   INTEGER     NOT NULL DEFAULT 0,
    fecha_calculo       TIMESTAMP   NOT NULL DEFAULT now(),
    comuna              INTEGER,
    CONSTRAINT chk_comuna_valida CHECK (comuna IS NULL OR (comuna >= 1 AND comuna <= 12)),
    CONSTRAINT chk_radio_positivo CHECK (radio > 0),
    CONSTRAINT zonas_riesgo_nivel_riesgo_check CHECK (nivel_riesgo IN ('seguro', 'medio', 'alto', 'peligroso'))
);

CREATE INDEX idx_zonas_riesgo_coords     ON public.zonas_riesgo (latitud_centro, longitud_centro);
CREATE INDEX idx_zonas_riesgo_nivel      ON public.zonas_riesgo (nivel_riesgo);
CREATE INDEX idx_zonas_riesgo_fecha      ON public.zonas_riesgo (fecha_calculo DESC);
CREATE INDEX idx_zonas_riesgo_comuna     ON public.zonas_riesgo (comuna) WHERE (comuna IS NOT NULL);
CREATE INDEX idx_zonas_riesgo_nivel_fecha ON public.zonas_riesgo (nivel_riesgo, fecha_calculo DESC);


-- =============================================================
-- Solicitudes de eliminación de reportes (usuario → admin)
-- =============================================================

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


-- =============================================================
-- Aceptación de términos y condiciones
-- =============================================================

CREATE TABLE public.aceptacion_terminos (
    id                  UUID        PRIMARY KEY DEFAULT gen_random_uuid(),
    usuario_id          UUID        NOT NULL REFERENCES public.usuarios(id) ON DELETE CASCADE,
    version_terminos    VARCHAR(10) NOT NULL DEFAULT 'v1.0',
    fecha_aceptacion    TIMESTAMP   NOT NULL DEFAULT now(),
    ip_origen           VARCHAR(45)
);

CREATE INDEX idx_aceptacion_usuario ON public.aceptacion_terminos (usuario_id);
CREATE INDEX idx_aceptacion_version ON public.aceptacion_terminos (version_terminos);
