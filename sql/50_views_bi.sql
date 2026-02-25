-- === File: sql/50_views_bi.sql ===
-- Capa BI: dims + facts + KPIs (sin margen, sin coste_venta)

------------------------------------------------------------
-- DIMENSIONES
------------------------------------------------------------

CREATE OR REPLACE VIEW vw_dim_clientes AS
SELECT
  c.cliente_id,
  c.cif_nif,
  c.razon_social,
  c.nombre_contacto,
  c.email,
  c.telefono,
  c.direccion,
  c.ciudad,
  c.provincia,
  c.cp,
  c.pais,
  c.fecha_alta,
  c.activo
FROM clientes c;

CREATE OR REPLACE VIEW vw_dim_productos AS
SELECT
  p.producto_id,
  p.ref_producto,
  p.nombre,
  p.categoria,
  p.unidad_medida,
  p.precio_venta,
  p.precio_alquiler_mensual,
  p.permite_mantenimiento,
  p.activo
FROM productos p;

CREATE OR REPLACE VIEW vw_dim_comerciales AS
SELECT
  co.comercial_id,
  co.codigo_comercial,
  co.zona,
  co.objetivo_mensual,
  pe.dni_nif,
  pe.nombre,
  pe.apellidos,
  pe.email,
  pe.telefono,
  pe.activo
FROM comerciales co
JOIN personal pe
  ON pe.personal_id = co.comercial_id;

------------------------------------------------------------
-- FACT VENTAS (solo CONFIRMADAS para BI de ingresos)
------------------------------------------------------------

CREATE OR REPLACE VIEW vw_fact_ventas AS
SELECT
  v.venta_id,
  v.num_venta,
  v.fecha_venta,
  TRUNC(v.fecha_venta, 'MM') AS mes,
  v.cliente_id,
  v.comercial_id,
  vl.venta_linea_id,
  vl.linea_num,
  vl.producto_id,
  p.ref_producto,
  p.nombre AS nombre_producto,
  p.categoria,
  vl.cantidad,
  vl.precio_unitario,
  vl.importe_linea AS importe,
  c.provincia,
  c.ciudad,
  v.estado,
  v.moneda
FROM ventas v
JOIN ventas_lineas vl
  ON vl.venta_id = v.venta_id
JOIN clientes c
  ON c.cliente_id = v.cliente_id
JOIN productos p
  ON p.producto_id = vl.producto_id
WHERE v.estado = 'CONFIRMADA';

------------------------------------------------------------
-- FACT ALQUILERES (ACTIVO / FINALIZADO / ANULADO incluidos)
------------------------------------------------------------

CREATE OR REPLACE VIEW vw_fact_alquileres AS
SELECT
  a.alquiler_id,
  a.num_alquiler,
  a.fecha_inicio,
  a.fecha_fin,
  TRUNC(a.fecha_inicio, 'MM') AS mes_inicio,
  TRUNC(a.fecha_fin, 'MM') AS mes_fin,
  a.cliente_id,
  a.comercial_id,
  al.alquiler_linea_id,
  al.linea_num,
  al.producto_id,
  p.ref_producto,
  p.nombre AS nombre_producto,
  p.categoria,
  al.cantidad,
  al.precio_mensual,
  al.importe_estimado AS importe_estimado,
  c.provincia,
  c.ciudad,
  a.estado,
  a.moneda
FROM alquileres a
JOIN alquileres_lineas al
  ON al.alquiler_id = a.alquiler_id
JOIN clientes c
  ON c.cliente_id = a.cliente_id
JOIN productos p
  ON p.producto_id = al.producto_id;

------------------------------------------------------------
-- FACT MANTENIMIENTOS (solo “contratados”, no alquiler)
------------------------------------------------------------

CREATE OR REPLACE VIEW vw_fact_mantenimientos AS
SELECT
  m.mantenimiento_id,
  m.venta_id,
  m.venta_linea_id,
  v.num_venta,
  v.fecha_venta,
  TRUNC(v.fecha_venta, 'MM') AS mes_venta,
  v.cliente_id,
  v.comercial_id,
  vl.producto_id,
  p.ref_producto,
  p.nombre AS nombre_producto,
  p.categoria,
  m.fecha_inicio,
  m.fecha_vencimiento,
  CASE
    WHEN m.estado = 'VIGENTE' AND TRUNC(m.fecha_vencimiento) < TRUNC(SYSDATE) THEN 'VENCIDO'
    ELSE m.estado
  END AS estado_calc,
  m.estado AS estado_raw,
  m.renovacion_de_id,
  c.provincia,
  c.ciudad
FROM mantenimientos m
JOIN ventas_lineas vl
  ON vl.venta_linea_id = m.venta_linea_id
JOIN ventas v
  ON v.venta_id = m.venta_id
JOIN productos p
  ON p.producto_id = vl.producto_id
JOIN clientes c
  ON c.cliente_id = v.cliente_id;

------------------------------------------------------------
-- KPI 1: Ventas vs Alquileres por producto y por mes
------------------------------------------------------------

CREATE OR REPLACE VIEW vw_kpi_ventas_vs_alquileres_por_producto_mes AS
WITH ventas_mes AS (
  SELECT
    mes,
    producto_id,
    ref_producto,
    nombre_producto,
    categoria,
    SUM(cantidad) AS unidades_ventas,
    SUM(importe)  AS importe_ventas
  FROM vw_fact_ventas
  GROUP BY mes, producto_id, ref_producto, nombre_producto, categoria
),
alquiler_mes AS (
  SELECT
    mes_inicio AS mes,
    producto_id,
    ref_producto,
    nombre_producto,
    categoria,
    SUM(cantidad) AS unidades_alquiler,
    SUM(importe_estimado) AS importe_alquiler_estimado
  FROM vw_fact_alquileres
  GROUP BY mes_inicio, producto_id, ref_producto, nombre_producto, categoria
)
SELECT
  COALESCE(v.mes, a.mes) AS mes,
  COALESCE(v.producto_id, a.producto_id) AS producto_id,
  COALESCE(v.ref_producto, a.ref_producto) AS ref_producto,
  COALESCE(v.nombre_producto, a.nombre_producto) AS nombre_producto,
  COALESCE(v.categoria, a.categoria) AS categoria,
  NVL(v.unidades_ventas, 0) AS unidades_ventas,
  NVL(v.importe_ventas, 0)  AS importe_ventas,
  NVL(a.unidades_alquiler, 0) AS unidades_alquiler,
  NVL(a.importe_alquiler_estimado, 0) AS importe_alquiler_estimado
FROM ventas_mes v
FULL OUTER JOIN alquiler_mes a
  ON a.mes = v.mes
 AND a.producto_id = v.producto_id;

------------------------------------------------------------
-- KPI 2: Mantenimientos por producto (vigentes y vencidos)
------------------------------------------------------------

CREATE OR REPLACE VIEW vw_kpi_mantenimientos_por_producto AS
SELECT
  producto_id,
  ref_producto,
  nombre_producto,
  categoria,
  SUM(CASE WHEN estado_calc = 'VIGENTE' THEN 1 ELSE 0 END) AS mantenimientos_vigentes,
  SUM(CASE WHEN estado_calc = 'VENCIDO' THEN 1 ELSE 0 END) AS mantenimientos_vencidos,
  COUNT(*) AS total_mantenimientos
FROM vw_fact_mantenimientos
GROUP BY producto_id, ref_producto, nombre_producto, categoria;

------------------------------------------------------------
-- Extras: alquileres que vencen en X días
------------------------------------------------------------

CREATE OR REPLACE VIEW vw_alquileres_proximos_vencer AS
SELECT
  a.alquiler_id,
  a.num_alquiler,
  a.fecha_inicio,
  a.fecha_fin,
  a.cliente_id,
  c.razon_social,
  a.comercial_id,
  a.estado,
  (TRUNC(a.fecha_fin) - TRUNC(SYSDATE)) AS dias_para_vencer
FROM alquileres a
JOIN clientes c ON c.cliente_id = a.cliente_id
WHERE a.estado = 'ACTIVO';

------------------------------------------------------------
-- KPI: Top comerciales por ventas (importe) y alquiler (estimado)
------------------------------------------------------------

CREATE OR REPLACE VIEW vw_kpi_top_comerciales AS
WITH vta AS (
  SELECT comercial_id, SUM(importe) AS importe_ventas
  FROM vw_fact_ventas
  GROUP BY comercial_id
),
alq AS (
  SELECT comercial_id, SUM(importe_estimado) AS importe_alquiler_estimado
  FROM vw_fact_alquileres
  WHERE estado IN ('ACTIVO','FINALIZADO')
  GROUP BY comercial_id
)
SELECT
  d.comercial_id,
  d.codigo_comercial,
  d.nombre,
  d.apellidos,
  NVL(vta.importe_ventas,0) AS importe_ventas,
  NVL(alq.importe_alquiler_estimado,0) AS importe_alquiler_estimado
FROM vw_dim_comerciales d
LEFT JOIN vta ON vta.comercial_id = d.comercial_id
LEFT JOIN alq ON alq.comercial_id = d.comercial_id;

------------------------------------------------------------
-- KPI: Rotación stock por producto/mes (simplificado)
------------------------------------------------------------

CREATE OR REPLACE VIEW vw_kpi_rotacion_stock_mes AS
WITH ventas_mes AS (
  SELECT
    mes,
    producto_id,
    SUM(cantidad) AS unidades_vendidas
  FROM vw_fact_ventas
  GROUP BY mes, producto_id
)
SELECT
  v.mes,
  p.producto_id,
  p.ref_producto,
  p.nombre,
  p.categoria,
  NVL(v.unidades_vendidas,0) AS unidades_vendidas,
  p.stock_total,
  CASE
    WHEN p.stock_total = 0 THEN 0
    ELSE ROUND(NVL(v.unidades_vendidas,0) / p.stock_total, 4)
  END AS ratio_rotacion
FROM productos p
LEFT JOIN ventas_mes v
  ON v.producto_id = p.producto_id;

------------------------------------------------------------
-- KPI: CLV simplificado (sin margen)
------------------------------------------------------------

CREATE OR REPLACE VIEW vw_kpi_clv_cliente AS
WITH vtas AS (
  SELECT
    cliente_id,
    MIN(fecha_venta) AS primera_venta,
    MAX(fecha_venta) AS ultima_venta,
    COUNT(DISTINCT venta_id) AS num_ventas,
    SUM(importe) AS ingresos_ventas
  FROM vw_fact_ventas
  GROUP BY cliente_id
),
alq AS (
  SELECT
    cliente_id,
    SUM(importe_estimado) AS ingresos_alquiler_estimado
  FROM vw_fact_alquileres
  WHERE estado IN ('ACTIVO','FINALIZADO')
  GROUP BY cliente_id
)
SELECT
  c.cliente_id,
  c.razon_social,
  NVL(v.num_ventas,0) AS num_ventas,
  NVL(v.ingresos_ventas,0) AS ingresos_ventas,
  NVL(a.ingresos_alquiler_estimado,0) AS ingresos_alquiler_estimado,
  (NVL(v.ingresos_ventas,0) + NVL(a.ingresos_alquiler_estimado,0)) AS clv_ingresos_estimado,
  CASE
    WHEN v.primera_venta IS NULL THEN 0
    ELSE ROUND(MONTHS_BETWEEN(TRUNC(SYSDATE), TRUNC(v.primera_venta)), 2)
  END AS meses_desde_primera_venta,
  v.primera_venta,
  v.ultima_venta
FROM clientes c
LEFT JOIN vtas v ON v.cliente_id = c.cliente_id
LEFT JOIN alq a ON a.cliente_id = c.cliente_id;

-- Fin 50_views_bi.sql