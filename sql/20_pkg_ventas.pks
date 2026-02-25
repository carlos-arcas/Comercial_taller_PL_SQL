-- === File: sql/20_pkg_ventas.pks ===
CREATE OR REPLACE PACKAGE pkg_ventas AS
  ------------------------------------------------------------------------------
  -- Ventas: cabecera + líneas
  --
  -- Estrategia de stock:
  -- - BORRADOR:   NO descuenta stock
  -- - CONFIRMADA: descuenta stock_total (stock físico)
  -- - ANULADA:    si estaba CONFIRMADA, revierte stock_total
  --
  -- Concurrencia (bloqueo pesimista):
  -- - confirmar_venta / anular_venta:
  --     bloquean la fila de VENTAS con SELECT ... FOR UPDATE
  --     (evita dobles confirmaciones/anulaciones simultáneas).
  -- - descontar/revertir stock:
  --     bloquean PRODUCTOS con FOR UPDATE (o bloqueo implícito por UPDATE).
  ------------------------------------------------------------------------------
  -- Códigos de error estándar (rango -20000 a -20999 recomendado)
  c_err_param        CONSTANT NUMBER := -20010;
  c_err_estado       CONSTANT NUMBER := -20011;
  c_err_notfound     CONSTANT NUMBER := -20012;
  c_err_stock        CONSTANT NUMBER := -20013;
  c_err_integridad   CONSTANT NUMBER := -20014;

  -- Estados
  c_estado_borrador   CONSTANT VARCHAR2(20) := 'BORRADOR';
  c_estado_confirmada CONSTANT VARCHAR2(20) := 'CONFIRMADA';
  c_estado_anulada    CONSTANT VARCHAR2(20) := 'ANULADA';

  -- Crea venta en BORRADOR
  PROCEDURE crear_venta(
    p_cliente_id    IN  NUMBER,
    p_comercial_id  IN  NUMBER,
    p_fecha_venta   IN  DATE DEFAULT TRUNC(SYSDATE),
    p_observaciones IN  VARCHAR2 DEFAULT NULL,
    o_venta_id      OUT NUMBER
  );

  -- Añade línea a una venta en BORRADOR
  PROCEDURE add_linea(
    p_venta_id        IN  NUMBER,
    p_producto_id     IN  NUMBER,
    p_cantidad        IN  NUMBER,
    p_precio_unitario IN  NUMBER DEFAULT NULL,
    o_venta_linea_id  OUT NUMBER
  );

  -- Recalcula total_importe desde líneas (utility)
  PROCEDURE recalcular_totales(
    p_venta_id IN NUMBER
  );

  -- Confirma venta:
  -- - requiere comentario
  -- - valida estado (solo BORRADOR)
  -- - valida que existan líneas
  -- - descuenta stock
  -- - pasa a CONFIRMADA
  -- - audita evento
  PROCEDURE confirmar_venta(
    p_venta_id   IN NUMBER,
    p_comentario IN VARCHAR2
  );

  -- Anula venta:
  -- - requiere comentario
  -- - si estaba CONFIRMADA revierte stock
  -- - pasa a ANULADA
  -- - audita evento
  PROCEDURE anular_venta(
    p_venta_id   IN NUMBER,
    p_comentario IN VARCHAR2
  );

END pkg_ventas;
/