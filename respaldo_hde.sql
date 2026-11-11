
-- ================================================================
-- SISTEMA INTEGRAL DE GESTIÓN HOSPITALARIA VETERINARIA
-- HOSPITAL DE EQUINOS
-- FES CUAUTITLÁN | UNAM
-- MOTOR: PostgreSQL
-- ================================================================

-- Si todavía no existe la base de datos, ejecutar primero:
-- CREATE DATABASE hospital_equinos;
-- Después conectarse a hospital_equinos y ejecutar este archivo.

BEGIN;

CREATE EXTENSION IF NOT EXISTS pgcrypto;

-- ================================================================
-- 1. ROLES Y USUARIOS
-- ================================================================

CREATE TABLE roles (
    id_rol BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    nombre VARCHAR(100) NOT NULL UNIQUE,
    descripcion TEXT,
    activo BOOLEAN NOT NULL DEFAULT TRUE
);

CREATE TABLE usuarios (
    id_usuario BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    id_rol BIGINT NOT NULL REFERENCES roles(id_rol),
    nombre VARCHAR(120) NOT NULL,
    apellido VARCHAR(120) NOT NULL,
    correo VARCHAR(150) NOT NULL UNIQUE,
    telefono VARCHAR(30),
    password_hash TEXT NOT NULL,
    cedula_profesional VARCHAR(40),
    especialidad VARCHAR(120),
    horario TEXT,
    activo BOOLEAN NOT NULL DEFAULT TRUE,
    fecha_registro TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- ================================================================
-- 2. PROPIETARIOS
-- ================================================================

CREATE TABLE propietarios (
    id_propietario BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    folio VARCHAR(30) UNIQUE,
    nombre VARCHAR(150) NOT NULL,
    apellido VARCHAR(150),
    identificacion VARCHAR(60),
    telefono VARCHAR(30),
    correo VARCHAR(150),
    domicilio TEXT,
    municipio VARCHAR(100),
    estado VARCHAR(100),
    observaciones TEXT,
    activo BOOLEAN NOT NULL DEFAULT TRUE,
    fecha_registro TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- ================================================================
-- 3. PACIENTES EQUINOS
-- ================================================================

CREATE TABLE pacientes (
    id_paciente BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    folio VARCHAR(30) UNIQUE,
    id_propietario BIGINT NOT NULL REFERENCES propietarios(id_propietario),

    nombre VARCHAR(120) NOT NULL,
    especie VARCHAR(30) NOT NULL DEFAULT 'Caballo'
        CHECK (especie IN ('Caballo','Yegua','Burro','Mula','Otro')),
    raza VARCHAR(100),
    sexo VARCHAR(20) NOT NULL
        CHECK (sexo IN ('Macho','Hembra','Castrado','Desconocido')),

    fecha_nacimiento DATE,
    color VARCHAR(80),
    señas_particulares TEXT,
    numero_identificacion VARCHAR(100),
    microchip VARCHAR(100) UNIQUE,

    peso NUMERIC(8,2) CHECK (peso IS NULL OR peso BETWEEN 0 AND 1500),
    altura NUMERIC(6,2) CHECK (altura IS NULL OR altura BETWEEN 0 AND 250),

    uso VARCHAR(100),
    disciplina VARCHAR(100),
    alergias TEXT,
    antecedentes TEXT,
    vacunas TEXT,
    desparasitaciones TEXT,

    estado VARCHAR(30) NOT NULL DEFAULT 'Activo'
        CHECK (estado IN ('Activo','Hospitalizado','Alta','Fallecido','Inactivo')),

    fecha_registro TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX pacientes_propietario_idx
ON pacientes(id_propietario);

CREATE INDEX pacientes_nombre_idx
ON pacientes(nombre);

CREATE INDEX pacientes_especie_idx
ON pacientes(especie);

-- ================================================================
-- 4. ÁREAS HOSPITALARIAS
-- ================================================================

CREATE TABLE areas (
    id_area BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    nombre VARCHAR(100) NOT NULL UNIQUE,
    descripcion TEXT,
    id_responsable BIGINT REFERENCES usuarios(id_usuario),
    ubicacion VARCHAR(120),
    activa BOOLEAN NOT NULL DEFAULT TRUE
);

-- ================================================================
-- 5. ADMISIÓN Y HOSPITALIZACIÓN
-- ================================================================

CREATE TABLE admisiones (
    id_admision BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    folio VARCHAR(30) UNIQUE,
    id_paciente BIGINT NOT NULL REFERENCES pacientes(id_paciente),
    id_area BIGINT NOT NULL REFERENCES areas(id_area),
    id_medico BIGINT REFERENCES usuarios(id_usuario),

    tipo_ingreso VARCHAR(60) NOT NULL,
    motivo TEXT NOT NULL,
    diagnostico_ingreso TEXT,
    box VARCHAR(40),

    estado VARCHAR(30) NOT NULL DEFAULT 'Registrado'
        CHECK (estado IN ('Registrado','Hospitalizado','En observación','Finalizado','Cancelado')),

    fecha_ingreso TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    fecha_salida TIMESTAMPTZ,

    observaciones TEXT,

    creado_por BIGINT REFERENCES usuarios(id_usuario),

    CHECK (fecha_salida IS NULL OR fecha_salida >= fecha_ingreso)
);

CREATE INDEX admisiones_paciente_idx
ON admisiones(id_paciente);

CREATE UNIQUE INDEX admisiones_box_activo_idx
ON admisiones(box)
WHERE box IS NOT NULL
AND estado IN ('Registrado','Hospitalizado','En observación');

-- ================================================================
-- 6. CONSULTAS Y EXPEDIENTE CLÍNICO
-- ================================================================

CREATE TABLE consultas (
    id_consulta BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    folio VARCHAR(30) UNIQUE,

    id_paciente BIGINT NOT NULL REFERENCES pacientes(id_paciente),
    id_admision BIGINT REFERENCES admisiones(id_admision),
    id_medico BIGINT NOT NULL REFERENCES usuarios(id_usuario),
    id_area BIGINT REFERENCES areas(id_area),

    tipo_registro VARCHAR(50) NOT NULL DEFAULT 'Consulta',
    motivo TEXT NOT NULL,
    sintomas TEXT,
    exploracion_fisica TEXT,
    diagnostico TEXT,
    diagnostico_diferencial TEXT,
    tratamiento TEXT,
    plan TEXT,
    pronostico VARCHAR(80),
    indicaciones TEXT,

    claudicacion SMALLINT CHECK (claudicacion BETWEEN 0 AND 5),
    condicion_corporal SMALLINT CHECK (condicion_corporal BETWEEN 1 AND 9),

    estado VARCHAR(30) NOT NULL DEFAULT 'Abierta'
        CHECK (estado IN ('Abierta','En seguimiento','Cerrada','Cancelada')),

    validacion VARCHAR(40) NOT NULL DEFAULT 'Pendiente'
        CHECK (validacion IN ('Pendiente','Validado','Enmendado','Devuelto','No aplica')),

    validado_por BIGINT REFERENCES usuarios(id_usuario),
    validado_en TIMESTAMPTZ,

    fecha_consulta TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    creado_por BIGINT REFERENCES usuarios(id_usuario)
);

CREATE INDEX consultas_paciente_idx
ON consultas(id_paciente, fecha_consulta DESC);

CREATE INDEX consultas_medico_idx
ON consultas(id_medico);

-- ================================================================
-- 7. SIGNOS VITALES
-- ================================================================

CREATE TABLE signos_vitales (
    id_signo BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    id_consulta BIGINT NOT NULL REFERENCES consultas(id_consulta) ON DELETE CASCADE,

    temperatura NUMERIC(4,1)
        CHECK (temperatura IS NULL OR temperatura BETWEEN 30 AND 45),

    frecuencia_cardiaca SMALLINT
        CHECK (frecuencia_cardiaca IS NULL OR frecuencia_cardiaca BETWEEN 0 AND 250),

    frecuencia_respiratoria SMALLINT
        CHECK (frecuencia_respiratoria IS NULL OR frecuencia_respiratoria BETWEEN 0 AND 150),

    peso NUMERIC(8,2)
        CHECK (peso IS NULL OR peso BETWEEN 0 AND 1500),

    mucosas VARCHAR(100),
    tiempo_llenado_capilar VARCHAR(50),
    motilidad_intestinal VARCHAR(100),
    hidratacion VARCHAR(100),
    dolor SMALLINT CHECK (dolor BETWEEN 0 AND 10),
    condicion_corporal SMALLINT CHECK (condicion_corporal BETWEEN 1 AND 9),

    observaciones TEXT,
    fecha_registro TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX signos_consulta_idx
ON signos_vitales(id_consulta);

-- ================================================================
-- 8. TRIAGE
-- ================================================================

CREATE TABLE triage (
    id_triage BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    folio VARCHAR(30) UNIQUE,
    id_paciente BIGINT NOT NULL REFERENCES pacientes(id_paciente),
    id_admision BIGINT REFERENCES admisiones(id_admision),
    id_area_destino BIGINT NOT NULL REFERENCES areas(id_area),
    id_responsable BIGINT REFERENCES usuarios(id_usuario),

    motivo TEXT NOT NULL,
    estado_general TEXT,
    prioridad VARCHAR(30) NOT NULL
        CHECK (prioridad IN ('Emergencia','Urgente','Prioritario','Estable')),

    dolor SMALLINT CHECK (dolor BETWEEN 0 AND 10),
    observaciones TEXT,

    fecha_registro TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- ================================================================
-- 9. INTERCONSULTAS
-- ================================================================

CREATE TABLE interconsultas (
    id_interconsulta BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    folio VARCHAR(30) UNIQUE,
    id_paciente BIGINT NOT NULL REFERENCES pacientes(id_paciente),
    id_area_origen BIGINT REFERENCES areas(id_area),
    id_area_destino BIGINT NOT NULL REFERENCES areas(id_area),
    id_especialista BIGINT REFERENCES usuarios(id_usuario),

    motivo TEXT NOT NULL,
    observaciones TEXT,
    respuesta TEXT,

    estado VARCHAR(30) NOT NULL DEFAULT 'Solicitada'
        CHECK (estado IN ('Solicitada','Aceptada','En proceso','Respondida','Cancelada')),

    fecha_registro TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- ================================================================
-- 10. LABORATORIO
-- ================================================================

CREATE TABLE estudios_laboratorio (
    id_estudio_lab BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    folio VARCHAR(30) UNIQUE,

    id_paciente BIGINT NOT NULL REFERENCES pacientes(id_paciente),
    id_consulta BIGINT REFERENCES consultas(id_consulta),
    id_solicitante BIGINT REFERENCES usuarios(id_usuario),
    id_responsable BIGINT REFERENCES usuarios(id_usuario),

    tipo_estudio VARCHAR(120) NOT NULL,
    tipo_muestra VARCHAR(100),
    fecha_toma TIMESTAMPTZ,
    fecha_procesamiento TIMESTAMPTZ,

    resultado TEXT,
    observaciones TEXT,

    estado VARCHAR(40) NOT NULL DEFAULT 'Solicitado'
        CHECK (estado IN ('Solicitado','En proceso','Resultado disponible','Validado','Cancelado')),

    fecha_registro TIMESTAMPTZ NOT NULL DEFAULT NOW(),

    CHECK (fecha_procesamiento IS NULL OR fecha_toma IS NULL OR fecha_procesamiento >= fecha_toma)
);

CREATE INDEX laboratorio_paciente_idx
ON estudios_laboratorio(id_paciente);

-- ================================================================
-- 11. IMAGENOLOGÍA
-- ================================================================

CREATE TABLE estudios_imagen (
    id_estudio_img BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    folio VARCHAR(30) UNIQUE,

    id_paciente BIGINT NOT NULL REFERENCES pacientes(id_paciente),
    id_consulta BIGINT REFERENCES consultas(id_consulta),
    id_solicitante BIGINT REFERENCES usuarios(id_usuario),
    id_interpreta BIGINT REFERENCES usuarios(id_usuario),

    tipo_estudio VARCHAR(100) NOT NULL,
    motivo TEXT NOT NULL,
    fecha_estudio TIMESTAMPTZ,
    informe TEXT,
    ruta_archivo TEXT,

    estado VARCHAR(40) NOT NULL DEFAULT 'Solicitado'
        CHECK (estado IN ('Solicitado','Programado','Realizado','Interpretado','Cancelado')),

    fecha_registro TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- ================================================================
-- 12. CIRUGÍAS
-- ================================================================

CREATE TABLE cirugias (
    id_cirugia BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    folio VARCHAR(30) UNIQUE,

    id_paciente BIGINT NOT NULL REFERENCES pacientes(id_paciente),
    id_consulta BIGINT REFERENCES consultas(id_consulta),
    id_cirujano BIGINT REFERENCES usuarios(id_usuario),
    id_anestesiologo BIGINT REFERENCES usuarios(id_usuario),
    id_area BIGINT REFERENCES areas(id_area),

    tipo_cirugia VARCHAR(150) NOT NULL,
    diagnostico TEXT,

    evaluacion_preoperatoria TEXT,
    evaluacion_anestesica TEXT,
    protocolo_anestesico TEXT,
    procedimiento TEXT,
    transoperatorio TEXT,
    incidentes TEXT,
    recuperacion TEXT,
    indicaciones_postoperatorias TEXT,

    autorizacion_registrada BOOLEAN NOT NULL DEFAULT FALSE,
    verificacion_preoperatoria BOOLEAN NOT NULL DEFAULT FALSE,

    fecha_programada TIMESTAMPTZ,
    fecha_finalizacion TIMESTAMPTZ,

    estado VARCHAR(40) NOT NULL DEFAULT 'Programada'
        CHECK (estado IN ('Programada','En preparación','En quirófano','En recuperación','Finalizada','Cancelada')),

    CHECK (
        estado NOT IN ('En quirófano','En recuperación','Finalizada')
        OR (autorizacion_registrada AND verificacion_preoperatoria)
    )
);

-- ================================================================
-- 13. PROVEEDORES Y FARMACIA
-- ================================================================

CREATE TABLE proveedores (
    id_proveedor BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    nombre VARCHAR(150) NOT NULL,
    contacto VARCHAR(120),
    telefono VARCHAR(30),
    correo VARCHAR(150),
    domicilio TEXT,
    activo BOOLEAN NOT NULL DEFAULT TRUE
);

CREATE TABLE medicamentos_lotes (
    id_lote BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    folio VARCHAR(30) UNIQUE,

    id_proveedor BIGINT REFERENCES proveedores(id_proveedor),

    principio_activo VARCHAR(150) NOT NULL,
    nombre_comercial VARCHAR(150),
    concentracion VARCHAR(80),
    presentacion VARCHAR(100),
    unidad_medida VARCHAR(30) NOT NULL DEFAULT 'Unidad',

    lote VARCHAR(80) NOT NULL,
    caducidad DATE NOT NULL,

    existencia_inicial INTEGER NOT NULL DEFAULT 0
        CHECK (existencia_inicial >= 0),

    fecha_registro TIMESTAMPTZ NOT NULL DEFAULT NOW(),

    UNIQUE (principio_activo, concentracion, lote)
);

CREATE INDEX medicamentos_caducidad_idx
ON medicamentos_lotes(caducidad);

CREATE TABLE movimientos_farmacia (
    id_movimiento BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    folio VARCHAR(30) UNIQUE,

    id_lote BIGINT NOT NULL REFERENCES medicamentos_lotes(id_lote),

    tipo VARCHAR(20) NOT NULL
        CHECK (tipo IN ('Entrada','Salida','Ajuste')),

    cantidad INTEGER NOT NULL CHECK (cantidad > 0),
    documento VARCHAR(120),
    motivo TEXT,

    fecha_registro TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    creado_por BIGINT REFERENCES usuarios(id_usuario)
);

-- ================================================================
-- 14. RECETAS Y DISPENSACIONES
-- ================================================================

CREATE TABLE recetas (
    id_receta BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    folio VARCHAR(30) UNIQUE,

    id_consulta BIGINT NOT NULL REFERENCES consultas(id_consulta),
    id_medico BIGINT NOT NULL REFERENCES usuarios(id_usuario),

    fecha_emision TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    indicaciones TEXT,
    estado VARCHAR(30) NOT NULL DEFAULT 'Pendiente'
        CHECK (estado IN ('Pendiente','Validada','Surtida','Cancelada'))
);

CREATE TABLE receta_detalle (
    id_detalle BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    id_receta BIGINT NOT NULL REFERENCES recetas(id_receta) ON DELETE CASCADE,
    id_lote BIGINT REFERENCES medicamentos_lotes(id_lote),

    medicamento VARCHAR(150) NOT NULL,
    dosis VARCHAR(100) NOT NULL,
    via_administracion VARCHAR(80),
    frecuencia VARCHAR(100),
    duracion VARCHAR(100),
    cantidad INTEGER NOT NULL CHECK (cantidad > 0),
    indicaciones TEXT
);

CREATE TABLE dispensaciones (
    id_dispensacion BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    folio VARCHAR(30) UNIQUE,

    id_receta BIGINT NOT NULL REFERENCES recetas(id_receta),
    id_detalle BIGINT NOT NULL REFERENCES receta_detalle(id_detalle),
    id_lote BIGINT NOT NULL REFERENCES medicamentos_lotes(id_lote),

    cantidad INTEGER NOT NULL CHECK (cantidad > 0),

    resultado VARCHAR(40) NOT NULL
        CHECK (resultado IN ('Entregado al propietario','Administrado en el hospital','No entregado')),

    observaciones TEXT,
    fecha_registro TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    creado_por BIGINT REFERENCES usuarios(id_usuario)
);

-- ================================================================
-- 15. FINANZAS
-- ================================================================

CREATE TABLE tarifas (
    id_tarifa BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    categoria VARCHAR(80) NOT NULL,
    concepto VARCHAR(150) NOT NULL,
    precio NUMERIC(12,2) NOT NULL CHECK (precio >= 0),
    vigente BOOLEAN NOT NULL DEFAULT TRUE,
    UNIQUE (categoria, concepto)
);

CREATE TABLE cargos (
    id_cargo BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    folio VARCHAR(30) UNIQUE,

    id_propietario BIGINT NOT NULL REFERENCES propietarios(id_propietario),
    id_paciente BIGINT REFERENCES pacientes(id_paciente),
    id_tarifa BIGINT REFERENCES tarifas(id_tarifa),

    concepto VARCHAR(150) NOT NULL,
    cantidad INTEGER NOT NULL CHECK (cantidad > 0),
    precio_unitario NUMERIC(12,2) NOT NULL CHECK (precio_unitario >= 0),

    estado VARCHAR(20) NOT NULL DEFAULT 'Vigente'
        CHECK (estado IN ('Vigente','Cancelado')),

    motivo_cancelacion TEXT,
    fecha_registro TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    creado_por BIGINT REFERENCES usuarios(id_usuario),

    CHECK (estado <> 'Cancelado' OR motivo_cancelacion IS NOT NULL)
);

CREATE TABLE abonos (
    id_abono BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    folio VARCHAR(30) UNIQUE,

    id_propietario BIGINT NOT NULL REFERENCES propietarios(id_propietario),

    monto NUMERIC(12,2) NOT NULL CHECK (monto > 0),
    metodo VARCHAR(40) NOT NULL,
    referencia VARCHAR(120),

    estado VARCHAR(20) NOT NULL DEFAULT 'Vigente'
        CHECK (estado IN ('Vigente','Cancelado')),

    motivo_cancelacion TEXT,
    fecha_registro TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    creado_por BIGINT REFERENCES usuarios(id_usuario),

    CHECK (estado <> 'Cancelado' OR motivo_cancelacion IS NOT NULL)
);

CREATE INDEX cargos_propietario_idx
ON cargos(id_propietario);

CREATE INDEX abonos_propietario_idx
ON abonos(id_propietario);

-- ================================================================
-- 16. CONTROL ACADÉMICO
-- ================================================================

CREATE TABLE actividades_academicas (
    id_actividad BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    folio VARCHAR(30) UNIQUE,

    id_estudiante BIGINT REFERENCES usuarios(id_usuario),
    id_supervisor BIGINT REFERENCES usuarios(id_usuario),
    id_area BIGINT REFERENCES areas(id_area),

    nombre_estudiante VARCHAR(150) NOT NULL,
    matricula VARCHAR(40),
    carrera VARCHAR(120),
    modalidad VARCHAR(80) NOT NULL,

    fecha DATE NOT NULL,
    hora_inicio TIME,
    hora_fin TIME,

    actividades TEXT NOT NULL,
    observaciones TEXT,

    estado VARCHAR(30) NOT NULL DEFAULT 'Pendiente'
        CHECK (estado IN ('Pendiente','En revisión','Aprobada','Rechazada')),

    CHECK (hora_fin IS NULL OR hora_inicio IS NULL OR hora_fin >= hora_inicio)
);

CREATE TABLE actividad_casos (
    id_actividad BIGINT NOT NULL REFERENCES actividades_academicas(id_actividad) ON DELETE CASCADE,
    id_paciente BIGINT NOT NULL REFERENCES pacientes(id_paciente),
    PRIMARY KEY (id_actividad,id_paciente)
);

-- ================================================================
-- 17. ARCHIVOS Y DOCUMENTACIÓN
-- ================================================================

CREATE TABLE archivos (
    id_archivo BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,

    tabla_origen VARCHAR(60) NOT NULL,
    id_registro BIGINT NOT NULL,

    nombre VARCHAR(255) NOT NULL,
    tipo_mime VARCHAR(120),
    tamanio BIGINT CHECK (tamanio IS NULL OR tamanio >= 0),
    hash_sha256 CHAR(64),

    contenido BYTEA,
    ruta TEXT,

    fecha_registro TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    creado_por BIGINT REFERENCES usuarios(id_usuario),

    CHECK (contenido IS NOT NULL OR ruta IS NOT NULL)
);

CREATE INDEX archivos_origen_idx
ON archivos(tabla_origen,id_registro);

-- ================================================================
-- 18. AUDITORÍA
-- ================================================================

CREATE TABLE bitacora (
    id_bitacora BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    fecha TIMESTAMPTZ NOT NULL DEFAULT NOW(),

    id_usuario BIGINT REFERENCES usuarios(id_usuario),
    tabla VARCHAR(80) NOT NULL,
    id_registro BIGINT,

    accion VARCHAR(30) NOT NULL,
    detalle JSONB
);

CREATE TABLE versiones_registro (
    id_version BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,

    tabla VARCHAR(80) NOT NULL,
    id_registro BIGINT NOT NULL,

    fecha TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    id_usuario BIGINT REFERENCES usuarios(id_usuario),

    operacion VARCHAR(20) NOT NULL,
    datos_anteriores JSONB,
    datos_nuevos JSONB
);

CREATE INDEX bitacora_fecha_idx
ON bitacora(fecha DESC);

CREATE INDEX bitacora_registro_idx
ON bitacora(tabla,id_registro);

CREATE INDEX versiones_registro_idx
ON versiones_registro(tabla,id_registro,fecha DESC);

-- ================================================================
-- 19. GENERACIÓN AUTOMÁTICA DE FOLIOS
-- ================================================================

CREATE TABLE folio_contador (
    prefijo VARCHAR(5) NOT NULL,
    anio INTEGER NOT NULL,
    ultimo INTEGER NOT NULL DEFAULT 0,
    PRIMARY KEY(prefijo,anio)
);

CREATE OR REPLACE FUNCTION siguiente_folio(p_prefijo TEXT)
RETURNS TEXT
LANGUAGE plpgsql
AS $$
DECLARE
    v_anio INTEGER := EXTRACT(YEAR FROM CURRENT_DATE)::INTEGER;
    v_numero INTEGER;
BEGIN
    INSERT INTO folio_contador(prefijo,anio,ultimo)
    VALUES(p_prefijo,v_anio,1)
    ON CONFLICT(prefijo,anio)
    DO UPDATE SET ultimo = folio_contador.ultimo + 1
    RETURNING ultimo INTO v_numero;

    RETURN p_prefijo || '-' || v_anio || '-' ||
           LPAD(v_numero::TEXT,5,'0');
END;
$$;

CREATE OR REPLACE FUNCTION asignar_folio()
RETURNS TRIGGER
LANGUAGE plpgsql
AS $$
BEGIN
    IF NEW.folio IS NULL OR NEW.folio = '' THEN
        NEW.folio := siguiente_folio(TG_ARGV[0]);
    END IF;
    RETURN NEW;
END;
$$;

DO $$
DECLARE
    r RECORD;
BEGIN
    FOR r IN
        SELECT * FROM (VALUES
            ('propietarios','PRP'),
            ('pacientes','PAC'),
            ('admisiones','ADM'),
            ('consultas','CON'),
            ('triage','TRI'),
            ('interconsultas','INT'),
            ('estudios_laboratorio','LAB'),
            ('estudios_imagen','IMG'),
            ('cirugias','CIR'),
            ('medicamentos_lotes','MED'),
            ('movimientos_farmacia','MOV'),
            ('recetas','REC'),
            ('dispensaciones','DIS'),
            ('cargos','CAR'),
            ('abonos','ABO'),
            ('actividades_academicas','ACA')
        ) AS x(tabla,prefijo)
    LOOP
        EXECUTE FORMAT(
            'CREATE TRIGGER asignar_folio
             BEFORE INSERT ON %I
             FOR EACH ROW EXECUTE FUNCTION asignar_folio(%L)',
            r.tabla,r.prefijo
        );
    END LOOP;
END;
$$;

-- ================================================================
-- 20. CONTROL DE EXISTENCIAS
-- ================================================================

CREATE OR REPLACE FUNCTION stock_lote(p_id_lote BIGINT)
RETURNS BIGINT
LANGUAGE SQL
STABLE
AS $$
    SELECT
        m.existencia_inicial +
        COALESCE(
            SUM(
                CASE
                    WHEN v.tipo = 'Entrada' THEN v.cantidad
                    WHEN v.tipo = 'Salida' THEN -v.cantidad
                    WHEN v.tipo = 'Ajuste' THEN v.cantidad
                    ELSE 0
                END
            ),0
        ) -
        COALESCE((
            SELECT SUM(d.cantidad)
            FROM dispensaciones d
            WHERE d.id_lote = m.id_lote
              AND d.resultado <> 'No entregado'
        ),0)
    FROM medicamentos_lotes m
    LEFT JOIN movimientos_farmacia v ON v.id_lote = m.id_lote
    WHERE m.id_lote = p_id_lote
    GROUP BY m.id_lote,m.existencia_inicial;
$$;

CREATE OR REPLACE FUNCTION validar_stock_movimiento()
RETURNS TRIGGER
LANGUAGE plpgsql
AS $$
DECLARE
    v_disponible BIGINT;
BEGIN
    PERFORM 1
    FROM medicamentos_lotes
    WHERE id_lote = NEW.id_lote
    FOR UPDATE;

    IF NOT FOUND THEN
        RAISE EXCEPTION 'El lote indicado no existe';
    END IF;

    IF NEW.tipo IN ('Salida','Ajuste') AND NEW.cantidad > 0 THEN
        v_disponible := stock_lote(NEW.id_lote);

        IF TG_OP = 'UPDATE' AND OLD.id_lote = NEW.id_lote THEN
            IF OLD.tipo = 'Salida' THEN
                v_disponible := v_disponible + OLD.cantidad;
            ELSIF OLD.tipo = 'Entrada' THEN
                v_disponible := v_disponible - OLD.cantidad;
            ELSIF OLD.tipo = 'Ajuste' THEN
                v_disponible := v_disponible + OLD.cantidad;
            END IF;
        END IF;

        IF NEW.tipo = 'Salida' AND NEW.cantidad > v_disponible THEN
            RAISE EXCEPTION 'Existencia insuficiente. Disponible: %',v_disponible;
        END IF;
    END IF;

    RETURN NEW;
END;
$$;

CREATE TRIGGER validar_stock_movimiento_trg
BEFORE INSERT OR UPDATE ON movimientos_farmacia
FOR EACH ROW EXECUTE FUNCTION validar_stock_movimiento();

CREATE OR REPLACE FUNCTION validar_stock_dispensacion()
RETURNS TRIGGER
LANGUAGE plpgsql
AS $$
DECLARE
    v_disponible BIGINT;
BEGIN
    PERFORM 1
    FROM medicamentos_lotes
    WHERE id_lote = NEW.id_lote
    FOR UPDATE;

    IF NOT FOUND THEN
        RAISE EXCEPTION 'El lote indicado no existe';
    END IF;

    IF NOT EXISTS (
        SELECT 1
        FROM recetas r
        WHERE r.id_receta = NEW.id_receta
          AND r.estado = 'Validada'
    ) THEN
        RAISE EXCEPTION 'La receta debe estar validada';
    END IF;

    IF NEW.resultado <> 'No entregado' THEN
        v_disponible := stock_lote(NEW.id_lote);

        IF TG_OP = 'UPDATE' AND OLD.id_lote = NEW.id_lote
           AND OLD.resultado <> 'No entregado' THEN
            v_disponible := v_disponible + OLD.cantidad;
        END IF;

        IF NEW.cantidad > v_disponible THEN
            RAISE EXCEPTION 'Existencia insuficiente. Disponible: %',v_disponible;
        END IF;
    END IF;

    RETURN NEW;
END;
$$;

CREATE TRIGGER validar_stock_dispensacion_trg
BEFORE INSERT OR UPDATE ON dispensaciones
FOR EACH ROW EXECUTE FUNCTION validar_stock_dispensacion();

-- ================================================================
-- 21. VISTAS DE CONSULTA
-- ================================================================

CREATE OR REPLACE VIEW v_expediente_pacientes AS
SELECT
    p.id_paciente,
    p.folio,
    p.nombre AS paciente,
    p.especie,
    p.raza,
    p.sexo,
    p.peso,
    p.altura,
    p.estado,
    pr.nombre AS propietario,
    pr.telefono
FROM pacientes p
JOIN propietarios pr
ON p.id_propietario = pr.id_propietario;

CREATE OR REPLACE VIEW v_cuenta_propietarios AS
SELECT
    p.id_propietario,
    p.nombre,
    COALESCE(c.total_cargos,0) AS total_cargos,
    COALESCE(a.total_abonos,0) AS total_abonos,
    COALESCE(c.total_cargos,0) -
    COALESCE(a.total_abonos,0) AS saldo
FROM propietarios p
LEFT JOIN (
    SELECT id_propietario,
           SUM(cantidad * precio_unitario) AS total_cargos
    FROM cargos
    WHERE estado = 'Vigente'
    GROUP BY id_propietario
) c ON c.id_propietario = p.id_propietario
LEFT JOIN (
    SELECT id_propietario,
           SUM(monto) AS total_abonos
    FROM abonos
    WHERE estado = 'Vigente'
    GROUP BY id_propietario
) a ON a.id_propietario = p.id_propietario;

CREATE OR REPLACE VIEW v_existencias_farmacia AS
SELECT
    m.id_lote,
    m.folio,
    m.principio_activo,
    m.nombre_comercial,
    m.lote,
    m.caducidad,
    stock_lote(m.id_lote) AS existencia,
    CASE
        WHEN m.caducidad < CURRENT_DATE THEN 'Caducado'
        WHEN m.caducidad <= CURRENT_DATE + 60 THEN 'Próximo a caducar'
        ELSE 'Vigente'
    END AS alerta
FROM medicamentos_lotes m;

CREATE OR REPLACE VIEW v_hospitalizados AS
SELECT
    a.id_admision,
    a.folio,
    p.nombre AS paciente,
    p.especie,
    ar.nombre AS area,
    a.box,
    a.fecha_ingreso,
    a.estado
FROM admisiones a
JOIN pacientes p ON p.id_paciente = a.id_paciente
JOIN areas ar ON ar.id_area = a.id_area
WHERE a.estado IN ('Registrado','Hospitalizado','En observación');

-- ================================================================
-- 22. AUDITORÍA AUTOMÁTICA
-- ================================================================

CREATE OR REPLACE FUNCTION registrar_auditoria()
RETURNS TRIGGER
LANGUAGE plpgsql
AS $$
DECLARE
    v_id BIGINT;
    v_antes JSONB;
    v_despues JSONB;
    v_accion TEXT;
BEGIN
    IF TG_OP = 'INSERT' THEN
        v_despues := TO_JSONB(NEW);
        v_id := (v_despues ->> TG_ARGV[0])::BIGINT;
        v_accion := 'INSERT';

    ELSIF TG_OP = 'UPDATE' THEN
        v_antes := TO_JSONB(OLD);
        v_despues := TO_JSONB(NEW);
        v_id := (v_despues ->> TG_ARGV[0])::BIGINT;
        v_accion := 'UPDATE';

    ELSE
        v_antes := TO_JSONB(OLD);
        v_id := (v_antes ->> TG_ARGV[0])::BIGINT;
        v_accion := 'DELETE';
    END IF;

    INSERT INTO bitacora(
        id_usuario,tabla,id_registro,accion,detalle
    )
    VALUES(
        NULLIF(CURRENT_SETTING('app.id_usuario',TRUE),'')::BIGINT,
        TG_TABLE_NAME,
        v_id,
        v_accion,
        JSONB_BUILD_OBJECT(
            'antes',v_antes,
            'despues',v_despues
        )
    );

    IF TG_OP <> 'INSERT' THEN
        INSERT INTO versiones_registro(
            tabla,id_registro,id_usuario,operacion,
            datos_anteriores,datos_nuevos
        )
        VALUES(
            TG_TABLE_NAME,
            v_id,
            NULLIF(CURRENT_SETTING('app.id_usuario',TRUE),'')::BIGINT,
            v_accion,
            v_antes,
            v_despues
        );
    END IF;

    IF TG_OP = 'DELETE' THEN
        RETURN OLD;
    END IF;

    RETURN NEW;
END;
$$;

DO $$
DECLARE r RECORD;
BEGIN
    FOR r IN
        SELECT * FROM (VALUES
            ('propietarios','id_propietario'),
            ('pacientes','id_paciente'),
            ('consultas','id_consulta'),
            ('admisiones','id_admision'),
            ('triage','id_triage'),
            ('interconsultas','id_interconsulta'),
            ('estudios_laboratorio','id_estudio_lab'),
            ('estudios_imagen','id_estudio_img'),
            ('cirugias','id_cirugia'),
            ('medicamentos_lotes','id_lote'),
            ('movimientos_farmacia','id_movimiento'),
            ('recetas','id_receta'),
            ('dispensaciones','id_dispensacion'),
            ('cargos','id_cargo'),
            ('abonos','id_abono'),
            ('actividades_academicas','id_actividad')
        ) AS x(tabla,pk)
    LOOP
        EXECUTE FORMAT(
            'CREATE TRIGGER auditoria_trg
             AFTER INSERT OR UPDATE OR DELETE ON %I
             FOR EACH ROW EXECUTE FUNCTION registrar_auditoria(%L)',
            r.tabla,r.pk
        );
    END LOOP;
END;
$$;

-- ================================================================
-- 23. DATOS INICIALES
-- ================================================================

INSERT INTO roles(nombre,descripcion) VALUES
('Administrador','Administración completa del sistema'),
('Director','Responsable del hospital'),
('Veterinario','Atención médica veterinaria'),
('Especialista','Atención especializada'),
('Recepcionista','Registro de propietarios y pacientes'),
('Farmacia','Control de medicamentos e inventario'),
('Laboratorio','Procesamiento de estudios'),
('Imagenología','Estudios de diagnóstico por imagen'),
('Estudiante','Actividades académicas supervisadas'),
('Supervisor','Supervisión académica y clínica')
ON CONFLICT(nombre) DO NOTHING;

INSERT INTO areas(nombre,descripcion) VALUES
('Recepción','Registro y atención inicial'),
('Medicina Interna','Diagnóstico y tratamiento médico'),
('Cirugía','Procedimientos quirúrgicos'),
('Urgencias','Atención de emergencias equinas'),
('Hospitalización','Estancia y vigilancia de pacientes'),
('Reproducción Equina','Atención reproductiva'),
('Odontología Equina','Salud dental de equinos'),
('Ortopedia','Evaluación musculoesquelética'),
('Laboratorio','Análisis clínicos'),
('Imagenología','Radiología y ultrasonografía'),
('Farmacia','Almacenamiento y dispensación'),
('Rehabilitación','Recuperación física')
ON CONFLICT(nombre) DO NOTHING;

COMMIT;

-- ================================================================
-- FIN DEL ESQUEMA
-- ================================================================
