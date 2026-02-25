-- === File: sql/21_pkg_ventas.pkb ===
CREATE OR REPLACE PACKAGE BODY pkg_ventas AS

  ------------------------------------------------------------------------------
  -- Util: valida que exista una venta y devuelve estado actual (para consultas)
  -- NOTA: NO bloquea la fila. Para operaciones críticas usa SELECT ... FOR UPDATE.
  ------------------------------------------------------------------------------
  FUNCTION get_estado_venta(p_venta_id IN NUMBER) RETURN VARCHAR2 IS
    l_estado ventas.estado%TYPE;
  BEGIN
    SELECT estado
      INTO l_estado
      FROM ventas
     WHERE venta_id = p_venta_id;

    RETURN l_estado;
  EXCEPTION
    WHEN NO_DATA_FOUND THEN
      raise_application_error(c_err_notfound, 'Venta no encontrada: ' || p_venta_id);
  END get_estado_venta;


  ------------------------------------------------------------------------------
  -- Util: genera num_venta legible (V-YYYYMM-000001)
  ------------------------------------------------------------------------------
  FUNCTION gen_num_venta(p_venta_id IN NUMBER) RETURN VARCHAR2 IS
  BEGIN
    RETURN 'V-' || TO_CHAR(SYSDATE,'YYYYMM') || '-' || LPAD(p_venta_id, 6, '0');
  END gen_num_venta;


  ------------------------------------------------------------------------------
  -- Crea venta BORRADOR
  ------------------------------------------------------------------------------
  PROCEDURE crear_venta(
    p_cliente_id    IN  NUMBER,
    p_comercial_id  IN  NUMBER,
    p_fecha_venta   IN  DATE DEFAULT TRUNC(SYSDATE),
    p_observaciones IN  VARCHAR2 DEFAULT NULL,
    o_venta_id      OUT NUMBER
  ) IS
    l_venta_id  NUMBER;
    l_num_venta ventas.num_venta%TYPE;
  BEGIN
    IF p_cliente_id IS NULL OR p_comercial_id IS NULL THEN
      raise_application_error(c_err_param, 'crear_venta: cliente_id y comercial_id son obligatorios');
    END IF;

    l_venta_id := seq_ventas.NEXTVAL;

    -- IMPORTANTe: calcular en PL/SQL (no usar gen_num_venta() dentro del INSERT)
    l_num_venta := gen_num_venta(l_venta_id);

    INSERT INTO ventas (
      venta_id, num_venta, fecha_venta, cliente_id, comercial_id,
      estado, moneda, total_importe, observaciones,
      created_at, created_by
    ) VALUES (
      l_venta_id, l_num_venta, TRUNC(NVL(p_fecha_venta, SYSDATE)),
      p_cliente_id, p_comercial_id,
      c_estado_borrador, 'EUR', 0, p_observaciones,
      SYSTIMESTAMP, pkg_auditoria.get_actor
    );

    pkg_auditoria.log_event(
      p_modulo     => pkg_auditoria.c_mod_ventas,
      p_accion     => 'CREAR',
      p_entidad    => 'VENTA',
      p_entidad_id => l_venta_id,
      p_detalle    => 'Venta creada en estado BORRADOR'
    );

    o_venta_id := l_venta_id;
  END crear_venta;


  ------------------------------------------------------------------------------
  -- Añade línea (solo si BORRADOR)
  ------------------------------------------------------------------------------
  PROCEDURE add_linea(
    p_venta_id         IN  NUMBER,
    p_producto_id      IN  NUMBER,
    p_cantidad         IN  NUMBER,
    p_precio_unitario  IN  NUMBER DEFAULT NULL,
    o_venta_linea_id   OUT NUMBER
  ) IS
    l_estado      VARCHAR2(20);
    l_linea_id    NUMBER;
    l_linea_num   NUMBER;
    l_precio      NUMBER(12,2);
    l_importe     NUMBER(14,2);
    l_precio_base productos.precio_venta%TYPE;
  BEGIN
    IF p_venta_id IS NULL OR p_producto_id IS NULL OR p_cantidad IS NULL THEN
      raise_application_error(c_err_param, 'add_linea: venta_id, producto_id y cantidad son obligatorios');
    END IF;

    IF p_cantidad <= 0 THEN
      raise_application_error(c_err_param, 'add_linea: cantidad debe ser > 0');
    END IF;

    l_estado := get_estado_venta(p_venta_id);
    IF l_estado <> c_estado_borrador THEN
      raise_application_error(c_err_estado, 'add_linea: solo permitido en BORRADOR. Estado actual='||l_estado);
    END IF;

    -- Precio: si no viene, usar precio_venta del producto
    SELECT precio_venta
      INTO l_precio_base
      FROM productos
     WHERE producto_id = p_producto_id;

    l_precio  := NVL(p_precio_unitario, l_precio_base);
    l_importe := ROUND(l_precio * p_cantidad, 2);

    l_linea_id := seq_ventas_lineas.NEXTVAL;

    SELECT NVL(MAX(linea_num),0) + 1
      INTO l_linea_num
      FROM ventas_lineas
     WHERE venta_id = p_venta_id;

    INSERT INTO ventas_lineas (
      venta_linea_id, venta_id, linea_num,
      producto_id, cantidad, precio_unitario, importe_linea,
      created_at, created_by
    ) VALUES (
      l_linea_id, p_venta_id, l_linea_num,
      p_producto_id, p_cantidad, l_precio, l_importe,
      SYSTIMESTAMP, pkg_auditoria.get_actor
    );

    recalcular_totales(p_venta_id);

    pkg_auditoria.log_event(
      p_modulo     => pkg_auditoria.c_mod_ventas,
      p_accion     => 'ADD_LINEA',
      p_entidad    => 'VENTA',
      p_entidad_id => p_venta_id,
      p_detalle    => 'Añadida línea '||l_linea_num||' (venta_linea_id='||l_linea_id||')'
    );

    o_venta_linea_id := l_linea_id;

  EXCEPTION
    WHEN NO_DATA_FOUND THEN
      raise_application_error(c_err_notfound, 'add_linea: producto o venta no encontrados');
  END add_linea;


  ------------------------------------------------------------------------------
  -- Recalcular total de cabecera
  ------------------------------------------------------------------------------
  PROCEDURE recalcular_totales(p_venta_id IN NUMBER) IS
    l_total NUMBER(14,2);
  BEGIN
    SELECT NVL(SUM(importe_linea),0)
      INTO l_total
      FROM ventas_lineas
     WHERE venta_id = p_venta_id;

    UPDATE ventas
       SET total_importe = l_total,
           updated_at    = SYSTIMESTAMP,
           updated_by    = pkg_auditoria.get_actor
     WHERE venta_id = p_venta_id;
  END recalcular_totales;


  ------------------------------------------------------------------------------
  -- Descuenta stock_total por cada línea (FOR UPDATE)
  ------------------------------------------------------------------------------
  PROCEDURE descontar_stock_por_venta(p_venta_id IN NUMBER) IS
    CURSOR c_lin IS
      SELECT producto_id, cantidad
        FROM ventas_lineas
       WHERE venta_id = p_venta_id
       ORDER BY linea_num;

    l_stock_total     productos.stock_total%TYPE;
    l_stock_reservado productos.stock_reservado%TYPE;
    l_disponible      NUMBER(12,2);
  BEGIN
    FOR r IN c_lin LOOP
      -- Bloqueo pesimista del producto para concurrencia
      SELECT stock_total, stock_reservado
        INTO l_stock_total, l_stock_reservado
        FROM productos
       WHERE producto_id = r.producto_id
       FOR UPDATE;

      l_disponible := l_stock_total - l_stock_reservado;

      IF r.cantidad > l_disponible THEN
        raise_application_error(c_err_stock,
          'Stock insuficiente producto_id='||r.producto_id||
          ' disponible='||TO_CHAR(l_disponible)||' solicitado='||TO_CHAR(r.cantidad));
      END IF;

      UPDATE productos
         SET stock_total = stock_total - r.cantidad,
             updated_at  = SYSTIMESTAMP,
             updated_by  = pkg_auditoria.get_actor
       WHERE producto_id = r.producto_id;
    END LOOP;
  END descontar_stock_por_venta;


  ------------------------------------------------------------------------------
  -- Revierte stock_total por cada línea
  ------------------------------------------------------------------------------
  PROCEDURE revertir_stock_por_venta(p_venta_id IN NUMBER) IS
    CURSOR c_lin IS
      SELECT producto_id, cantidad
        FROM ventas_lineas
       WHERE venta_id = p_venta_id
       ORDER BY linea_num;
  BEGIN
    FOR r IN c_lin LOOP
      -- UPDATE bloquea fila (bloqueo implícito)
      UPDATE productos
         SET stock_total = stock_total + r.cantidad,
             updated_at  = SYSTIMESTAMP,
             updated_by  = pkg_auditoria.get_actor
       WHERE producto_id = r.producto_id;
    END LOOP;
  END revertir_stock_por_venta;


  ------------------------------------------------------------------------------
  -- Confirma venta: valida y descuenta stock (con bloqueo FOR UPDATE en VENTAS)
  ------------------------------------------------------------------------------
  PROCEDURE confirmar_venta(
    p_venta_id   IN NUMBER,
    p_comentario IN VARCHAR2
  ) IS
    l_estado VARCHAR2(20);
    l_cnt    NUMBER;
  BEGIN
    IF p_venta_id IS NULL THEN
      raise_application_error(c_err_param, 'confirmar_venta: venta_id obligatorio');
    END IF;

    IF p_comentario IS NULL OR LENGTH(TRIM(p_comentario)) < 3 THEN
      raise_application_error(c_err_param, 'confirmar_venta: comentario obligatorio (mín. 3 caracteres)');
    END IF;

    -- 1) BLOQUEO PESSIMISTA DE LA VENTA (evita doble confirmación simultánea)
    SELECT estado
      INTO l_estado
      FROM ventas
     WHERE venta_id = p_venta_id
       FOR UPDATE;

    IF l_estado <> c_estado_borrador THEN
      raise_application_error(c_err_estado, 'confirmar_venta: solo desde BORRADOR. Estado='||l_estado);
    END IF;

    SELECT COUNT(*)
      INTO l_cnt
      FROM ventas_lineas
     WHERE venta_id = p_venta_id;

    IF l_cnt = 0 THEN
      raise_application_error(c_err_integridad, 'confirmar_venta: la venta no tiene líneas');
    END IF;

    -- Recalcular total antes de confirmar
    recalcular_totales(p_venta_id);

    -- Descontar stock (con FOR UPDATE por producto)
    descontar_stock_por_venta(p_venta_id);

    -- Cambiar estado
    UPDATE ventas
       SET estado     = c_estado_confirmada,
           updated_at = SYSTIMESTAMP,
           updated_by = pkg_auditoria.get_actor
     WHERE venta_id = p_venta_id;

    pkg_auditoria.log_event(
      p_modulo     => pkg_auditoria.c_mod_ventas,
      p_accion     => 'CONFIRMAR',
      p_entidad    => 'VENTA',
      p_entidad_id => p_venta_id,
      p_detalle    => 'Confirmada. Comentario: '||SUBSTR(p_comentario,1,400)
    );

  EXCEPTION
    WHEN NO_DATA_FOUND THEN
      raise_application_error(c_err_notfound, 'confirmar_venta: venta no encontrada: '||p_venta_id);
  END confirmar_venta;


  ------------------------------------------------------------------------------
  -- Anula venta: requiere comentario; revierte stock si estaba confirmada
  -- (con bloqueo FOR UPDATE en VENTAS para evitar carreras)
  ------------------------------------------------------------------------------
  PROCEDURE anular_venta(
    p_venta_id   IN NUMBER,
    p_comentario IN VARCHAR2
  ) IS
    l_estado VARCHAR2(20);
  BEGIN
    IF p_venta_id IS NULL THEN
      raise_application_error(c_err_param, 'anular_venta: venta_id obligatorio');
    END IF;

    IF p_comentario IS NULL OR LENGTH(TRIM(p_comentario)) < 3 THEN
      raise_application_error(c_err_param, 'anular_venta: comentario obligatorio (mín. 3 caracteres)');
    END IF;

    -- 1) BLOQUEO PESSIMISTA DE LA VENTA (evita anulación/confirmación simultánea)
    SELECT estado
      INTO l_estado
      FROM ventas
     WHERE venta_id = p_venta_id
       FOR UPDATE;

    IF l_estado = c_estado_anulada THEN
      raise_application_error(c_err_estado, 'anular_venta: ya está ANULADA');
    END IF;

    -- Si estaba confirmada, revertir stock
    IF l_estado = c_estado_confirmada THEN
      revertir_stock_por_venta(p_venta_id);
    ELSIF l_estado <> c_estado_borrador THEN
      raise_application_error(c_err_estado, 'anular_venta: estado inválido para anular: '||l_estado);
    END IF;

    UPDATE ventas
       SET estado     = c_estado_anulada,
           updated_at = SYSTIMESTAMP,
           updated_by = pkg_auditoria.get_actor
     WHERE venta_id = p_venta_id;

    pkg_auditoria.log_event(
      p_modulo     => pkg_auditoria.c_mod_ventas,
      p_accion     => 'ANULAR',
      p_entidad    => 'VENTA',
      p_entidad_id => p_venta_id,
      p_detalle    => 'Anulada. Comentario: '||SUBSTR(p_comentario,1,400)
    );

  EXCEPTION
    WHEN NO_DATA_FOUND THEN
      raise_application_error(c_err_notfound, 'anular_venta: venta no encontrada: '||p_venta_id);
  END anular_venta;


END pkg_ventas;
/