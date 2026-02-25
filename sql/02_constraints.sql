-- === File: sql/02_constraints.sql ===
-- Constraints + índices para integridad fuerte y rendimiento BI
-- Requiere haber ejecutado: 01_tables.sql

------------------------------------------------------------
-- PKs
------------------------------------------------------------

ALTER TABLE personal            ADD CONSTRAINT pk_personal PRIMARY KEY (personal_id);
ALTER TABLE comerciales         ADD CONSTRAINT pk_comerciales PRIMARY KEY (comercial_id);
ALTER TABLE clientes            ADD CONSTRAINT pk_clientes PRIMARY KEY (cliente_id);
ALTER TABLE productos           ADD CONSTRAINT pk_productos PRIMARY KEY (producto_id);

ALTER TABLE ventas              ADD CONSTRAINT pk_ventas PRIMARY KEY (venta_id);
ALTER TABLE ventas_lineas       ADD CONSTRAINT pk_ventas_lineas PRIMARY KEY (venta_linea_id);

ALTER TABLE alquileres          ADD CONSTRAINT pk_alquileres PRIMARY KEY (alquiler_id);
ALTER TABLE alquileres_lineas   ADD CONSTRAINT pk_alquileres_lineas PRIMARY KEY (alquiler_linea_id);

ALTER TABLE mantenimientos      ADD CONSTRAINT pk_mantenimientos PRIMARY KEY (mantenimiento_id);

ALTER TABLE auditoria_eventos   ADD CONSTRAINT pk_auditoria_eventos PRIMARY KEY (evento_id);

------------------------------------------------------------
-- UNIQUEs (negocio)
------------------------------------------------------------

ALTER TABLE personal    ADD CONSTRAINT uk_personal_dni UNIQUE (dni_nif);
ALTER TABLE personal    ADD CONSTRAINT uk_personal_email UNIQUE (email);

ALTER TABLE comerciales ADD CONSTRAINT uk_comerciales_codigo UNIQUE (codigo_comercial);

ALTER TABLE clientes    ADD CONSTRAINT uk_clientes_cif UNIQUE (cif_nif);
ALTER TABLE clientes    ADD CONSTRAINT uk_clientes_email UNIQUE (email);

ALTER TABLE productos   ADD CONSTRAINT uk_productos_ref UNIQUE (ref_producto);

ALTER TABLE ventas      ADD CONSTRAINT uk_ventas_num UNIQUE (num_venta);
ALTER TABLE alquileres  ADD CONSTRAINT uk_alquileres_num UNIQUE (num_alquiler);

-- Evitar líneas duplicadas por número dentro de cabecera
ALTER TABLE ventas_lineas     ADD CONSTRAINT uk_ventas_lineas_num UNIQUE (venta_id, linea_num);
ALTER TABLE alquileres_lineas ADD CONSTRAINT uk_alquileres_lineas_num UNIQUE (alquiler_id, linea_num);

------------------------------------------------------------
-- FKs
------------------------------------------------------------

-- Subtipo 1:1 comerciales -> personal
ALTER TABLE comerciales
  ADD CONSTRAINT fk_comerciales_personal
  FOREIGN KEY (comercial_id) REFERENCES personal (personal_id);

-- Ventas
ALTER TABLE ventas
  ADD CONSTRAINT fk_ventas_clientes
  FOREIGN KEY (cliente_id) REFERENCES clientes (cliente_id);

ALTER TABLE ventas
  ADD CONSTRAINT fk_ventas_comerciales
  FOREIGN KEY (comercial_id) REFERENCES comerciales (comercial_id);

ALTER TABLE ventas_lineas
  ADD CONSTRAINT fk_ventas_lineas_ventas
  FOREIGN KEY (venta_id) REFERENCES ventas (venta_id);

ALTER TABLE ventas_lineas
  ADD CONSTRAINT fk_ventas_lineas_productos
  FOREIGN KEY (producto_id) REFERENCES productos (producto_id);

-- Alquileres
ALTER TABLE alquileres
  ADD CONSTRAINT fk_alquileres_clientes
  FOREIGN KEY (cliente_id) REFERENCES clientes (cliente_id);

ALTER TABLE alquileres
  ADD CONSTRAINT fk_alquileres_comerciales
  FOREIGN KEY (comercial_id) REFERENCES comerciales (comercial_id);

ALTER TABLE alquileres_lineas
  ADD CONSTRAINT fk_alquileres_lineas_alquileres
  FOREIGN KEY (alquiler_id) REFERENCES alquileres (alquiler_id);

ALTER TABLE alquileres_lineas
  ADD CONSTRAINT fk_alquileres_lineas_productos
  FOREIGN KEY (producto_id) REFERENCES productos (producto_id);

-- Mantenimientos
ALTER TABLE mantenimientos
  ADD CONSTRAINT fk_mant_venta
  FOREIGN KEY (venta_id) REFERENCES ventas (venta_id);

ALTER TABLE mantenimientos
  ADD CONSTRAINT fk_mant_venta_linea
  FOREIGN KEY (venta_linea_id) REFERENCES ventas_lineas (venta_linea_id);

ALTER TABLE mantenimientos
  ADD CONSTRAINT fk_mant_renovacion_de
  FOREIGN KEY (renovacion_de_id) REFERENCES mantenimientos (mantenimiento_id);

------------------------------------------------------------
-- CHECKs y NOT NULL “de negocio”
------------------------------------------------------------

-- Flags S/N
ALTER TABLE personal   ADD CONSTRAINT ck_personal_activo   CHECK (activo IN ('S','N'));
ALTER TABLE clientes   ADD CONSTRAINT ck_clientes_activo   CHECK (activo IN ('S','N'));
ALTER TABLE productos  ADD CONSTRAINT ck_productos_activo  CHECK (activo IN ('S','N'));
ALTER TABLE productos  ADD CONSTRAINT ck_productos_perm_mant CHECK (permite_mantenimiento IN ('S','N'));

-- Stock no negativo
ALTER TABLE productos  ADD CONSTRAINT ck_productos_stock_total CHECK (stock_total >= 0);
ALTER TABLE productos  ADD CONSTRAINT ck_productos_stock_reservado CHECK (stock_reservado >= 0);
ALTER TABLE productos  ADD CONSTRAINT ck_productos_stock_rel CHECK (stock_reservado <= stock_total);

-- Precios no negativos (0 permitido si quieres “promo”, pero aquí lo evitamos)
ALTER TABLE productos  ADD CONSTRAINT ck_productos_precio_venta CHECK (precio_venta >= 0);
ALTER TABLE productos  ADD CONSTRAINT ck_productos_precio_alq CHECK (precio_alquiler_mensual >= 0);

-- Estados
ALTER TABLE ventas     ADD CONSTRAINT ck_ventas_estado CHECK (estado IN ('BORRADOR','CONFIRMADA','ANULADA'));
ALTER TABLE alquileres ADD CONSTRAINT ck_alquileres_estado CHECK (estado IN ('ACTIVO','FINALIZADO','ANULADO'));
ALTER TABLE mantenimientos ADD CONSTRAINT ck_mant_estado CHECK (estado IN ('VIGENTE','VENCIDO','ANULADO'));

-- Fechas
ALTER TABLE alquileres ADD CONSTRAINT ck_alquileres_fechas CHECK (fecha_fin >= fecha_inicio);
ALTER TABLE mantenimientos ADD CONSTRAINT ck_mant_fechas CHECK (fecha_vencimiento >= fecha_inicio);

-- Cantidades
ALTER TABLE ventas_lineas     ADD CONSTRAINT ck_ventas_lineas_cant CHECK (cantidad > 0);
ALTER TABLE alquileres_lineas ADD CONSTRAINT ck_alquileres_lineas_cant CHECK (cantidad > 0);

-- Importes / precios unitarios
ALTER TABLE ventas_lineas ADD CONSTRAINT ck_ventas_lineas_precio CHECK (precio_unitario >= 0);
ALTER TABLE ventas_lineas ADD CONSTRAINT ck_ventas_lineas_importe CHECK (importe_linea >= 0);

ALTER TABLE alquileres_lineas ADD CONSTRAINT ck_alq_lineas_precio CHECK (precio_mensual >= 0);
ALTER TABLE alquileres_lineas ADD CONSTRAINT ck_alq_lineas_importe CHECK (importe_estimado >= 0);

------------------------------------------------------------
-- Índices (rendimiento BI / joins / filtros)
------------------------------------------------------------

-- Dim joins
CREATE INDEX ix_ventas_cliente      ON ventas (cliente_id);
CREATE INDEX ix_ventas_comercial    ON ventas (comercial_id);
CREATE INDEX ix_ventas_fecha_estado ON ventas (fecha_venta, estado);

CREATE INDEX ix_vl_venta            ON ventas_lineas (venta_id);
CREATE INDEX ix_vl_producto         ON ventas_lineas (producto_id);

CREATE INDEX ix_alq_cliente         ON alquileres (cliente_id);
CREATE INDEX ix_alq_comercial       ON alquileres (comercial_id);
CREATE INDEX ix_alq_fechas_estado   ON alquileres (fecha_inicio, fecha_fin, estado);

CREATE INDEX ix_alq_l_alquiler      ON alquileres_lineas (alquiler_id);
CREATE INDEX ix_alq_l_producto      ON alquileres_lineas (producto_id);

CREATE INDEX ix_mant_venta_linea    ON mantenimientos (venta_linea_id);
CREATE INDEX ix_mant_estado_fechas  ON mantenimientos (estado, fecha_inicio, fecha_vencimiento);

-- Auditoría: filtros por tiempo y entidad
CREATE INDEX ix_aud_fecha_modulo    ON auditoria_eventos (fecha_evento, modulo);
CREATE INDEX ix_aud_entidad         ON auditoria_eventos (entidad, entidad_id);

-- Fin 02_constraints.sql