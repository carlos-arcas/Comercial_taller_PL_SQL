-- === File: sql/03_sequences.sql ===
-- Secuencias para IDs (modelo portable / reproducible)
-- Requiere: 01_tables.sql y recomendable 02_constraints.sql ya aplicado

------------------------------------------------------------
-- Secuencias principales
------------------------------------------------------------

CREATE SEQUENCE seq_personal          START WITH 1 INCREMENT BY 1 NOCACHE NOCYCLE;
CREATE SEQUENCE seq_clientes          START WITH 1 INCREMENT BY 1 NOCACHE NOCYCLE;
CREATE SEQUENCE seq_productos         START WITH 1 INCREMENT BY 1 NOCACHE NOCYCLE;

CREATE SEQUENCE seq_ventas            START WITH 1 INCREMENT BY 1 NOCACHE NOCYCLE;
CREATE SEQUENCE seq_ventas_lineas     START WITH 1 INCREMENT BY 1 NOCACHE NOCYCLE;

CREATE SEQUENCE seq_alquileres        START WITH 1 INCREMENT BY 1 NOCACHE NOCYCLE;
CREATE SEQUENCE seq_alquileres_lineas START WITH 1 INCREMENT BY 1 NOCACHE NOCYCLE;

CREATE SEQUENCE seq_mantenimientos    START WITH 1 INCREMENT BY 1 NOCACHE NOCYCLE;

CREATE SEQUENCE seq_auditoria_eventos START WITH 1 INCREMENT BY 1 NOCACHE NOCYCLE;

------------------------------------------------------------
-- Nota sobre numeración "de negocio" (num_venta/num_alquiler)
-- Se generan en packages con formato: V-YYYYMM-000001 / A-YYYYMM-000001
-- usando seq_ventas/seq_alquileres como base.
------------------------------------------------------------

-- Fin 03_sequences.sql