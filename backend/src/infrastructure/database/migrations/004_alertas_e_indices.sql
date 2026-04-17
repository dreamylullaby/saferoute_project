-- =============================================================
-- Migración 004: Alertas, índices y vistas para consultas
-- HU-07: configuración y registro de alertas por proximidad
-- HU-08: índices para consultas de mapa
-- HU-09: índices para filtros de mapa y estadísticas
-- HU-10: índices para panel de administración
-- HU-11: vista de estadísticas básicas
-- HU-12: vista de ranking de zonas con más hurtos
-- =============================================================

-- =========================================================
-- TABLA: configuracion_alertas (HU-07)
-- =========================================================
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

-- =========================================================
-- TABLA: alertas (HU-07)
-- =========================================================
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

-- =========================================================
-- ÍNDICES: Filtros generales (HU-09)
-- =========================================================
CREATE INDEX IF NOT EXISTS idx_reportes_fecha_incidente ON public.reportes (fecha_incidente);
CREATE INDEX IF NOT EXISTS idx_reportes_franja_horaria  ON public.reportes (franja_horaria);
CREATE INDEX IF NOT EXISTS idx_reportes_zona_id         ON public.reportes (zona_id);
CREATE INDEX IF NOT EXISTS idx_reportes_comuna          ON public.reportes (comuna);
CREATE INDEX IF NOT EXISTS idx_reportes_tipo_hurto      ON public.reportes (tipo_hurto);
CREATE INDEX IF NOT EXISTS idx_reportes_estado          ON public.reportes (estado);
CREATE INDEX IF NOT EXISTS idx_reportes_estado_fecha    ON public.reportes (estado, fecha_incidente);
CREATE INDEX IF NOT EXISTS idx_reportes_estado_zona     ON public.reportes (estado, zona_id);

-- =========================================================
-- ÍNDICES: Alertas
-- =========================================================
CREATE INDEX IF NOT EXISTS idx_alertas_usuario_leida    ON public.alertas (usuario_id, leida);
CREATE INDEX IF NOT EXISTS idx_alertas_reporte          ON public.alertas (reporte_id);

-- =========================================================
-- ÍNDICES: Mapa interactivo (HU-08)
-- =========================================================
CREATE INDEX IF NOT EXISTS idx_reportes_latitud_longitud
    ON public.reportes (latitud, longitud);

CREATE INDEX IF NOT EXISTS idx_reportes_estado_coords
    ON public.reportes (estado, latitud, longitud);

CREATE INDEX IF NOT EXISTS idx_reportes_fecha_creacion
    ON public.reportes (fecha_creacion DESC);

-- =========================================================
-- ÍNDICES: Panel de administración (HU-10)
-- Optimizan listados filtrados por fecha, zona, comuna,
-- tipo de hurto y estado para gestión administrativa
-- =========================================================

-- Consulta admin: filtrar por estado + fecha + comuna (listado principal)
CREATE INDEX IF NOT EXISTS idx_reportes_estado_fecha_comuna
    ON public.reportes (estado, fecha_incidente, comuna);

-- Consulta admin: filtrar por estado + comuna + tipo_hurto (desglose por tipo)
CREATE INDEX IF NOT EXISTS idx_reportes_estado_comuna_tipo
    ON public.reportes (estado, comuna, tipo_hurto);

-- Consulta admin: filtrar por estado + fecha + zona_id (detalle por barrio)
CREATE INDEX IF NOT EXISTS idx_reportes_estado_fecha_zona
    ON public.reportes (estado, fecha_incidente, zona_id);

-- Consulta admin: reportes por usuario (auditoría)
CREATE INDEX IF NOT EXISTS idx_reportes_usuario_id
    ON public.reportes (usuario_id);

-- Consulta admin: reportes actualizados por admin (trazabilidad)
CREATE INDEX IF NOT EXISTS idx_reportes_actualizado_por
    ON public.reportes (actualizado_por)
    WHERE actualizado_por IS NOT NULL;

-- =========================================================
-- VISTA: vw_estadisticas_basicas (HU-11)
-- Estadísticas generales de reportes activos:
-- total, por día, por franja horaria
-- Permite comparación entre periodos filtrando por fecha
-- =========================================================
CREATE OR REPLACE VIEW public.vw_estadisticas_basicas AS
WITH reportes_activos AS (
    SELECT
        id,
        fecha_incidente,
        franja_horaria,
        tipo_hurto,
        comuna,
        zona_id,
        fecha_creacion
    FROM public.reportes
    WHERE estado = 'activo'
),
total AS (
    SELECT COUNT(*) AS total_reportes FROM reportes_activos
),
por_dia AS (
    SELECT
        fecha_incidente,
        COUNT(*) AS cantidad
    FROM reportes_activos
    GROUP BY fecha_incidente
),
por_franja AS (
    SELECT
        franja_horaria,
        COUNT(*) AS cantidad
    FROM reportes_activos
    GROUP BY franja_horaria
)
SELECT
    t.total_reportes,
    pd.fecha_incidente,
    pd.cantidad AS reportes_dia,
    pf.franja_horaria,
    pf.cantidad AS reportes_franja
FROM total t
CROSS JOIN por_dia pd
CROSS JOIN por_franja pf;

-- =========================================================
-- VISTA: vw_estadisticas_por_periodo (HU-11)
-- Vista auxiliar para comparación entre periodos
-- Agrupa reportes activos por semana (ISO) para facilitar
-- comparaciones tipo "esta semana vs anterior"
-- =========================================================
CREATE OR REPLACE VIEW public.vw_estadisticas_por_periodo AS
SELECT
    DATE_TRUNC('week', fecha_incidente)::DATE AS semana_inicio,
    COUNT(*)                                  AS total_reportes,
    COUNT(DISTINCT fecha_incidente)           AS dias_con_reportes,
    ROUND(COUNT(*)::NUMERIC /
        NULLIF(COUNT(DISTINCT fecha_incidente), 0), 2) AS promedio_diario
FROM public.reportes
WHERE estado = 'activo'
GROUP BY DATE_TRUNC('week', fecha_incidente)
ORDER BY semana_inicio DESC;

-- =========================================================
-- VISTA: vw_top_zonas_hurtos (HU-12)
-- Ranking de comunas con más hurtos (vista principal)
-- Incluye desglose por tipo de hurto más frecuente
-- =========================================================
CREATE OR REPLACE VIEW public.vw_top_zonas_hurtos AS
WITH conteo_comuna AS (
    SELECT
        r.comuna,
        COUNT(*)            AS total_reportes,
        MAX(r.fecha_incidente) AS ultimo_reporte
    FROM public.reportes r
    WHERE r.estado = 'activo'
      AND r.comuna IS NOT NULL
    GROUP BY r.comuna
),
tipo_frecuente AS (
    SELECT DISTINCT ON (r.comuna)
        r.comuna,
        r.tipo_hurto,
        COUNT(*) AS cantidad_tipo
    FROM public.reportes r
    WHERE r.estado = 'activo'
      AND r.comuna IS NOT NULL
    GROUP BY r.comuna, r.tipo_hurto
    ORDER BY r.comuna, cantidad_tipo DESC
)
SELECT
    cc.comuna,
    cc.total_reportes,
    cc.ultimo_reporte,
    tf.tipo_hurto       AS tipo_hurto_frecuente,
    tf.cantidad_tipo    AS cantidad_tipo_frecuente
FROM conteo_comuna cc
LEFT JOIN tipo_frecuente tf ON cc.comuna = tf.comuna
ORDER BY cc.total_reportes DESC;

-- =========================================================
-- VISTA: vw_top_barrios_hurtos (HU-12)
-- Ranking de barrios con más hurtos dentro de cada comuna
-- Para mostrar el barrio con mayor incidencia
-- =========================================================
CREATE OR REPLACE VIEW public.vw_top_barrios_hurtos AS
SELECT
    r.comuna,
    z.barrio,
    r.zona_id,
    COUNT(*)                    AS total_reportes,
    MAX(r.fecha_incidente)      AS ultimo_reporte
FROM public.reportes r
INNER JOIN public.zonas z ON r.zona_id = z.id
WHERE r.estado = 'activo'
  AND r.zona_id IS NOT NULL
GROUP BY r.comuna, z.barrio, r.zona_id
ORDER BY total_reportes DESC;
