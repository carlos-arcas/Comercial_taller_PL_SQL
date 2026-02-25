-- === File: sql/31_pkg_alquileres.pkb ===
CREATE OR REPLACE PACKAGE BODY pkg_alquileres AS

  FUNCTION get_estado_alquiler(p_alquiler_id IN NUMBER) RETURN VARCHAR2 IS
    l_estado alquileres.estado%TYPE;
  BEGIN
    SELECT estado
      INTO l_estado
      FROM alquileres
     WHERE alquiler_id = p_alquiler_id;

    RETURN l_estado;
  EXCEPTION
    WHEN NO_DATA_FOUND THEN
      raise_application_error(c_err_notfound, 'Alquiler no encontrado: ' || p_alquiler_id);
  END get_estado_alquiler;


  FUNCTION gen_num_alquiler(p_alquiler_id IN NUMBER) RETURN VARCHAR2 IS
  BEGIN
    RETURN 'A-' || TO_CHAR(SYSDATE,'YYYYMM') || '-' || LPAD(p_alquiler_id, 6, '0');
  END gen_num_alquiler;


  PROCEDURE crear_alquiler(
    p_cliente_id    IN  NUMBER,
    p_comercial_id  IN  NUMBER,
    p_fecha_inicio  IN  DATE DEFAULT TRUNC(SYSDATE),
    p_fecha_fin     IN  DATE,
    p_observaciones IN  VARCHAR2 DEFAULT NULL,
    o_alquiler_id   OUT NUMBER
  ) IS
    l_id          NUMBER;
    l_num_alquiler alquileres.num_alquiler%TYPE;
    l_ini         DATE;
    l_fin         DATE;
  BEGIN
    IF p_cliente_id IS NULL OR p_comercial_id IS NULL OR p_fecha_fin IS NULL THEN
      raise_application_error(c_err_param, 'crear_alquiler: cliente_id, comercial_id y fecha_fin son obligatorios');
    END IF;

    l_ini := TRUNC(NVL(p_fecha_inicio, SYSDATE));
    l_fin := TRUNC(p_fecha_fin);

    IF l_fin < l_ini THEN
      raise_application_error(c_err_param, 'crear_alquiler: fecha_fin debe ser >= fecha_inicio');
    END IF;

    l_id := seq_alquileres.NEXTVAL;

    -- IMPORTANTE: calcular aquí para NO llamar a una función PL/SQL dentro del SQL
    l_num_alquiler := 'A-' || TO_CHAR(SYSDATE,'YYYYMM') || '-' || LPAD(l_id, 6, '0');

    INSERT INTO alquileres (
      alquiler_id, num_alquiler, fecha_inicio, fecha_fin,
      cliente_id, comercial_id, estado, moneda, total_estimado,
      observaciones, created_at, created_by
    ) VALUES (
      l_id, l_num_alquiler, l_ini, l_fin,
      p_cliente_id, p_comercial_id, c_estado_activo, 'EUR', 0,
      p_observaciones, SYSTIMESTAMP, pkg_auditoria.get_actor
    );

    pkg_auditoria.log_event(
      p_modulo     => pkg_auditoria.c_mod_alquileres,
      p_accion     => 'CREAR',
      p_entidad    => 'ALQUILER',
      p_entidad_id => l_id,
      p_detalle    => 'Alquiler creado en estado ACTIVO'
    );

    o_alquiler_id := l_id;
  END crear_alquiler;


  PROCEDURE reservar_stock_por_linea(p_producto_id IN NUMBER, p_cantidad IN NUMBER) IS
    l_total productos.stock_total%TYPE;
    l_res   productos.stock_reservado%TYPE;
    l_disp  NUMBER(12,2);
  BEGIN
    SELECT stock_total, stock_reservado
      INTO l_total, l_res
      FROM productos
     WHERE producto_id = p_producto_id
     FOR UPDATE;

    l_disp := l_total - l_res;

    IF p_cantidad > l_disp THEN
      raise_application_error(c_err_stock,
        'Disponibilidad insuficiente producto_id='||p_producto_id||
        ' disponible='||TO_CHAR(l_disp)||' solicitado='||TO_CHAR(p_cantidad));
    END IF;

    UPDATE productos
       SET stock_reservado = stock_reservado + p_cantidad,
           updated_at      = SYSTIMESTAMP,
           updated_by      = pkg_auditoria.get_actor
     WHERE producto_id = p_producto_id;
  END reservar_stock_por_linea;


  PROCEDURE liberar_stock_por_alquiler(p_alquiler_id IN NUMBER) IS
    CURSOR c_lin IS
      SELECT producto_id, cantidad
        FROM alquileres_lineas
       WHERE alquiler_id = p_alquiler_id
       ORDER BY linea_num;

    l_total productos.stock_total%TYPE;
    l_res   productos.stock_reservado%TYPE;
  BEGIN
    FOR r IN c_lin LOOP
      -- Bloqueo explícito para consistencia
      SELECT stock_total, stock_reservado
        INTO l_total, l_res
        FROM productos
       WHERE producto_id = r.producto_id
       FOR UPDATE;

      IF r.cantidad > l_res THEN
        -- Inconsistencia (no debería pasar). Lo paramos para no dejar negativo.
        raise_application_error(c_err_integridad,
          'Liberación inválida: producto_id='||r.producto_id||
          ' reservado='||TO_CHAR(l_res)||' a_liberar='||TO_CHAR(r.cantidad));
      END IF;

      UPDATE productos
         SET stock_reservado = stock_reservado - r.cantidad,
             updated_at      = SYSTIMESTAMP,
             updated_by      = pkg_auditoria.get_actor
       WHERE producto_id = r.producto_id;
    END LOOP;
  END liberar_stock_por_alquiler;


  PROCEDURE add_linea(
    p_alquiler_id        IN  NUMBER,
    p_producto_id        IN  NUMBER,
    p_cantidad           IN  NUMBER,
    p_precio_mensual     IN  NUMBER DEFAULT NULL,
    o_alquiler_linea_id  OUT NUMBER
  ) IS
    l_estado     VARCHAR2(20);
    l_linea_id   NUMBER;
    l_linea_num  NUMBER;
    l_precio_base productos.precio_alquiler_mensual%TYPE;
    l_precio     NUMBER(12,2);
    l_meses      NUMBER;
    l_importe    NUMBER(14,2);
    l_ini        DATE;
    l_fin        DATE;
  BEGIN
    IF p_alquiler_id IS NULL OR p_producto_id IS NULL OR p_cantidad IS NULL THEN
      raise_application_error(c_err_param, 'add_linea: alquiler_id, producto_id y cantidad son obligatorios');
    END IF;

    IF p_cantidad <= 0 THEN
      raise_application_error(c_err_param, 'add_linea: cantidad debe ser > 0');
    END IF;

    l_estado := get_estado_alquiler(p_alquiler_id);
    IF l_estado <> c_estado_activo THEN
      raise_application_error(c_err_estado, 'add_linea: solo permitido en ACTIVO. Estado actual='||l_estado);
    END IF;

    -- Fechas del alquiler para calcular meses estimados
    SELECT fecha_inicio, fecha_fin
      INTO l_ini, l_fin
      FROM alquileres
     WHERE alquiler_id = p_alquiler_id;

    -- Meses estimados (mínimo 1 mes)
    l_meses := GREATEST(1, CEIL(MONTHS_BETWEEN(l_fin, l_ini)));

    SELECT precio_alquiler_mensual
      INTO l_precio_base
      FROM productos
     WHERE producto_id = p_producto_id;

    l_precio  := NVL(p_precio_mensual, l_precio_base);
    l_importe := ROUND(l_precio * p_cantidad * l_meses, 2);

    -- Reservar disponibilidad (FOR UPDATE en productos)
    reservar_stock_por_linea(p_producto_id, p_cantidad);

    l_linea_id := seq_alquileres_lineas.NEXTVAL;

    SELECT NVL(MAX(linea_num),0) + 1
      INTO l_linea_num
      FROM alquileres_lineas
     WHERE alquiler_id = p_alquiler_id;

    INSERT INTO alquileres_lineas (
      alquiler_linea_id, alquiler_id, linea_num,
      producto_id, cantidad, precio_mensual, importe_estimado,
      created_at, created_by
    ) VALUES (
      l_linea_id, p_alquiler_id, l_linea_num,
      p_producto_id, p_cantidad, l_precio, l_importe,
      SYSTIMESTAMP, pkg_auditoria.get_actor
    );

    recalcular_totales(p_alquiler_id);

    pkg_auditoria.log_event(
      p_modulo     => pkg_auditoria.c_mod_alquileres,
      p_accion     => 'ADD_LINEA',
      p_entidad    => 'ALQUILER',
      p_entidad_id => p_alquiler_id,
      p_detalle    => 'Añadida línea '||l_linea_num||' (alquiler_linea_id='||l_linea_id||')'
    );

    o_alquiler_linea_id := l_linea_id;

  EXCEPTION
    WHEN NO_DATA_FOUND THEN
      raise_application_error(c_err_notfound, 'add_linea: producto o alquiler no encontrados');
  END add_linea;


  PROCEDURE recalcular_totales(p_alquiler_id IN NUMBER) IS
    l_total NUMBER(14,2);
  BEGIN
    SELECT NVL(SUM(importe_estimado),0)
      INTO l_total
      FROM alquileres_lineas
     WHERE alquiler_id = p_alquiler_id;

    UPDATE alquileres
       SET total_estimado = l_total,
           updated_at     = SYSTIMESTAMP,
           updated_by     = pkg_auditoria.get_actor
     WHERE alquiler_id = p_alquiler_id;
  END recalcular_totales;


  PROCEDURE cerrar_alquiler(
    p_alquiler_id IN NUMBER,
    p_comentario  IN VARCHAR2
  ) IS
    l_estado VARCHAR2(20);
  BEGIN
    IF p_alquiler_id IS NULL THEN
      raise_application_error(c_err_param, 'cerrar_alquiler: alquiler_id obligatorio');
    END IF;

    IF p_comentario IS NULL OR LENGTH(TRIM(p_comentario)) < 3 THEN
      raise_application_error(c_err_param, 'cerrar_alquiler: comentario obligatorio (mín. 3 caracteres)');
    END IF;

    l_estado := get_estado_alquiler(p_alquiler_id);

    IF l_estado <> c_estado_activo THEN
      raise_application_error(c_err_estado, 'cerrar_alquiler: solo desde ACTIVO. Estado='||l_estado);
    END IF;

    -- Liberar reservas
    liberar_stock_por_alquiler(p_alquiler_id);

    UPDATE alquileres
       SET estado     = c_estado_finalizado,
           updated_at = SYSTIMESTAMP,
           updated_by = pkg_auditoria.get_actor
     WHERE alquiler_id = p_alquiler_id;

    pkg_auditoria.log_event(
      p_modulo     => pkg_auditoria.c_mod_alquileres,
      p_accion     => 'CERRAR',
      p_entidad    => 'ALQUILER',
      p_entidad_id => p_alquiler_id,
      p_detalle    => 'Finalizado. Comentario: '||SUBSTR(p_comentario,1,400)
    );
  END cerrar_alquiler;


  PROCEDURE anular_alquiler(
    p_alquiler_id IN NUMBER,
    p_comentario  IN VARCHAR2
  ) IS
    l_estado VARCHAR2(20);
  BEGIN
    IF p_alquiler_id IS NULL THEN
      raise_application_error(c_err_param, 'anular_alquiler: alquiler_id obligatorio');
    END IF;

    IF p_comentario IS NULL OR LENGTH(TRIM(p_comentario)) < 3 THEN
      raise_application_error(c_err_param, 'anular_alquiler: comentario obligatorio (mín. 3 caracteres)');
    END IF;

    l_estado := get_estado_alquiler(p_alquiler_id);

    IF l_estado = c_estado_anulado THEN
      raise_application_error(c_err_estado, 'anular_alquiler: ya está ANULADO');
    END IF;

    IF l_estado <> c_estado_activo THEN
      raise_application_error(c_err_estado, 'anular_alquiler: solo desde ACTIVO. Estado='||l_estado);
    END IF;

    -- Liberar reservas
    liberar_stock_por_alquiler(p_alquiler_id);

    UPDATE alquileres
       SET estado     = c_estado_anulado,
           updated_at = SYSTIMESTAMP,
           updated_by = pkg_auditoria.get_actor
     WHERE alquiler_id = p_alquiler_id;

    pkg_auditoria.log_event(
      p_modulo     => pkg_auditoria.c_mod_alquileres,
      p_accion     => 'ANULAR',
      p_entidad    => 'ALQUILER',
      p_entidad_id => p_alquiler_id,
      p_detalle    => 'Anulado. Comentario: '||SUBSTR(p_comentario,1,400)
    );
  END anular_alquiler;

END pkg_alquileres;
/