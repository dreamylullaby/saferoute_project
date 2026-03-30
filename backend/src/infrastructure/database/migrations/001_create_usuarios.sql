-- ========================================
-- 001_create_usuarios.sql
-- Crea extensiones necesarias y la tabla de usuarios
-- ========================================

-- Para UUID
CREATE EXTENSION IF NOT EXISTS "pgcrypto";

-- Para búsquedas sin acentos (backend fuzzy search)
CREATE EXTENSION IF NOT EXISTS unaccent;

-- Para distancia entre palabras (Levenshtein)
CREATE EXTENSION IF NOT EXISTS fuzzystrmatch;

-- ========================================
-- TABLA USUARIOS
-- ========================================
CREATE TABLE IF NOT EXISTS public.usuarios (
    id              uuid        PRIMARY KEY DEFAULT gen_random_uuid(),
    username        VARCHAR     NOT NULL UNIQUE,
    correo          VARCHAR     NOT NULL UNIQUE,
    password_hash   TEXT,
    foto_url        TEXT,
    rol             VARCHAR     NOT NULL CHECK (rol IN ('usuario', 'admin')),
    auth_provider   VARCHAR     NOT NULL CHECK (auth_provider IN ('local', 'google')),
    google_id       VARCHAR     UNIQUE,
    fecha_creacion  TIMESTAMP   NOT NULL DEFAULT now(),
    estado          VARCHAR     NOT NULL CHECK (estado IN ('activo', 'bloqueado'))
);

-- Datos de prueba
INSERT INTO public.usuarios (username, correo, password_hash, rol, auth_provider, estado)
VALUES
    ('admin_luna',        'adminluna@saferoute.com',        '$2a$12$tOgExBIeBKhoSymKRpczzuTkwx0qbvCy6OO67a7u0V93f3.5hXDfq', 'admin',   'local', 'activo'),
    ('admin_lily',        'adminlily@saferoute.com',        '$2a$12$g/zBlxujS51Dgyhbja8qyukslzG1rk.u.mDsgz5W.E4z0r1S.mVTm', 'admin',   'local', 'activo'),
    ('admin_sarah',       'adminsarah@saferoute.com',       '$2a$12$i617M0GuFR8vv2voFu27R.0oCBr2QVBtRmvgEhYkrgPqZZ72uUR/2', 'admin',   'local', 'activo'),
    ('vigilante1',        'vigilar_1@gmail.com',            '$2a$12$tNG4rQF2sy5R6JJjdQdVouAwayAbjMojds3Ga25Uj8aeZVHPrYc/K', 'usuario', 'local', 'activo'),
    ('vigilante_seguro',  'vigilanteseguro@gmail.com',      '$2a$12$4yo4aj4J7aIaF6w9L14A/uanMGuSN5wQxfWm09gs9RG8hhUZ3tfC6', 'usuario', 'local', 'activo');
