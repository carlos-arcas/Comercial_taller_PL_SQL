-- === File: sql/40_pkg_mantenimientos.pks ===
CREATE OR REPLACE PACKAGE pkg_mantenimientos AS
  ------------------------------------------------------------------------------
  -- Mantenimientos (solo para productos VENDIDOS)
  -- - Vinculados a ventas_lineas
  -- - Renovable por periodos: renovar = crear nuevo registro
  -- - Estados: VIGENTE / VENCIDO / ANULADO
  ------------------------------------------------------------------------------

  c_err_param        CONSTANT NUMBER := -20210;
  c_err_estado       CONSTANT NUMBER := -20211;
  c_err_notfound     CONSTANT NUMBER := -20212;
  c_err_regla        CONSTANT NUMBER := -20213;

  c_estado_vigente   CONSTANT VARCHAR2(20) := 'VIGENTE';
  c_estado_vencido   CONSTANT VARCHAR2(20) := 'VENCIDO';
  c_estado_anulado   CONSTANT VARCHAR2(20) := 'ANULADO';

  -- Contratar mantenimiento para una venta_linea
  PROCEDURE contratar(
    p_venta_linea_id     IN  NUMBER,
    p_fecha_inicio       IN  DATE DEFAULT TRUNC(SYSDATE),
    p_duracion_meses     IN  NUMBER DEFAULT 12,
    p_comentario         IN  VARCHAR2,
    o_mantenimiento_id   OUT NUMBER
  );

  -- Renovar un mantenimiento existente (crea nuevo periodo)
  PROCEDURE renovar(
    p_mantenimiento_id_anterior IN NUMBER,
    p_fecha_inicio              IN DATE DEFAULT TRUNC(SYSDATE),
    p_duracion_meses            IN NUMBER DEFAULT 12,
    p_comentario                IN VARCHAR2,
    o_mantenimiento_id_nuevo    OUT NUMBER
  );

  -- Marca como VENCIDO los mantenimientos cuyo vencimiento < hoy (si estaban VIGENTE)
  PROCEDURE marcar_vencidos(
    p_fecha_corte IN DATE DEFAULT TRUNC(SYSDATE)
  );

END pkg_mantenimientos;
/