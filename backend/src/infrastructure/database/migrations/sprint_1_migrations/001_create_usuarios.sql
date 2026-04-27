-- ========================================
-- 001_create_usuarios.sql
-- Crea extensiones necesarias y la tabla de usuarios
-- ========================================

CREATE EXTENSION IF NOT EXISTS "pgcrypto";
CREATE EXTENSION IF NOT EXISTS unaccent;
CREATE EXTENSION IF NOT EXISTS fuzzystrmatch;

-- ========================================
-- TABLA USUARIOS
-- ========================================
CREATE TABLE IF NOT EXISTS public.usuarios (
    id              UUID        PRIMARY KEY DEFAULT gen_random_uuid(),
    username        VARCHAR(50) NOT NULL UNIQUE,
    correo          VARCHAR(150) NOT NULL UNIQUE,
    password_hash   TEXT,
    foto_url        TEXT,
    rol             VARCHAR(20) NOT NULL CHECK (rol IN ('usuario', 'admin')),
    auth_provider   VARCHAR(20) NOT NULL CHECK (auth_provider IN ('local', 'google')),
    google_id       VARCHAR(255) UNIQUE,
    fecha_creacion  TIMESTAMP   NOT NULL DEFAULT now(),
    estado          VARCHAR(20) NOT NULL CHECK (estado IN ('activo', 'bloqueado', 'eliminado')),
    fcm_token       TEXT
);
