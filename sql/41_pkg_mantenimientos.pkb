-- === File: sql/41_pkg_mantenimientos.pkb ===
CREATE OR REPLACE PACKAGE BODY pkg_mantenimientos AS

  ------------------------------------------------------------------------------
  -- Util: valida venta_linea existe, devuelve venta_id, producto_id y estado venta
  ------------------------------------------------------------------------------
  PROCEDURE get_contexto_venta_linea(
    p_venta_linea_id IN NUMBER,
    o_venta_id       OUT NUMBER,
    o_producto_id    OUT NUMBER,
    o_estado_venta   OUT VARCHAR2
  ) IS
  BEGIN
    SELECT vl.venta_id, vl.producto_id, v.estado
      INTO o_venta_id, o_producto_id, o_estado_venta
      FROM ventas_lineas vl
      JOIN ventas v ON v.venta_id = vl.venta_id
     WHERE vl.venta_linea_id = p_venta_linea_id;
  EXCEPTION
    WHEN NO_DATA_FOUND THEN
      raise_application_error(c_err_notfound, 'Venta_linea no encontrada: '||p_venta_linea_id);
  END get_contexto_venta_linea;


  FUNCTION calc_vencimiento(p_inicio IN DATE, p_meses IN NUMBER) RETURN DATE IS
  BEGIN
    RETURN ADD_MONTHS(TRUNC(p_inicio), p_meses);
  END calc_vencimiento;


  FUNCTION estado_por_fechas(p_inicio IN DATE, p_venc IN DATE, p_hoy IN DATE) RETURN VARCHAR2 IS
  BEGIN
    IF TRUNC(p_venc) < TRUNC(p_hoy) THEN
      RETURN c_estado_vencido;
    ELSE
      RETURN c_estado_vigente;
    END IF;
  END estado_por_fechas;


  ------------------------------------------------------------------------------
  -- Contratar mantenimiento (solo venta confirmada + producto permite mantenimiento)
  ------------------------------------------------------------------------------
  PROCEDURE contratar(
    p_venta_linea_id     IN  NUMBER,
    p_fecha_inicio       IN  DATE DEFAULT TRUNC(SYSDATE),
    p_duracion_meses     IN  NUMBER DEFAULT 12,
    p_comentario         IN  VARCHAR2,
    o_mantenimiento_id   OUT NUMBER
  ) IS
    l_venta_id    NUMBER;
    l_producto_id NUMBER;
    l_estado_venta VARCHAR2(20);
    l_perm CHAR(1);
    l_id   NUMBER;
    l_ini  DATE;
    l_venc DATE;
    l_estado VARCHAR2(20);
    l_cnt NUMBER;
  BEGIN
    IF p_venta_linea_id IS NULL THEN
      raise_application_error(c_err_param, 'contratar: venta_linea_id obligatorio');
    END IF;

    IF p_duracion_meses IS NULL OR p_duracion_meses <= 0 THEN
      raise_application_error(c_err_param, 'contratar: duracion_meses debe ser > 0');
    END IF;

    IF p_comentario IS NULL OR LENGTH(TRIM(p_comentario)) < 3 THEN
      raise_application_error(c_err_param, 'contratar: comentario obligatorio (mín. 3 caracteres)');
    END IF;

    get_contexto_venta_linea(p_venta_linea_id, l_venta_id, l_producto_id, l_estado_venta);

    IF l_estado_venta <> pkg_ventas.c_estado_confirmada THEN
      raise_application_error(c_err_estado,
        'contratar: la venta debe estar CONFIRMADA. venta_id='||l_venta_id||' estado='||l_estado_venta);
    END IF;

    SELECT permite_mantenimiento
      INTO l_perm
      FROM productos
     WHERE producto_id = l_producto_id;

    IF l_perm <> 'S' THEN
      raise_application_error(c_err_regla,
        'contratar: el producto no permite mantenimiento. producto_id='||l_producto_id);
    END IF;

    -- Evitar duplicar un mantenimiento vigente para la misma venta_linea (regla razonable)
    SELECT COUNT(*)
      INTO l_cnt
      FROM mantenimientos
     WHERE venta_linea_id = p_venta_linea_id
       AND estado = c_estado_vigente;

    IF l_cnt > 0 THEN
      raise_application_error(c_err_regla,
        'contratar: ya existe un mantenimiento VIGENTE para venta_linea_id='||p_venta_linea_id);
    END IF;

    l_ini  := TRUNC(NVL(p_fecha_inicio, SYSDATE));
    l_venc := calc_vencimiento(l_ini, p_duracion_meses);
    l_estado := estado_por_fechas(l_ini, l_venc, TRUNC(SYSDATE));

    l_id := seq_mantenimientos.NEXTVAL;

    INSERT INTO mantenimientos (
      mantenimiento_id, venta_id, venta_linea_id,
      fecha_inicio, fecha_vencimiento, estado,
      renovacion_de_id, comentario,
      created_at, created_by
    ) VALUES (
      l_id, l_venta_id, p_venta_linea_id,
      l_ini, l_venc, l_estado,
      NULL, p_comentario,
      SYSTIMESTAMP, pkg_auditoria.get_actor
    );

    pkg_auditoria.log_event(
      p_modulo     => pkg_auditoria.c_mod_mantenimientos,
      p_accion     => 'CONTRATAR',
      p_entidad    => 'MANTENIMIENTO',
      p_entidad_id => l_id,
      p_detalle    => 'Contratado para venta_linea_id='||p_venta_linea_id||
                      ' venc='||TO_CHAR(l_venc,'YYYY-MM-DD')
    );

    o_mantenimiento_id := l_id;

  EXCEPTION
    WHEN NO_DATA_FOUND THEN
      raise_application_error(c_err_notfound, 'contratar: producto no encontrado para la venta_linea');
  END contratar;


  ------------------------------------------------------------------------------
  -- Renovar: crea nuevo periodo, enlaza con anterior
  ------------------------------------------------------------------------------
  PROCEDURE renovar(
    p_mantenimiento_id_anterior IN NUMBER,
    p_fecha_inicio              IN DATE DEFAULT TRUNC(SYSDATE),
    p_duracion_meses            IN NUMBER DEFAULT 12,
    p_comentario                IN VARCHAR2,
    o_mantenimiento_id_nuevo    OUT NUMBER
  ) IS
    l_prev mantenimientos%ROWTYPE;
    l_venta_id NUMBER;
    l_producto_id NUMBER;
    l_estado_venta VARCHAR2(20);
    l_perm CHAR(1);

    l_id NUMBER;
    l_ini DATE;
    l_venc DATE;
    l_estado VARCHAR2(20);
  BEGIN
    IF p_mantenimiento_id_anterior IS NULL THEN
      raise_application_error(c_err_param, 'renovar: mantenimiento_id_anterior obligatorio');
    END IF;

    IF p_duracion_meses IS NULL OR p_duracion_meses <= 0 THEN
      raise_application_error(c_err_param, 'renovar: duracion_meses debe ser > 0');
    END IF;

    IF p_comentario IS NULL OR LENGTH(TRIM(p_comentario)) < 3 THEN
      raise_application_error(c_err_param, 'renovar: comentario obligatorio (mín. 3 caracteres)');
    END IF;

    SELECT *
      INTO l_prev
      FROM mantenimientos
     WHERE mantenimiento_id = p_mantenimiento_id_anterior;

    IF l_prev.estado = c_estado_anulado THEN
      raise_application_error(c_err_estado, 'renovar: no se puede renovar un mantenimiento ANULADO');
    END IF;

    -- Validar contexto (venta confirmada y producto permite mantenimiento)
    get_contexto_venta_linea(l_prev.venta_linea_id, l_venta_id, l_producto_id, l_estado_venta);

    IF l_estado_venta <> pkg_ventas.c_estado_confirmada THEN
      raise_application_error(c_err_estado,
        'renovar: la venta debe estar CONFIRMADA. venta_id='||l_venta_id||' estado='||l_estado_venta);
    END IF;

    SELECT permite_mantenimiento
      INTO l_perm
      FROM productos
     WHERE producto_id = l_producto_id;

    IF l_perm <> 'S' THEN
      raise_application_error(c_err_regla,
        'renovar: el producto no permite mantenimiento. producto_id='||l_producto_id);
    END IF;

    l_ini  := TRUNC(NVL(p_fecha_inicio, SYSDATE));
    l_venc := calc_vencimiento(l_ini, p_duracion_meses);
    l_estado := estado_por_fechas(l_ini, l_venc, TRUNC(SYSDATE));

    l_id := seq_mantenimientos.NEXTVAL;

    INSERT INTO mantenimientos (
      mantenimiento_id, venta_id, venta_linea_id,
      fecha_inicio, fecha_vencimiento, estado,
      renovacion_de_id, comentario,
      created_at, created_by
    ) VALUES (
      l_id, l_prev.venta_id, l_prev.venta_linea_id,
      l_ini, l_venc, l_estado,
      l_prev.mantenimiento_id, p_comentario,
      SYSTIMESTAMP, pkg_auditoria.get_actor
    );

    -- Opcional: si el anterior estaba VIGENTE, lo marcamos VENCIDO al renovar (política común)
    -- Si no quieres esto, quita este UPDATE.
    UPDATE mantenimientos
       SET estado     = c_estado_vencido,
           updated_at = SYSTIMESTAMP,
           updated_by = pkg_auditoria.get_actor
     WHERE mantenimiento_id = l_prev.mantenimiento_id
       AND estado = c_estado_vigente;

    pkg_auditoria.log_event(
      p_modulo     => pkg_auditoria.c_mod_mantenimientos,
      p_accion     => 'RENOVAR',
      p_entidad    => 'MANTENIMIENTO',
      p_entidad_id => l_id,
      p_detalle    => 'Renovación de mantenimiento_id='||l_prev.mantenimiento_id||
                      ' nuevo_venc='||TO_CHAR(l_venc,'YYYY-MM-DD')
    );

    o_mantenimiento_id_nuevo := l_id;

  EXCEPTION
    WHEN NO_DATA_FOUND THEN
      raise_application_error(c_err_notfound, 'renovar: mantenimiento anterior no encontrado');
  END renovar;


  ------------------------------------------------------------------------------
  -- Marcar vencidos (proceso batch)
  ------------------------------------------------------------------------------
  PROCEDURE marcar_vencidos(
    p_fecha_corte IN DATE DEFAULT TRUNC(SYSDATE)
  ) IS
    l_corte DATE := TRUNC(NVL(p_fecha_corte, SYSDATE));
    l_rows NUMBER;
  BEGIN
    UPDATE mantenimientos
       SET estado     = c_estado_vencido,
           updated_at = SYSTIMESTAMP,
           updated_by = pkg_auditoria.get_actor
     WHERE estado = c_estado_vigente
       AND TRUNC(fecha_vencimiento) < l_corte;

    l_rows := SQL%ROWCOUNT;

    pkg_auditoria.log_event(
      p_modulo     => pkg_auditoria.c_mod_mantenimientos,
      p_accion     => 'MARCAR_VENCIDOS',
      p_entidad    => 'MANTENIMIENTO',
      p_entidad_id => NULL,
      p_detalle    => 'Marcados como VENCIDO: '||l_rows||' registros (corte='||TO_CHAR(l_corte,'YYYY-MM-DD')||')'
    );
  END marcar_vencidos;

END pkg_mantenimientos;
/