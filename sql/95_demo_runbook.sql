-- === File: sql/95_demo_runbook.sql ===
-- Runbook Demo: escenarios + queries de verificación + KPIs
-- Requiere: seed ejecutado (90_seed_demo.sql)

PROMPT =========================================================
PROMPT 0) Smoke checks (volumen y estados)
PROMPT =========================================================

SELECT COUNT(*) AS total_ventas FROM ventas;
SELECT estado, COUNT(*) AS cnt FROM ventas GROUP BY estado ORDER BY estado;

SELECT COUNT(*) AS total_alquileres FROM alquileres;
SELECT estado, COUNT(*) AS cnt FROM alquileres GROUP BY estado ORDER BY estado;

SELECT COUNT(*) AS total_mantenimientos FROM mantenimientos;
SELECT estado, COUNT(*) AS cnt FROM mantenimientos GROUP BY estado ORDER BY estado;

SELECT COUNT(*) AS total_auditoria FROM auditoria_eventos;

PROMPT =========================================================
PROMPT 1) Verificación stock y disponibilidad
PROMPT    disponibilidad = stock_total - stock_reservado
PROMPT =========================================================

SELECT
  ref_producto,
  nombre,
  stock_total,
  stock_reservado,
  (stock_total - stock_reservado) AS disponible
FROM productos
ORDER BY ref_producto;

PROMPT =========================================================
PROMPT 2) KPI 1: Nº de ventas por producto (unidades + importe)
PROMPT =========================================================

SELECT
  ref_producto,
  nombre_producto,
  SUM(cantidad) AS unidades_vendidas,
  SUM(importe)  AS importe_vendido
FROM vw_fact_ventas
GROUP BY ref_producto, nombre_producto
ORDER BY importe_vendido DESC;

PROMPT =========================================================
PROMPT 3) KPI 2: Productos recibidos por cliente
PROMPT    - variedad (nº productos distintos)
PROMPT    - unidades totales
PROMPT =========================================================

-- Variedad y unidades (ventas confirmadas)
SELECT
  cliente_id,
  MAX(razon_social) AS razon_social,
  COUNT(DISTINCT producto_id) AS variedad_productos,
  SUM(cantidad) AS unidades_totales
FROM (
  SELECT
    f.cliente_id,
    c.razon_social,
    f.producto_id,
    f.cantidad
  FROM vw_fact_ventas f
  JOIN clientes c ON c.cliente_id = f.cliente_id
)
GROUP BY cliente_id
ORDER BY unidades_totales DESC;

PROMPT =========================================================
PROMPT 4) KPI 3: Ventas vs Alquileres por producto y por mes
PROMPT =========================================================

SELECT *
FROM vw_kpi_ventas_vs_alquileres_por_producto_mes
ORDER BY mes, ref_producto;

PROMPT =========================================================
PROMPT 5) KPI 4: Mantenimientos por producto (vigentes/vencidos)
PROMPT =========================================================

SELECT *
FROM vw_kpi_mantenimientos_por_producto
ORDER BY total_mantenimientos DESC;

PROMPT =========================================================
PROMPT 6) Extra: alquileres que vencen en X días
PROMPT    (ejemplo: próximos 15 días)
PROMPT =========================================================

SELECT *
FROM vw_alquileres_proximos_vencer
WHERE dias_para_vencer BETWEEN 0 AND 15
ORDER BY dias_para_vencer;

PROMPT =========================================================
PROMPT 7) Extra: Top comerciales por ventas / alquiler
PROMPT =========================================================

SELECT *
FROM vw_kpi_top_comerciales
ORDER BY importe_ventas DESC;

PROMPT =========================================================
PROMPT 8) Escenario demo APEX #1: Crear y confirmar una venta
PROMPT    - Crea venta BORRADOR
PROMPT    - Añade líneas
PROMPT    - Confirma (descuenta stock_total)
PROMPT =========================================================

DECLARE
  v_cli NUMBER;
  v_com NUMBER;
  v_p1  NUMBER;
  v_p2  NUMBER;
  v_venta_id NUMBER;
  v_line_id NUMBER;
BEGIN
  SELECT cliente_id INTO v_cli FROM clientes WHERE activo='S' ORDER BY cliente_id FETCH FIRST 1 ROWS ONLY;
  SELECT comercial_id INTO v_com FROM comerciales ORDER BY comercial_id FETCH FIRST 1 ROWS ONLY;

  SELECT producto_id INTO v_p1 FROM productos WHERE ref_producto='P-LLAVE-001';
  SELECT producto_id INTO v_p2 FROM productos WHERE ref_producto='P-CONS-004';

  pkg_ventas.crear_venta(v_cli, v_com, TRUNC(SYSDATE), 'Runbook: venta manual', v_venta_id);
  pkg_ventas.add_linea(v_venta_id, v_p1, 1, NULL, v_line_id);
  pkg_ventas.add_linea(v_venta_id, v_p2, 5, NULL, v_line_id);
  pkg_ventas.confirmar_venta(v_venta_id, 'Runbook: confirmación venta manual');
END;
/
-- Ver impacto en stock
SELECT ref_producto, stock_total, stock_reservado
FROM productos
WHERE ref_producto IN ('P-LLAVE-001','P-CONS-004');

PROMPT =========================================================
PROMPT 9) Escenario demo APEX #2: Crear alquiler y cerrar
PROMPT    - Crea alquiler ACTIVO
PROMPT    - Añade línea (reserva stock_reservado)
PROMPT    - Cierra (libera stock_reservado)
PROMPT =========================================================

DECLARE
  v_cli NUMBER;
  v_com NUMBER;
  v_p   NUMBER;
  v_alq_id NUMBER;
  v_lid NUMBER;
BEGIN
  SELECT cliente_id INTO v_cli FROM clientes WHERE activo='S' ORDER BY cliente_id FETCH FIRST 1 ROWS ONLY;
  SELECT comercial_id INTO v_com FROM comerciales ORDER BY comercial_id FETCH FIRST 1 ROWS ONLY;
  SELECT producto_id INTO v_p FROM productos WHERE ref_producto='P-DIAG-003';

  pkg_alquileres.crear_alquiler(v_cli, v_com, TRUNC(SYSDATE), TRUNC(SYSDATE)+30, 'Runbook: alquiler manual', v_alq_id);
  pkg_alquileres.add_linea(v_alq_id, v_p, 1, NULL, v_lid);

  -- Ver reserva
  SELECT ref_producto, stock_total, stock_reservado, (stock_total-stock_reservado) AS disponible
  FROM productos
  WHERE ref_producto='P-DIAG-003';

  pkg_alquileres.cerrar_alquiler(v_alq_id, 'Runbook: cierre alquiler manual');

  -- Ver liberación
  SELECT ref_producto, stock_total, stock_reservado, (stock_total-stock_reservado) AS disponible
  FROM productos
  WHERE ref_producto='P-DIAG-003';
END;
/

PROMPT =========================================================
PROMPT 10) Escenario demo APEX #3: Contratar y renovar mantenimiento
PROMPT     (sobre una venta_linea de venta CONFIRMADA)
PROMPT =========================================================

DECLARE
  v_vl NUMBER;
  v_m1 NUMBER;
  v_m2 NUMBER;
BEGIN
  -- Elegimos cualquier venta_linea confirmada con producto que permita mantenimiento
  SELECT vl.venta_linea_id
    INTO v_vl
    FROM ventas_lineas vl
    JOIN ventas v ON v.venta_id = vl.venta_id
    JOIN productos p ON p.producto_id = vl.producto_id
   WHERE v.estado='CONFIRMADA'
     AND p.permite_mantenimiento='S'
   ORDER BY DBMS_RANDOM.VALUE
   FETCH FIRST 1 ROWS ONLY;

  pkg_mantenimientos.contratar(v_vl, TRUNC(SYSDATE), 6, 'Runbook: contratar 6 meses', v_m1);
  pkg_mantenimientos.renovar(v_m1, TRUNC(SYSDATE), 12, 'Runbook: renovar 12 meses', v_m2);
  pkg_mantenimientos.marcar_vencidos(TRUNC(SYSDATE));
END;
/

PROMPT =========================================================
PROMPT 11) Auditoría: últimos 50 eventos
PROMPT =========================================================

SELECT
  evento_id,
  fecha_evento,
  actor,
  modulo,
  accion,
  entidad,
  entidad_id,
  detalle
FROM auditoria_eventos
ORDER BY fecha_evento DESC
FETCH FIRST 50 ROWS ONLY;

PROMPT =========================================================
PROMPT 12) Queries útiles para Power BI (tablas a importar)
PROMPT =========================================================

-- Facts
SELECT * FROM vw_fact_ventas FETCH FIRST 5 ROWS ONLY;
SELECT * FROM vw_fact_alquileres FETCH FIRST 5 ROWS ONLY;
SELECT * FROM vw_fact_mantenimientos FETCH FIRST 5 ROWS ONLY;

-- Dims
SELECT * FROM vw_dim_clientes FETCH FIRST 5 ROWS ONLY;
SELECT * FROM vw_dim_productos FETCH FIRST 5 ROWS ONLY;
SELECT * FROM vw_dim_comerciales FETCH FIRST 5 ROWS ONLY;

-- KPIs
SELECT * FROM vw_kpi_ventas_vs_alquileres_por_producto_mes FETCH FIRST 10 ROWS ONLY;
SELECT * FROM vw_kpi_mantenimientos_por_producto FETCH FIRST 10 ROWS ONLY;

-- Fin 95_demo_runbook.sql