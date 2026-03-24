-- 002_create_reportes.sql
-- Tabla de reportes
CREATE TABLE reportes (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    
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
    tipo_hurto VARCHAR(30) NOT NULL CHECK (tipo_hurto IN ('atraco','raponazo','cosquilleo','fleteo')),
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
    estado VARCHAR(20) NOT NULL CHECK (estado IN ('activo','oculto','eliminado')),
    
    CONSTRAINT fk_usuario FOREIGN KEY (usuario_id)
        REFERENCES usuarios(id)
        ON DELETE SET DEFAULT,
    
    CONSTRAINT fk_actualizado_por FOREIGN KEY (actualizado_por)
        REFERENCES usuarios(id)
        ON DELETE SET NULL
);

-- Insert de prueba
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