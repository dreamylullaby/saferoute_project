-- BASE USADA EN SUPABASE.

CREATE EXTENSION IF NOT EXISTS "pgcrypto";

-- =========================================
-- TABLA DE USUARIOS
-- =========================================
CREATE TABLE usuarios (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    username VARCHAR(50) NOT NULL UNIQUE,
    correo VARCHAR(150) NOT NULL UNIQUE,
    password_hash TEXT,
    foto_url TEXT,
    rol VARCHAR(20) NOT NULL CHECK (rol IN ('usuario','admin')),
    auth_provider VARCHAR(20) NOT NULL CHECK (auth_provider IN ('local','google')),
    google_id VARCHAR(255) UNIQUE,
    fecha_creacion TIMESTAMP NOT NULL DEFAULT NOW(),
    estado VARCHAR(20) NOT NULL CHECK (estado IN ('activo','bloqueado'))
);

-- Datos de prueba: admin y usuario
INSERT INTO usuarios (username, correo, password_hash, rol, auth_provider, estado)
VALUES 
('admin_luna', 'adminluna@saferoute.com', '$2a$12$tOgExBIeBKhoSymKRpczzuTkwx0qbvCy6OO67a7u0V93f3.5hXDfq', 'admin', 'local', 'activo'),
('admin_lily', 'adminlily@saferoute.com', '$2a$12$g/zBlxujS51Dgyhbja8qyukslzG1rk.u.mDsgz5W.E4z0r1S.mVTm', 'admin', 'local', 'activo'),
('admin_sarah', 'adminsarah@saferoute.com', '$2a$12$i617M0GuFR8vv2voFu27R.0oCBr2QVBtRmvgEhYkrgPqZZ72uUR/2', 'admin', 'local', 'activo'),
('vigilante1', 'vigilar_1@gmail.com','$2a$12$tNG4rQF2sy5R6JJjdQdVouAwayAbjMojds3Ga25Uj8aeZVHPrYc/K','usuario', 'local', 'activo'),
('vigilante_seguro', 'vigilanteseguro@gmail.com', '$2a$12$4yo4aj4J7aIaF6w9L14A/uanMGuSN5wQxfWm09gs9RG8hhUZ3tfC6', 'usuario', 'local', 'activo');


-- =========================================
-- TABLA DE REPORTES
-- =========================================
CREATE TABLE reportes (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    
    -- Mantener que si se borra un usuario, el reporte pasa al admin
    usuario_id UUID NOT NULL DEFAULT '00000000-0000-0000-0000-000000000001',
    
    tipo_reportante VARCHAR(20) NOT NULL CHECK (tipo_reportante IN ('victima','testigo')),
    fecha_incidente DATE NOT NULL,
    franja_horaria VARCHAR(20) NOT NULL CHECK (
        franja_horaria IN (
            '00:00-05:59',
            '06:00-11:59',
            '12:00-17:59',
            '18:00-23:59'
        )
    ),
    latitud DECIMAL(9,6) NOT NULL,
    longitud DECIMAL(9,6) NOT NULL,
    direccion VARCHAR(100),
    comuna INTEGER CHECK (comuna BETWEEN 1 AND 12),
    tipo_hurto VARCHAR(30) NOT NULL CHECK (
        tipo_hurto IN ('atraco','raponazo','cosquilleo','fleteo')
    ),
    descripcion VARCHAR(300),
    objeto_hurtado VARCHAR(50) CHECK (
        objeto_hurtado IN (
            'celular',
            'dinero',
            'tarjetas_documentos',
            'articulos_personales',
            'dispositivos_electronicos'
        )
    ),
    numero_agresores VARCHAR(20) CHECK (
        numero_agresores IN ('1','2','3+','desconocido')
    ),
    fecha_creacion TIMESTAMP NOT NULL DEFAULT NOW(),
    fecha_actualizacion TIMESTAMP,
    actualizado_por UUID,
    estado VARCHAR(20) NOT NULL CHECK (
        estado IN ('activo','oculto','eliminado')
    ),
    
    CONSTRAINT fk_usuario FOREIGN KEY (usuario_id)
        REFERENCES usuarios(id)
        ON DELETE SET DEFAULT,
    
    CONSTRAINT fk_actualizado_por FOREIGN KEY (actualizado_por)
        REFERENCES usuarios(id)
        ON DELETE SET NULL
);

-- Insert de prueba en reportes
INSERT INTO reportes (
    usuario_id, tipo_reportante, fecha_incidente, franja_horaria,
    latitud, longitud, direccion, comuna, tipo_hurto, descripcion, objeto_hurtado, numero_agresores, estado
)
VALUES
(
    (SELECT id FROM usuarios WHERE username='vigilante1'),
    'victima',
    CURRENT_DATE,
    '12:00-17:59',
    1.234567,
    -76.543210,
    'Calle Falsa 123',
    5,
    'raponazo',
    'Me robaron el celular mientras caminaba',
    'celular',
    '1',
    'activo'
);

-- /////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

-- BASE PARA RDS (RDS)

CREATE EXTENSION IF NOT EXISTS "pgcrypto";

CREATE TABLE usuarios (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    username VARCHAR(50) NOT NULL UNIQUE,
    correo VARCHAR(150) NOT NULL UNIQUE,
    password_hash TEXT,
    foto_url TEXT,
    rol VARCHAR(20) NOT NULL CHECK (rol IN ('usuario','admin')),
    auth_provider VARCHAR(20) NOT NULL CHECK (auth_provider IN ('local','google')),
    google_id VARCHAR(255) UNIQUE,
    fecha_creacion TIMESTAMP NOT NULL DEFAULT NOW(),
    estado VARCHAR(20) NOT NULL CHECK (estado IN ('activo','bloqueado'))
);

INSERT INTO usuarios (id, username, correo, rol, auth_provider, fecha_creacion, estado)
VALUES (
'00000000-0000-0000-0000-000000000001',
'admin_sistema',
'admin@sistema.com',
'admin',
'local',
NOW(),
'activo'
);

CREATE TABLE reportes (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    usuario_id UUID NOT NULL DEFAULT '00000000-0000-0000-0000-000000000001',
    tipo_reportante VARCHAR(20) NOT NULL CHECK (tipo_reportante IN ('victima','testigo')),
    fecha_incidente DATE NOT NULL,
    franja_horaria VARCHAR(20) NOT NULL CHECK (franja_horaria IN ('00:00-05:59','06:00-11:59','12:00-17:59','18:00-23:59')),
    latitud DECIMAL(9,6) NOT NULL,
    longitud DECIMAL(9,6) NOT NULL,
    direccion VARCHAR(100),
    comuna INTEGER CHECK (comuna BETWEEN 1 AND 12),
    tipo_hurto VARCHAR(30) NOT NULL CHECK (tipo_hurto IN ('atraco','raponazo','cosquilleo','fleteo')),
    descripcion VARCHAR(300),
    objeto_hurtado VARCHAR(50) CHECK (objeto_hurtado IN ('celular','dinero','tarjetas_documentos','articulos_personales','dispositivos_electronicos')),
    numero_agresores VARCHAR(20) CHECK (numero_agresores IN ('1','2','3+','desconocido')),
    fecha_creacion TIMESTAMP NOT NULL DEFAULT NOW(),
    fecha_actualizacion TIMESTAMP,
    actualizado_por UUID,
    estado VARCHAR(20) NOT NULL CHECK (estado IN ('activo','oculto','eliminado')),

    CONSTRAINT fk_usuario FOREIGN KEY (usuario_id)
        REFERENCES usuarios(id)
        ON DELETE SET DEFAULT,

    CONSTRAINT fk_actualizado_por FOREIGN KEY (actualizado_por)
        REFERENCES usuarios(id)
        ON DELETE SET NULL
);


