-- === File: sql/30_pkg_alquileres.pks ===
CREATE OR REPLACE PACKAGE pkg_alquileres AS
  ------------------------------------------------------------------------------
  -- Alquileres: cabecera + líneas
  -- Estrategia de disponibilidad/stock:
  -- - stock_total: stock físico
  -- - stock_reservado: unidades comprometidas en alquileres ACTIVO
  -- - ACTIVO: incrementa stock_reservado (reserva)
  -- - FINALIZADO/ANULADO: decrementa stock_reservado (libera)
  --
  -- Concurrencia:
  -- - Al reservar/liberar se bloquea el producto con FOR UPDATE
  ------------------------------------------------------------------------------

  c_err_param        CONSTANT NUMBER := -20110;
  c_err_estado       CONSTANT NUMBER := -20111;
  c_err_notfound     CONSTANT NUMBER := -20112;
  c_err_stock        CONSTANT NUMBER := -20113;
  c_err_integridad   CONSTANT NUMBER := -20114;

  c_estado_activo     CONSTANT VARCHAR2(20) := 'ACTIVO';
  c_estado_finalizado CONSTANT VARCHAR2(20) := 'FINALIZADO';
  c_estado_anulado    CONSTANT VARCHAR2(20) := 'ANULADO';

  -- Crea alquiler (por defecto ACTIVO) con fecha_fin obligatoria
  PROCEDURE crear_alquiler(
    p_cliente_id   IN  NUMBER,
    p_comercial_id IN  NUMBER,
    p_fecha_inicio IN  DATE DEFAULT TRUNC(SYSDATE),
    p_fecha_fin    IN  DATE,
    p_observaciones IN VARCHAR2 DEFAULT NULL,
    o_alquiler_id  OUT NUMBER
  );

  -- Añade línea a un alquiler ACTIVO (permitimos mientras ACTIVO, para demo)
  PROCEDURE add_linea(
    p_alquiler_id      IN  NUMBER,
    p_producto_id      IN  NUMBER,
    p_cantidad         IN  NUMBER,
    p_precio_mensual   IN  NUMBER DEFAULT NULL,
    o_alquiler_linea_id OUT NUMBER
  );

  -- Recalcula total_estimado (simple: meses * sum(precio*cantidad))
  PROCEDURE recalcular_totales(
    p_alquiler_id IN NUMBER
  );

  -- Cierra alquiler: ACTIVO -> FINALIZADO (libera reservas) + auditoría
  PROCEDURE cerrar_alquiler(
    p_alquiler_id IN NUMBER,
    p_comentario  IN VARCHAR2
  );

  -- Anula alquiler: ACTIVO -> ANULADO (libera reservas) + auditoría
  PROCEDURE anular_alquiler(
    p_alquiler_id IN NUMBER,
    p_comentario  IN VARCHAR2
  );

END pkg_alquileres;
/