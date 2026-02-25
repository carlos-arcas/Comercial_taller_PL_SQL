-- === File: sql/01_tables.sql ===
-- Proyecto Portfolio: Empresa venta/alquiler a talleres mecánicos (Oracle)
-- Crea SOLO TABLAS (sin constraints/índices/secuencias). Ver:
--  - 02_constraints.sql
--  - 03_sequences.sql
--  - 10..41 packages
--  - 50_views_bi.sql

-- Recomendación: ejecutar como esquema dedicado (p.ej. PORTFOLIO_TALLER)
-- y con NLS_DATE_LANGUAGE consistente si vas a seedear con fechas.

------------------------------------------------------------
-- 1) Catálogos base
------------------------------------------------------------

CREATE TABLE personal (
    personal_id        NUMBER(12)        NOT NULL,
    dni_nif            VARCHAR2(20)       NOT NULL,
    nombre             VARCHAR2(80)       NOT NULL,
    apellidos          VARCHAR2(120)      NOT NULL,
    email              VARCHAR2(160),
    telefono           VARCHAR2(30),
    fecha_alta         DATE              DEFAULT SYSDATE NOT NULL,
    activo             CHAR(1)           DEFAULT 'S' NOT NULL, -- S/N
    created_at         TIMESTAMP         DEFAULT SYSTIMESTAMP NOT NULL,
    created_by         VARCHAR2(128)     DEFAULT USER NOT NULL,
    updated_at         TIMESTAMP,
    updated_by         VARCHAR2(128)
);

-- Subtipo 1:1 de personal
CREATE TABLE comerciales (
    comercial_id       NUMBER(12)        NOT NULL, -- PK = FK a personal.personal_id
    codigo_comercial   VARCHAR2(30)      NOT NULL,
    zona              VARCHAR2(80),
    objetivo_mensual   NUMBER(12,2),
    created_at         TIMESTAMP         DEFAULT SYSTIMESTAMP NOT NULL,
    created_by         VARCHAR2(128)     DEFAULT USER NOT NULL,
    updated_at         TIMESTAMP,
    updated_by         VARCHAR2(128)
);

CREATE TABLE clientes (
    cliente_id         NUMBER(12)        NOT NULL,
    cif_nif            VARCHAR2(20)       NOT NULL,
    razon_social       VARCHAR2(200)      NOT NULL,
    nombre_contacto    VARCHAR2(120),
    email              VARCHAR2(160),
    telefono           VARCHAR2(30),
    direccion          VARCHAR2(240),
    ciudad             VARCHAR2(120),
    provincia          VARCHAR2(120),
    cp                 VARCHAR2(12),
    pais               VARCHAR2(80)       DEFAULT 'España' NOT NULL,
    fecha_alta         DATE               DEFAULT SYSDATE NOT NULL,
    activo             CHAR(1)            DEFAULT 'S' NOT NULL, -- S/N
    created_at         TIMESTAMP          DEFAULT SYSTIMESTAMP NOT NULL,
    created_by         VARCHAR2(128)      DEFAULT USER NOT NULL,
    updated_at         TIMESTAMP,
    updated_by         VARCHAR2(128)
);

CREATE TABLE productos (
    producto_id        NUMBER(12)        NOT NULL,
    ref_producto       VARCHAR2(40)      NOT NULL,
    nombre             VARCHAR2(200)     NOT NULL,
    categoria          VARCHAR2(120),
    unidad_medida      VARCHAR2(30)      DEFAULT 'ud' NOT NULL,
    stock_total        NUMBER(12,2)      DEFAULT 0 NOT NULL,
    stock_reservado    NUMBER(12,2)      DEFAULT 0 NOT NULL,
    precio_venta       NUMBER(12,2)      NOT NULL,
    precio_alquiler_mensual NUMBER(12,2) NOT NULL,
    permite_mantenimiento CHAR(1)        DEFAULT 'S' NOT NULL, -- S/N (si el producto admite mantenimiento)
    activo             CHAR(1)           DEFAULT 'S' NOT NULL, -- S/N
    created_at         TIMESTAMP         DEFAULT SYSTIMESTAMP NOT NULL,
    created_by         VARCHAR2(128)     DEFAULT USER NOT NULL,
    updated_at         TIMESTAMP,
    updated_by         VARCHAR2(128)
);

------------------------------------------------------------
-- 2) Ventas (cabecera + líneas)
------------------------------------------------------------

CREATE TABLE ventas (
    venta_id           NUMBER(12)        NOT NULL,
    num_venta          VARCHAR2(30)      NOT NULL, -- legible para negocio
    fecha_venta        DATE              DEFAULT TRUNC(SYSDATE) NOT NULL,
    cliente_id         NUMBER(12)        NOT NULL,
    comercial_id       NUMBER(12)        NOT NULL,
    estado             VARCHAR2(20)      DEFAULT 'BORRADOR' NOT NULL, -- BORRADOR/CONFIRMADA/ANULADA
    moneda             VARCHAR2(3)       DEFAULT 'EUR' NOT NULL,
    total_importe      NUMBER(14,2)      DEFAULT 0 NOT NULL,
    observaciones      VARCHAR2(2000),
    created_at         TIMESTAMP         DEFAULT SYSTIMESTAMP NOT NULL,
    created_by         VARCHAR2(128)     DEFAULT USER NOT NULL,
    updated_at         TIMESTAMP,
    updated_by         VARCHAR2(128)
);

CREATE TABLE ventas_lineas (
    venta_linea_id     NUMBER(12)        NOT NULL,
    venta_id           NUMBER(12)        NOT NULL,
    linea_num          NUMBER(6)         NOT NULL,
    producto_id        NUMBER(12)        NOT NULL,
    cantidad           NUMBER(12,2)      NOT NULL,
    precio_unitario    NUMBER(12,2)      NOT NULL,
    importe_linea      NUMBER(14,2)      NOT NULL,
    created_at         TIMESTAMP         DEFAULT SYSTIMESTAMP NOT NULL,
    created_by         VARCHAR2(128)     DEFAULT USER NOT NULL,
    updated_at         TIMESTAMP,
    updated_by         VARCHAR2(128)
);

------------------------------------------------------------
-- 3) Alquileres (cabecera + líneas)
------------------------------------------------------------

CREATE TABLE alquileres (
    alquiler_id        NUMBER(12)        NOT NULL,
    num_alquiler       VARCHAR2(30)      NOT NULL,
    fecha_inicio       DATE              DEFAULT TRUNC(SYSDATE) NOT NULL,
    fecha_fin          DATE              NOT NULL, -- obligatoria
    cliente_id         NUMBER(12)        NOT NULL,
    comercial_id       NUMBER(12)        NOT NULL,
    estado             VARCHAR2(20)      DEFAULT 'ACTIVO' NOT NULL, -- ACTIVO/FINALIZADO/ANULADO
    moneda             VARCHAR2(3)       DEFAULT 'EUR' NOT NULL,
    total_estimado     NUMBER(14,2)      DEFAULT 0 NOT NULL,
    observaciones      VARCHAR2(2000),
    created_at         TIMESTAMP         DEFAULT SYSTIMESTAMP NOT NULL,
    created_by         VARCHAR2(128)     DEFAULT USER NOT NULL,
    updated_at         TIMESTAMP,
    updated_by         VARCHAR2(128)
);

CREATE TABLE alquileres_lineas (
    alquiler_linea_id  NUMBER(12)        NOT NULL,
    alquiler_id        NUMBER(12)        NOT NULL,
    linea_num          NUMBER(6)         NOT NULL,
    producto_id        NUMBER(12)        NOT NULL,
    cantidad           NUMBER(12,2)      NOT NULL,
    precio_mensual     NUMBER(12,2)      NOT NULL,
    importe_estimado   NUMBER(14,2)      NOT NULL,
    created_at         TIMESTAMP         DEFAULT SYSTIMESTAMP NOT NULL,
    created_by         VARCHAR2(128)     DEFAULT USER NOT NULL,
    updated_at         TIMESTAMP,
    updated_by         VARCHAR2(128)
);

------------------------------------------------------------
-- 4) Mantenimientos (solo para productos vendidos)
--    Modelo por periodos renovables: cada renovación = nuevo registro.
------------------------------------------------------------

CREATE TABLE mantenimientos (
    mantenimiento_id   NUMBER(12)        NOT NULL,
    venta_id           NUMBER(12)        NOT NULL,
    venta_linea_id     NUMBER(12)        NOT NULL,
    fecha_inicio       DATE              NOT NULL,
    fecha_vencimiento  DATE              NOT NULL,
    estado             VARCHAR2(20)      DEFAULT 'VIGENTE' NOT NULL, -- VIGENTE/VENCIDO/ANULADO
    renovacion_de_id   NUMBER(12), -- self-FK opcional: referencia al mantenimiento anterior
    comentario         VARCHAR2(1000), -- obligatorio en renovaciones/acciones (se validará en package)
    created_at         TIMESTAMP         DEFAULT SYSTIMESTAMP NOT NULL,
    created_by         VARCHAR2(128)     DEFAULT USER NOT NULL,
    updated_at         TIMESTAMP,
    updated_by         VARCHAR2(128)
);

------------------------------------------------------------
-- 5) Auditoría de eventos (acciones clave)
------------------------------------------------------------

CREATE TABLE auditoria_eventos (
    evento_id          NUMBER(12)        NOT NULL,
    fecha_evento       TIMESTAMP         DEFAULT SYSTIMESTAMP NOT NULL,
    actor              VARCHAR2(128)     NOT NULL, -- APEX: v('APP_USER') o USER
    modulo             VARCHAR2(60)      NOT NULL, -- VENTAS/ALQUILERES/MANTENIMIENTOS/STOCK/APEX
    accion             VARCHAR2(60)      NOT NULL, -- CONFIRMAR/ANULAR/CREAR/CERRAR/RENOVAR/etc
    entidad            VARCHAR2(60)      NOT NULL, -- VENTA/ALQUILER/MANTENIMIENTO/PRODUCTO
    entidad_id         NUMBER(12),
    detalle            VARCHAR2(2000),
    ip_origen          VARCHAR2(80),
    created_at         TIMESTAMP         DEFAULT SYSTIMESTAMP NOT NULL
);

-- Fin 01_tables.sql