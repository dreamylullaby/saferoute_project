-- ============================================================
-- SafeRoute - Script de Base de Datos
-- PostgreSQL 17 + PostGIS + Supabase
-- Generado: Abril 2026
-- ============================================================

-- ============================================================
-- 1. EXTENSIONES
-- ============================================================

CREATE EXTENSION IF NOT EXISTS fuzzystrmatch WITH SCHEMA public;
CREATE EXTENSION IF NOT EXISTS pgcrypto WITH SCHEMA extensions;
CREATE EXTENSION IF NOT EXISTS postgis WITH SCHEMA public;
CREATE EXTENSION IF NOT EXISTS unaccent WITH SCHEMA public;
CREATE EXTENSION IF NOT EXISTS "uuid-ossp" WITH SCHEMA extensions;

-- ============================================================
-- 2. TABLAS
-- ============================================================

-- Usuarios del sistema
CREATE TABLE public.usuarios (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    username character varying(50) NOT NULL,
    correo character varying(150) NOT NULL,
    password_hash text,
    foto_url text,
    rol character varying(20) NOT NULL,
    auth_provider character varying(20) NOT NULL,
    google_id character varying(255),
    fecha_creacion timestamp without time zone DEFAULT now() NOT NULL,
    estado character varying(20) NOT NULL,
    fcm_token text,
    CONSTRAINT usuarios_auth_provider_check CHECK (((auth_provider)::text[] <@ ARRAY['local', 'google']::text[] AND array_length(auth_provider, 1) > 0)),
    CONSTRAINT usuarios_estado_check CHECK (((estado)::text = ANY (ARRAY['activo', 'bloqueado', 'eliminado', 'oculto']::text[]))),
    CONSTRAINT usuarios_rol_check CHECK (((rol)::text = ANY (ARRAY['usuario', 'admin']::text[]))),
    CONSTRAINT usuarios_pkey PRIMARY KEY (id),
    CONSTRAINT usuarios_correo_key UNIQUE (correo),
    CONSTRAINT usuarios_google_id_key UNIQUE (google_id),
    CONSTRAINT usuarios_username_key UNIQUE (username)
);

-- Zonas (barrios) de la ciudad
CREATE TABLE public.zonas (
    id serial NOT NULL,
    barrio character varying(80) NOT NULL,
    comuna integer NOT NULL,
    geom public.geometry(MultiPolygon,4326),
    CONSTRAINT chk_barrio_not_empty CHECK (((barrio)::text <> ''::text)),
    CONSTRAINT zonas_comuna_check CHECK ((comuna >= 1 AND comuna <= 12)),
    CONSTRAINT zonas_pkey PRIMARY KEY (id),
    CONSTRAINT uniq_barrio_comuna UNIQUE (barrio, comuna)
);

-- Corregimientos (zonas rurales)
CREATE TABLE public.corregimientos (
    id serial NOT NULL,
    nombre character varying(80) NOT NULL,
    geom public.geometry(MultiPolygon,4326),
    CONSTRAINT chk_corregimiento_not_empty CHECK (((nombre)::text <> ''::text)),
    CONSTRAINT corregimientos_pkey PRIMARY KEY (id),
    CONSTRAINT uniq_corregimiento UNIQUE (nombre)
);

-- Veredas dentro de corregimientos
CREATE TABLE public.veredas (
    id serial NOT NULL,
    nombre character varying(80) NOT NULL,
    corregimiento_id integer NOT NULL,
    es_cabecera boolean DEFAULT false NOT NULL,
    CONSTRAINT chk_vereda_not_empty CHECK (((nombre)::text <> ''::text)),
    CONSTRAINT veredas_pkey PRIMARY KEY (id)
);

-- Secciones censales del DANE
CREATE TABLE public.secciones_dane (
    id serial NOT NULL,
    secu_ccdgo character varying(10),
    setu_ccdgo character varying(10),
    comuna integer,
    geom public.geometry(MultiPolygon,4326),
    CONSTRAINT secciones_dane_pkey PRIMARY KEY (id)
);

-- Reportes de hurtos
CREATE TABLE public.reportes (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    usuario_id uuid DEFAULT '645c346d-e56a-4022-b488-e8142e0c96a5'::uuid NOT NULL,
    tipo_reportante character varying(20) NOT NULL,
    fecha_incidente date NOT NULL,
    franja_horaria character varying(20) NOT NULL,
    latitud numeric(9,6),
    longitud numeric(9,6),
    direccion character varying(100),
    tipo_hurto character varying(30) NOT NULL,
    descripcion character varying(300),
    objeto_hurtado character varying(50),
    numero_agresores character varying(20),
    fecha_creacion timestamp without time zone DEFAULT now() NOT NULL,
    fecha_actualizacion timestamp without time zone,
    actualizado_por uuid,
    estado character varying(20) NOT NULL,
    barrio_ingresado character varying(80) DEFAULT 'SIN DEFINIR'::character varying NOT NULL,
    zona_id integer,
    comuna integer,
    zona_tipo character varying(10) DEFAULT 'urbana'::character varying NOT NULL,
    corregimiento_id integer,
    vereda_id integer,
    incidente_id uuid,
    CONSTRAINT reportes_estado_check CHECK (((estado)::text = ANY (ARRAY['activo', 'oculto', 'eliminado']::text[]))),
    CONSTRAINT reportes_franja_horaria_check CHECK (((franja_horaria)::text = ANY (ARRAY['00:00-05:59', '06:00-11:59', '12:00-17:59', '18:00-23:59']::text[]))),
    CONSTRAINT reportes_numero_agresores_check CHECK (((numero_agresores)::text = ANY (ARRAY['1', '2', '3+', 'desconocido']::text[]))),
    CONSTRAINT reportes_objeto_hurtado_check CHECK (((objeto_hurtado)::text = ANY (ARRAY['celular', 'dinero', 'tarjetas_documentos', 'articulos_personales', 'dispositivos_electronicos']::text[]))),
    CONSTRAINT reportes_tipo_hurto_check CHECK (((tipo_hurto)::text = ANY (ARRAY['atraco', 'raponazo', 'cosquilleo', 'fleteo']::text[]))),
    CONSTRAINT reportes_tipo_reportante_check CHECK (((tipo_reportante)::text = ANY (ARRAY['victima', 'testigo']::text[]))),
    CONSTRAINT reportes_zona_tipo_check CHECK (((zona_tipo)::text = ANY (ARRAY['urbana', 'rural']::text[]))),
    CONSTRAINT reportes_pkey PRIMARY KEY (id)
);

-- Incidentes (agrupación de reportes cercanos)
CREATE TABLE public.incidentes (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    reporte_principal_id uuid NOT NULL,
    tipo_hurto character varying(30) NOT NULL,
    fecha_incidente date NOT NULL,
    franja_horaria character varying(20) NOT NULL,
    latitud_centro numeric(9,6),
    longitud_centro numeric(9,6),
    zona_id integer,
    comuna integer,
    cantidad_reportes integer DEFAULT 1 NOT NULL,
    fecha_creacion timestamp without time zone DEFAULT now() NOT NULL,
    CONSTRAINT chk_incidente_comuna CHECK ((comuna IS NULL OR (comuna >= 1 AND comuna <= 12))),
    CONSTRAINT incidentes_franja_horaria_check CHECK (((franja_horaria)::text = ANY (ARRAY['00:00-05:59', '06:00-11:59', '12:00-17:59', '18:00-23:59']::text[]))),
    CONSTRAINT incidentes_tipo_hurto_check CHECK (((tipo_hurto)::text = ANY (ARRAY['atraco', 'raponazo', 'cosquilleo', 'fleteo']::text[]))),
    CONSTRAINT incidentes_pkey PRIMARY KEY (id)
);

-- Alertas a usuarios por cercanía
CREATE TABLE public.alertas (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    usuario_id uuid NOT NULL,
    reporte_id uuid NOT NULL,
    distancia_metros numeric(8,2),
    leida boolean DEFAULT false NOT NULL,
    fecha_creacion timestamp without time zone DEFAULT now() NOT NULL,
    fecha_leida timestamp without time zone,
    CONSTRAINT alertas_pkey PRIMARY KEY (id)
);

-- Configuración de alertas por usuario
CREATE TABLE public.configuracion_alertas (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    usuario_id uuid NOT NULL,
    radio_metros integer DEFAULT 500 NOT NULL,
    activo boolean DEFAULT true NOT NULL,
    fecha_creacion timestamp without time zone DEFAULT now() NOT NULL,
    fecha_actualizacion timestamp without time zone,
    CONSTRAINT chk_radio_maximo CHECK ((radio_metros <= 5000)),
    CONSTRAINT chk_radio_minimo CHECK ((radio_metros >= 100)),
    CONSTRAINT configuracion_alertas_pkey PRIMARY KEY (id),
    CONSTRAINT configuracion_alertas_usuario_id_key UNIQUE (usuario_id)
);

-- Tokens de recuperación de contraseña
CREATE TABLE public.password_resets (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    usuario_id uuid NOT NULL,
    token text NOT NULL,
    expiration timestamp without time zone NOT NULL,
    usado boolean DEFAULT false NOT NULL,
    fecha_creacion timestamp without time zone DEFAULT now() NOT NULL,
    CONSTRAINT password_resets_pkey PRIMARY KEY (id)
);

-- Auditoría de acciones sobre reportes (ocultar, eliminar, etc.)
CREATE TABLE public.auditoria_reportes (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    admin_id uuid NOT NULL,
    reporte_id uuid NOT NULL,
    accion character varying(30) NOT NULL,
    fecha timestamp without time zone DEFAULT now() NOT NULL,
    detalle text,
    CONSTRAINT chk_auditoria_reportes_accion CHECK (((accion)::text = ANY (ARRAY['ocultar', 'eliminar', 'restaurar', 'marcar_duplicado', 'marcar_fraudulento']::text[]))),
    CONSTRAINT auditoria_reportes_pkey PRIMARY KEY (id)
);

-- Auditoría de ediciones a reportes
CREATE TABLE public.auditoria_edicion_reportes (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    admin_id uuid NOT NULL,
    reporte_id uuid NOT NULL,
    campos_modificados text[] NOT NULL,
    valores_anteriores jsonb,
    fecha timestamp without time zone DEFAULT now() NOT NULL,
    CONSTRAINT auditoria_edicion_reportes_pkey PRIMARY KEY (id)
);

-- Auditoría de acciones sobre usuarios
CREATE TABLE public.auditoria_usuarios (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    admin_id uuid NOT NULL,
    usuario_id uuid NOT NULL,
    accion character varying(30) NOT NULL,
    fecha timestamp without time zone DEFAULT now() NOT NULL,
    detalle text,
    CONSTRAINT chk_auditoria_usuarios_accion CHECK (((accion)::text = ANY (ARRAY['ver', 'bloquear', 'desbloquear', 'reactivar', 'eliminar']::text[]))),
    CONSTRAINT auditoria_usuarios_pkey PRIMARY KEY (id)
);

-- Zonas de riesgo calculadas
CREATE TABLE public.zonas_riesgo (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    latitud_centro numeric(9,6) NOT NULL,
    longitud_centro numeric(9,6) NOT NULL,
    radio integer DEFAULT 200 NOT NULL,
    nivel_riesgo character varying(20) NOT NULL,
    cantidad_reportes integer DEFAULT 0 NOT NULL,
    fecha_calculo timestamp without time zone DEFAULT now() NOT NULL,
    comuna integer,
    CONSTRAINT chk_comuna_valida CHECK ((comuna IS NULL OR (comuna >= 1 AND comuna <= 12))),
    CONSTRAINT chk_radio_positivo CHECK ((radio > 0)),
    CONSTRAINT zonas_riesgo_nivel_riesgo_check CHECK (((nivel_riesgo)::text = ANY (ARRAY['seguro', 'medio', 'alto', 'peligroso']::text[]))),
    CONSTRAINT zonas_riesgo_pkey PRIMARY KEY (id)
);

-- Solicitudes de eliminación de reportes
CREATE TABLE public.solicitudes_eliminacion (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    reporte_id uuid NOT NULL,
    usuario_id uuid NOT NULL,
    estado_solicitud character varying(20) DEFAULT 'pendiente' NOT NULL,
    motivo text,
    fecha_solicitud timestamp without time zone DEFAULT now() NOT NULL,
    fecha_resolucion timestamp without time zone,
    admin_id uuid,
    CONSTRAINT solicitudes_eliminacion_estado_check CHECK (((estado_solicitud)::text = ANY (ARRAY['pendiente', 'aprobada', 'rechazada']::text[]))),
    CONSTRAINT solicitudes_eliminacion_pkey PRIMARY KEY (id)
);

-- Aceptación de términos y condiciones
CREATE TABLE public.aceptacion_terminos (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    usuario_id uuid NOT NULL,
    version_terminos character varying(10) DEFAULT 'v1.0' NOT NULL,
    fecha_aceptacion timestamp without time zone DEFAULT now() NOT NULL,
    ip_origen character varying(45),
    CONSTRAINT aceptacion_terminos_pkey PRIMARY KEY (id)
);

-- ============================================================
-- 3. FOREIGN KEYS (Relaciones)
-- ============================================================

-- veredas -> corregimientos
ALTER TABLE ONLY public.veredas
    ADD CONSTRAINT veredas_corregimiento_id_fkey FOREIGN KEY (corregimiento_id) REFERENCES public.corregimientos(id);

-- reportes -> usuarios
ALTER TABLE ONLY public.reportes
    ADD CONSTRAINT fk_usuario FOREIGN KEY (usuario_id) REFERENCES public.usuarios(id) ON DELETE SET DEFAULT;

ALTER TABLE ONLY public.reportes
    ADD CONSTRAINT fk_actualizado_por FOREIGN KEY (actualizado_por) REFERENCES public.usuarios(id) ON DELETE SET NULL;

-- reportes -> zonas / corregimientos / veredas / incidentes
ALTER TABLE ONLY public.reportes
    ADD CONSTRAINT fk_zona FOREIGN KEY (zona_id) REFERENCES public.zonas(id);

ALTER TABLE ONLY public.reportes
    ADD CONSTRAINT reportes_corregimiento_id_fkey FOREIGN KEY (corregimiento_id) REFERENCES public.corregimientos(id);

ALTER TABLE ONLY public.reportes
    ADD CONSTRAINT reportes_vereda_id_fkey FOREIGN KEY (vereda_id) REFERENCES public.veredas(id);

ALTER TABLE ONLY public.reportes
    ADD CONSTRAINT fk_reporte_incidente FOREIGN KEY (incidente_id) REFERENCES public.incidentes(id) ON DELETE SET NULL;

-- incidentes -> reportes / zonas
ALTER TABLE ONLY public.incidentes
    ADD CONSTRAINT fk_reporte_principal FOREIGN KEY (reporte_principal_id) REFERENCES public.reportes(id) ON DELETE RESTRICT;

ALTER TABLE ONLY public.incidentes
    ADD CONSTRAINT fk_incidente_zona FOREIGN KEY (zona_id) REFERENCES public.zonas(id);

-- alertas -> usuarios / reportes
ALTER TABLE ONLY public.alertas
    ADD CONSTRAINT fk_alerta_usuario FOREIGN KEY (usuario_id) REFERENCES public.usuarios(id) ON DELETE CASCADE;

ALTER TABLE ONLY public.alertas
    ADD CONSTRAINT fk_alerta_reporte FOREIGN KEY (reporte_id) REFERENCES public.reportes(id) ON DELETE CASCADE;

-- configuracion_alertas -> usuarios
ALTER TABLE ONLY public.configuracion_alertas
    ADD CONSTRAINT fk_config_usuario FOREIGN KEY (usuario_id) REFERENCES public.usuarios(id) ON DELETE CASCADE;

-- password_resets -> usuarios
ALTER TABLE ONLY public.password_resets
    ADD CONSTRAINT password_resets_usuario_id_fkey FOREIGN KEY (usuario_id) REFERENCES public.usuarios(id) ON DELETE CASCADE;

-- auditoría -> usuarios / reportes
ALTER TABLE ONLY public.auditoria_reportes
    ADD CONSTRAINT auditoria_reportes_admin_id_fkey FOREIGN KEY (admin_id) REFERENCES public.usuarios(id) ON DELETE SET NULL;

ALTER TABLE ONLY public.auditoria_reportes
    ADD CONSTRAINT auditoria_reportes_reporte_id_fkey FOREIGN KEY (reporte_id) REFERENCES public.reportes(id) ON DELETE CASCADE;

ALTER TABLE ONLY public.auditoria_edicion_reportes
    ADD CONSTRAINT auditoria_edicion_reportes_admin_id_fkey FOREIGN KEY (admin_id) REFERENCES public.usuarios(id) ON DELETE SET NULL;

ALTER TABLE ONLY public.auditoria_edicion_reportes
    ADD CONSTRAINT auditoria_edicion_reportes_reporte_id_fkey FOREIGN KEY (reporte_id) REFERENCES public.reportes(id) ON DELETE CASCADE;

ALTER TABLE ONLY public.auditoria_usuarios
    ADD CONSTRAINT auditoria_usuarios_admin_id_fkey FOREIGN KEY (admin_id) REFERENCES public.usuarios(id) ON DELETE SET NULL;

ALTER TABLE ONLY public.auditoria_usuarios
    ADD CONSTRAINT auditoria_usuarios_usuario_id_fkey FOREIGN KEY (usuario_id) REFERENCES public.usuarios(id) ON DELETE CASCADE;

-- solicitudes_eliminacion -> reportes / usuarios
ALTER TABLE ONLY public.solicitudes_eliminacion
    ADD CONSTRAINT solicitudes_eliminacion_reporte_fkey FOREIGN KEY (reporte_id) REFERENCES public.reportes(id) ON DELETE CASCADE;

ALTER TABLE ONLY public.solicitudes_eliminacion
    ADD CONSTRAINT solicitudes_eliminacion_usuario_fkey FOREIGN KEY (usuario_id) REFERENCES public.usuarios(id) ON DELETE CASCADE;

ALTER TABLE ONLY public.solicitudes_eliminacion
    ADD CONSTRAINT solicitudes_eliminacion_admin_fkey FOREIGN KEY (admin_id) REFERENCES public.usuarios(id) ON DELETE SET NULL;

-- aceptacion_terminos -> usuarios
ALTER TABLE ONLY public.aceptacion_terminos
    ADD CONSTRAINT aceptacion_terminos_usuario_fkey FOREIGN KEY (usuario_id) REFERENCES public.usuarios(id) ON DELETE CASCADE;

-- ============================================================
-- 4. ÍNDICES
-- ============================================================

-- Reportes
CREATE INDEX idx_reportes_usuario_id ON public.reportes USING btree (usuario_id);
CREATE INDEX idx_reportes_estado ON public.reportes USING btree (estado);
CREATE INDEX idx_reportes_fecha_incidente ON public.reportes USING btree (fecha_incidente);
CREATE INDEX idx_reportes_fecha_creacion ON public.reportes USING btree (fecha_creacion DESC);
CREATE INDEX idx_reportes_tipo_hurto ON public.reportes USING btree (tipo_hurto);
CREATE INDEX idx_reportes_franja_horaria ON public.reportes USING btree (franja_horaria);
CREATE INDEX idx_reportes_comuna ON public.reportes USING btree (comuna);
CREATE INDEX idx_reportes_zona_id ON public.reportes USING btree (zona_id);
CREATE INDEX idx_reportes_incidente_id ON public.reportes USING btree (incidente_id);
CREATE INDEX idx_reportes_corregimiento ON public.reportes USING btree (corregimiento_id);
CREATE INDEX idx_reportes_latitud_longitud ON public.reportes USING btree (latitud, longitud);
CREATE INDEX idx_reportes_zona_tipo ON public.reportes USING btree (zona_tipo);
CREATE INDEX idx_reportes_actualizado_por ON public.reportes USING btree (actualizado_por) WHERE (actualizado_por IS NOT NULL);
CREATE INDEX idx_reportes_estado_fecha ON public.reportes USING btree (estado, fecha_incidente);
CREATE INDEX idx_reportes_estado_tipo_hurto ON public.reportes USING btree (estado, tipo_hurto);
CREATE INDEX idx_reportes_estado_zona ON public.reportes USING btree (estado, zona_id);
CREATE INDEX idx_reportes_estado_coords ON public.reportes USING btree (estado, latitud, longitud);
CREATE INDEX idx_reportes_estado_comuna_tipo ON public.reportes USING btree (estado, comuna, tipo_hurto);
CREATE INDEX idx_reportes_estado_fecha_zona ON public.reportes USING btree (estado, fecha_incidente, zona_id);
CREATE INDEX idx_reportes_estado_fecha_comuna ON public.reportes USING btree (estado, fecha_incidente, comuna);
CREATE INDEX idx_reportes_estado_fecha_export ON public.reportes USING btree (estado, fecha_incidente DESC);
CREATE INDEX idx_reportes_comuna_estado_fecha ON public.reportes USING btree (comuna, estado, fecha_incidente DESC);
CREATE INDEX idx_reportes_zona_estado_fecha ON public.reportes USING btree (zona_id, estado, fecha_incidente DESC);
CREATE INDEX idx_reportes_fecha_zona_tipo ON public.reportes USING btree (fecha_incidente, zona_id, tipo_hurto);

-- Incidentes
CREATE INDEX idx_incidentes_fecha ON public.incidentes USING btree (fecha_incidente);
CREATE INDEX idx_incidentes_tipo_hurto ON public.incidentes USING btree (tipo_hurto);
CREATE INDEX idx_incidentes_zona ON public.incidentes USING btree (zona_id);
CREATE INDEX idx_incidentes_comuna ON public.incidentes USING btree (comuna);
CREATE INDEX idx_incidentes_coords ON public.incidentes USING btree (latitud_centro, longitud_centro);

-- Alertas
CREATE INDEX idx_alertas_usuario_leida ON public.alertas USING btree (usuario_id, leida);
CREATE INDEX idx_alertas_reporte ON public.alertas USING btree (reporte_id);

-- Configuración alertas
CREATE INDEX idx_configuracion_alertas_usuario_id ON public.configuracion_alertas USING btree (usuario_id);

-- Password resets
CREATE INDEX idx_password_resets_token ON public.password_resets USING btree (token);
CREATE INDEX idx_password_resets_usuario ON public.password_resets USING btree (usuario_id);

-- Auditoría reportes
CREATE INDEX idx_auditoria_reportes_admin ON public.auditoria_reportes USING btree (admin_id, fecha DESC);
CREATE INDEX idx_auditoria_reportes_reporte ON public.auditoria_reportes USING btree (reporte_id, fecha DESC);
CREATE INDEX idx_auditoria_reportes_estado ON public.auditoria_reportes USING btree (accion, fecha DESC);

-- Auditoría edición reportes
CREATE INDEX idx_auditoria_edicion_admin ON public.auditoria_edicion_reportes USING btree (admin_id, fecha DESC);
CREATE INDEX idx_auditoria_edicion_reporte_id ON public.auditoria_edicion_reportes USING btree (reporte_id, fecha DESC);

-- Auditoría usuarios
CREATE INDEX idx_auditoria_usuarios_estado_fecha ON public.auditoria_usuarios USING btree (admin_id, fecha DESC);
CREATE INDEX idx_auditoria_usuarios_usuario ON public.auditoria_usuarios USING btree (usuario_id, fecha DESC);

-- Zonas riesgo
CREATE INDEX idx_zonas_riesgo_coords ON public.zonas_riesgo USING btree (latitud_centro, longitud_centro);
CREATE INDEX idx_zonas_riesgo_nivel ON public.zonas_riesgo USING btree (nivel_riesgo);
CREATE INDEX idx_zonas_riesgo_fecha ON public.zonas_riesgo USING btree (fecha_calculo DESC);
CREATE INDEX idx_zonas_riesgo_comuna ON public.zonas_riesgo USING btree (comuna) WHERE (comuna IS NOT NULL);
CREATE INDEX idx_zonas_riesgo_nivel_fecha ON public.zonas_riesgo USING btree (nivel_riesgo, fecha_calculo DESC);

-- Geoespaciales (GiST)
CREATE INDEX idx_secciones_geom ON public.secciones_dane USING gist (geom);
CREATE INDEX idx_zonas_geom ON public.zonas USING gist (geom);
CREATE INDEX idx_corregimientos_geom ON public.corregimientos USING gist (geom);
CREATE INDEX idx_veredas_corregimiento ON public.veredas USING btree (corregimiento_id);

-- Solicitudes eliminación
CREATE INDEX idx_solicitudes_estado ON public.solicitudes_eliminacion USING btree (estado_solicitud);
CREATE INDEX idx_solicitudes_reporte ON public.solicitudes_eliminacion USING btree (reporte_id);
CREATE INDEX idx_solicitudes_usuario ON public.solicitudes_eliminacion USING btree (usuario_id);
CREATE UNIQUE INDEX uniq_solicitud_pendiente_por_reporte ON public.solicitudes_eliminacion USING btree (reporte_id) WHERE ((estado_solicitud)::text = 'pendiente');

-- Aceptación términos
CREATE INDEX idx_aceptacion_usuario ON public.aceptacion_terminos USING btree (usuario_id);
CREATE INDEX idx_aceptacion_version ON public.aceptacion_terminos USING btree (version_terminos);

-- ============================================================
-- 5. FUNCIONES
-- ============================================================

-- Buscar barrio más similar por nombre (Levenshtein)
CREATE FUNCTION public.buscar_barrio_similar(texto_usuario text)
RETURNS TABLE(id integer, barrio character varying, comuna integer, similitud integer)
LANGUAGE sql AS $$
    SELECT z.id, z.barrio, z.comuna,
        levenshtein(unaccent(lower(z.barrio)), unaccent(lower(texto_usuario))) AS similitud
    FROM zonas z
    ORDER BY similitud ASC
    LIMIT 5;
$$;

-- Calcular nivel de riesgo según cantidad de reportes
CREATE FUNCTION public.calcular_nivel_riesgo(cantidad integer)
RETURNS character varying
LANGUAGE sql IMMUTABLE AS $$
    SELECT CASE
        WHEN cantidad <= 3  THEN 'seguro'
        WHEN cantidad <= 7  THEN 'medio'
        WHEN cantidad <= 10 THEN 'alto'
        ELSE 'peligroso'
    END;
$$;

-- Obtener zona y barrios por coordenadas geográficas
CREATE FUNCTION public.get_zona_por_coordenadas(lat double precision, lng double precision)
RETURNS TABLE(comuna integer, barrios text[])
LANGUAGE sql AS $$
    SELECT s.comuna,
        ARRAY_AGG(z.barrio ORDER BY z.barrio) AS barrios
    FROM public.secciones_dane s
    JOIN public.zonas z ON z.comuna = s.comuna
    WHERE ST_Contains(s.geom, ST_SetSRID(ST_MakePoint(lng, lat), 4326))
    GROUP BY s.comuna
    LIMIT 1;
$$;

-- Obtener corregimiento y veredas por coordenadas geográficas
CREATE FUNCTION public.get_corregimiento_por_coordenadas(lat double precision, lng double precision)
RETURNS TABLE(corregimiento_id integer, corregimiento text, veredas text[])
LANGUAGE sql AS $$
    SELECT c.id, c.nombre,
        ARRAY_AGG(v.nombre ORDER BY v.nombre) AS veredas
    FROM public.corregimientos c
    JOIN public.veredas v ON v.corregimiento_id = c.id
    WHERE ST_Contains(c.geom, ST_SetSRID(ST_MakePoint(lng, lat), 4326))
    GROUP BY c.id, c.nombre
    LIMIT 1;
$$;

-- Eliminar cuenta de usuario (soft delete + anonimización)
CREATE FUNCTION public.eliminar_cuenta_usuario(p_usuario_id uuid)
RETURNS void
LANGUAGE plpgsql AS $$
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

-- Asignar zona y comuna automáticamente al crear/actualizar reporte
CREATE FUNCTION public.asignar_zona_y_comuna()
RETURNS trigger
LANGUAGE plpgsql AS $$
DECLARE
    zona_encontrada INTEGER;
    comuna_encontrada INTEGER;
BEGIN
    -- Prioridad 1: por coordenadas geográficas
    IF NEW.latitud IS NOT NULL AND NEW.longitud IS NOT NULL THEN
        SELECT z.id, z.comuna INTO zona_encontrada, comuna_encontrada
        FROM public.secciones_dane s
        JOIN public.zonas z ON z.comuna = s.comuna
        WHERE ST_Contains(s.geom, ST_SetSRID(ST_MakePoint(NEW.longitud::float8, NEW.latitud::float8), 4326))
          AND unaccent(lower(z.barrio)) = unaccent(lower(NEW.barrio_ingresado))
        LIMIT 1;
    END IF;

    -- Prioridad 2: por nombre exacto (fallback)
    IF zona_encontrada IS NULL AND NEW.barrio_ingresado IS NOT NULL THEN
        SELECT z.id, z.comuna INTO zona_encontrada, comuna_encontrada
        FROM public.zonas z
        WHERE unaccent(lower(z.barrio)) = unaccent(lower(NEW.barrio_ingresado))
        LIMIT 1;
    END IF;

    NEW.zona_id := zona_encontrada;
    NEW.comuna  := comuna_encontrada;
    RETURN NEW;
END;
$$;

-- Asignar zona automática por similitud de nombre (fallback Levenshtein)
CREATE FUNCTION public.asignar_zona_automatica()
RETURNS trigger
LANGUAGE plpgsql AS $$
DECLARE
    zona_encontrada INTEGER;
BEGIN
    SELECT id INTO zona_encontrada
    FROM buscar_barrio_similar(NEW.barrio_ingresado)
    LIMIT 1;

    NEW.zona_id = zona_encontrada;
    RETURN NEW;
END;
$$;

-- Asignar o crear incidente agrupando reportes cercanos
CREATE FUNCTION public.asignar_o_crear_incidente()
RETURNS trigger
LANGUAGE plpgsql AS $$
DECLARE
    incidente_existente UUID;
    nuevo_incidente_id  UUID;
    RADIO_METROS        CONSTANT NUMERIC := 150;
BEGIN
    IF NEW.latitud IS NOT NULL AND NEW.longitud IS NOT NULL THEN
        SELECT i.id INTO incidente_existente
        FROM public.incidentes i
        WHERE i.tipo_hurto      = NEW.tipo_hurto
          AND i.fecha_incidente = NEW.fecha_incidente
          AND i.franja_horaria  = NEW.franja_horaria
          AND i.latitud_centro  IS NOT NULL
          AND (
              6371000 * acos(
                  LEAST(1.0,
                      cos(radians(i.latitud_centro::float8))
                      * cos(radians(NEW.latitud::float8))
                      * cos(radians(NEW.longitud::float8) - radians(i.longitud_centro::float8))
                      + sin(radians(i.latitud_centro::float8))
                      * sin(radians(NEW.latitud::float8))
                  )
              )
          ) <= RADIO_METROS
        ORDER BY i.fecha_creacion ASC
        LIMIT 1;
    END IF;

    IF incidente_existente IS NOT NULL THEN
        UPDATE public.incidentes i
        SET cantidad_reportes = i.cantidad_reportes + 1,
            latitud_centro  = (i.latitud_centro * i.cantidad_reportes + NEW.latitud) / (i.cantidad_reportes + 1),
            longitud_centro = (i.longitud_centro * i.cantidad_reportes + NEW.longitud) / (i.cantidad_reportes + 1),
            reporte_principal_id = CASE
                WHEN NEW.tipo_reportante = 'victima' THEN NEW.id
                ELSE i.reporte_principal_id
            END
        WHERE i.id = incidente_existente;
        nuevo_incidente_id := incidente_existente;
    ELSE
        INSERT INTO public.incidentes (
            reporte_principal_id, tipo_hurto, fecha_incidente,
            franja_horaria, latitud_centro, longitud_centro,
            zona_id, comuna, cantidad_reportes
        ) VALUES (
            NEW.id, NEW.tipo_hurto, NEW.fecha_incidente,
            NEW.franja_horaria, NEW.latitud, NEW.longitud,
            NEW.zona_id, NEW.comuna, 1
        )
        RETURNING id INTO nuevo_incidente_id;
    END IF;

    UPDATE public.reportes SET incidente_id = nuevo_incidente_id WHERE id = NEW.id;
    RETURN NEW;
END;
$$;

-- ============================================================
-- 6. TRIGGERS
-- ============================================================

CREATE TRIGGER trigger_asignar_zona_comuna
    BEFORE INSERT OR UPDATE ON public.reportes
    FOR EACH ROW
    EXECUTE FUNCTION public.asignar_zona_y_comuna();

CREATE TRIGGER trigger_asignar_zona
    BEFORE INSERT OR UPDATE ON public.reportes
    FOR EACH ROW
    WHEN (NEW.zona_id IS NULL)
    EXECUTE FUNCTION public.asignar_zona_automatica();

CREATE TRIGGER trigger_asignar_incidente
    AFTER INSERT ON public.reportes
    FOR EACH ROW
    EXECUTE FUNCTION public.asignar_o_crear_incidente();

-- ============================================================
-- 7. VISTAS
-- ============================================================

-- Conteo de reportes por estado
CREATE VIEW public.vw_conteo_estado_reportes AS
SELECT estado,
    count(*) AS total,
    count(DISTINCT usuario_id) AS usuarios_distintos,
    min(fecha_creacion) AS primer_reporte,
    max(fecha_creacion) AS ultimo_reporte
FROM public.reportes
GROUP BY estado;

-- Dashboard de incidentes
CREATE VIEW public.vw_dashboard_incidentes AS
SELECT i.id, i.tipo_hurto, i.fecha_incidente,
    (EXTRACT(year FROM i.fecha_incidente))::integer AS anio,
    (EXTRACT(month FROM i.fecha_incidente))::integer AS mes,
    to_char((i.fecha_incidente)::timestamp with time zone, 'TMMonth'::text) AS nombre_mes,
    i.franja_horaria,
    (i.comuna)::text AS comuna,
    z.barrio,
    i.cantidad_reportes,
    i.latitud_centro, i.longitud_centro,
    public.calcular_nivel_riesgo(i.cantidad_reportes) AS nivel_riesgo,
    (SELECT count(*) FROM public.reportes r2
     WHERE r2.incidente_id = i.id AND r2.tipo_reportante = 'victima' AND r2.estado = 'activo') AS victimas,
    (SELECT count(*) FROM public.reportes r3
     WHERE r3.incidente_id = i.id AND r3.tipo_reportante = 'testigo' AND r3.estado = 'activo') AS testigos,
    i.fecha_creacion
FROM public.incidentes i
LEFT JOIN public.zonas z ON i.zona_id = z.id
JOIN public.reportes r ON r.id = i.reporte_principal_id
WHERE r.estado = 'activo';

-- Estadísticas para admin
CREATE VIEW public.vw_estadisticas_admin AS
SELECT r.comuna, z.barrio, r.tipo_hurto, r.franja_horaria,
    r.estado AS estado_reporte,
    (date_trunc('month', r.fecha_incidente::timestamp with time zone))::date AS mes,
    count(*) AS total_reportes,
    count(DISTINCT r.incidente_id) AS total_incidentes,
    min(r.fecha_incidente) AS primer_incidente,
    max(r.fecha_incidente) AS ultimo_incidente
FROM public.reportes r
LEFT JOIN public.zonas z ON r.zona_id = z.id
GROUP BY r.comuna, z.barrio, r.tipo_hurto, r.franja_horaria, r.estado,
    date_trunc('month', r.fecha_incidente::timestamp with time zone)
ORDER BY count(*) DESC;

-- Estadísticas básicas
CREATE VIEW public.vw_estadisticas_basicas AS
WITH reportes_activos AS (
    SELECT id, fecha_incidente, franja_horaria, tipo_hurto, comuna, zona_id, fecha_creacion
    FROM public.reportes WHERE estado = 'activo'
), total AS (
    SELECT count(*) AS total_reportes FROM reportes_activos
), por_dia AS (
    SELECT fecha_incidente, count(*) AS cantidad FROM reportes_activos GROUP BY fecha_incidente
), por_franja AS (
    SELECT franja_horaria, count(*) AS cantidad FROM reportes_activos GROUP BY franja_horaria
)
SELECT t.total_reportes, pd.fecha_incidente, pd.cantidad AS reportes_dia,
    pf.franja_horaria, pf.cantidad AS reportes_franja
FROM total t CROSS JOIN por_dia pd CROSS JOIN por_franja pf;

-- Estadísticas por periodo semanal
CREATE VIEW public.vw_estadisticas_por_periodo AS
SELECT (date_trunc('week', fecha_incidente::timestamp with time zone))::date AS semana_inicio,
    count(*) AS total_reportes,
    count(DISTINCT fecha_incidente) AS dias_con_reportes,
    round(count(*)::numeric / NULLIF(count(DISTINCT fecha_incidente), 0)::numeric, 2) AS promedio_diario
FROM public.reportes
WHERE estado = 'activo'
GROUP BY date_trunc('week', fecha_incidente::timestamp with time zone)
ORDER BY semana_inicio DESC;

-- Exportación de reportes para admin
CREATE VIEW public.vw_export_reportes_admin AS
SELECT r.id AS reporte_id, r.fecha_incidente, r.franja_horaria, r.tipo_hurto,
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
LEFT JOIN public.zonas z ON r.zona_id = z.id
LEFT JOIN public.corregimientos c ON r.corregimiento_id = c.id
LEFT JOIN public.veredas v ON r.vereda_id = v.id
LEFT JOIN public.usuarios u_autor ON r.usuario_id = u_autor.id
LEFT JOIN public.usuarios u_admin ON r.actualizado_por = u_admin.id
ORDER BY r.fecha_incidente DESC, r.fecha_creacion DESC;

-- Tendencias por zona y tipo de hurto
CREATE VIEW public.vw_tendencias_zona_tipo AS
SELECT r.comuna, z.barrio, r.tipo_hurto,
    (date_trunc('week', r.fecha_incidente::timestamp with time zone))::date AS semana_inicio,
    count(*) AS total_reportes,
    count(DISTINCT r.incidente_id) AS total_incidentes
FROM public.reportes r
LEFT JOIN public.zonas z ON r.zona_id = z.id
WHERE r.estado = 'activo'
GROUP BY r.comuna, z.barrio, r.tipo_hurto, date_trunc('week', r.fecha_incidente::timestamp with time zone)
ORDER BY semana_inicio DESC, count(*) DESC;

-- Top barrios con más hurtos
CREATE VIEW public.vw_top_barrios_hurtos AS
SELECT i.comuna, z.barrio, i.zona_id,
    count(*) AS total_incidentes,
    sum(i.cantidad_reportes) AS total_reportes_vinculados,
    max(i.fecha_incidente) AS ultimo_incidente
FROM public.incidentes i
JOIN public.zonas z ON i.zona_id = z.id
JOIN public.reportes r ON r.id = i.reporte_principal_id
WHERE r.estado = 'activo' AND i.zona_id IS NOT NULL
GROUP BY i.comuna, z.barrio, i.zona_id
ORDER BY count(*) DESC;

-- Top zonas (comunas) con más hurtos
CREATE VIEW public.vw_top_zonas_hurtos AS
WITH conteo_comuna AS (
    SELECT i.comuna, count(*) AS total_incidentes,
        sum(i.cantidad_reportes) AS total_reportes_vinculados,
        max(i.fecha_incidente) AS ultimo_incidente
    FROM public.incidentes i
    JOIN public.reportes r ON r.id = i.reporte_principal_id
    WHERE r.estado = 'activo' AND i.comuna IS NOT NULL
    GROUP BY i.comuna
), tipo_frecuente AS (
    SELECT DISTINCT ON (i.comuna) i.comuna, i.tipo_hurto,
        count(*) AS cantidad_tipo
    FROM public.incidentes i
    JOIN public.reportes r ON r.id = i.reporte_principal_id
    WHERE r.estado = 'activo' AND i.comuna IS NOT NULL
    GROUP BY i.comuna, i.tipo_hurto
    ORDER BY i.comuna, count(*) DESC
)
SELECT cc.comuna, cc.total_incidentes, cc.total_reportes_vinculados,
    cc.ultimo_incidente, tf.tipo_hurto AS tipo_hurto_frecuente,
    tf.cantidad_tipo AS cantidad_tipo_frecuente
FROM conteo_comuna cc
LEFT JOIN tipo_frecuente tf ON cc.comuna = tf.comuna
ORDER BY cc.total_incidentes DESC;