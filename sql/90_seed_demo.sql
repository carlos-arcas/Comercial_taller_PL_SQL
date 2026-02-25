-- === File: sql/90_seed_demo.sql ===
-- Seed demo ampliado (sin errores) - ejecuta sobre esquema vacío o recién creado.
-- Requiere: 01/02/03 + packages + 50_views_bi.sql

SET DEFINE OFF;

--------------------------------------------------------------------------------
-- 0) Limpieza opcional (si quieres re-ejecutar el seed)
--    OJO: respeta el orden por FKs
--------------------------------------------------------------------------------
BEGIN
  EXECUTE IMMEDIATE 'TRUNCATE TABLE auditoria_eventos';
  EXECUTE IMMEDIATE 'TRUNCATE TABLE mantenimientos';
  EXECUTE IMMEDIATE 'TRUNCATE TABLE alquileres_lineas';
  EXECUTE IMMEDIATE 'TRUNCATE TABLE alquileres';
  EXECUTE IMMEDIATE 'TRUNCATE TABLE ventas_lineas';
  EXECUTE IMMEDIATE 'TRUNCATE TABLE ventas';
  EXECUTE IMMEDIATE 'TRUNCATE TABLE comerciales';
  EXECUTE IMMEDIATE 'TRUNCATE TABLE personal';
  EXECUTE IMMEDIATE 'TRUNCATE TABLE clientes';
  EXECUTE IMMEDIATE 'TRUNCATE TABLE productos';
EXCEPTION
  WHEN OTHERS THEN
    NULL; -- Si es primera ejecución, no pasa nada
END;
/

--------------------------------------------------------------------------------
-- 1) Personal + Comerciales
--------------------------------------------------------------------------------
DECLARE
  v_id NUMBER;
BEGIN
  v_id := seq_personal.NEXTVAL;
  INSERT INTO personal (personal_id, dni_nif, nombre, apellidos, email, telefono, fecha_alta, activo)
  VALUES (v_id, '12345678A', 'Laura', 'Santos Vega', 'laura.santos@demo.com', '600111222', TRUNC(SYSDATE)-700, 'S');
  INSERT INTO comerciales (comercial_id, codigo_comercial, zona, objetivo_mensual)
  VALUES (v_id, 'COM-001', 'Sevilla', 15000);

  v_id := seq_personal.NEXTVAL;
  INSERT INTO personal (personal_id, dni_nif, nombre, apellidos, email, telefono, fecha_alta, activo)
  VALUES (v_id, '23456789B', 'Miguel', 'Romero Diaz', 'miguel.romero@demo.com', '600333444', TRUNC(SYSDATE)-650, 'S');
  INSERT INTO comerciales (comercial_id, codigo_comercial, zona, objetivo_mensual)
  VALUES (v_id, 'COM-002', 'Huelva', 12000);

  v_id := seq_personal.NEXTVAL;
  INSERT INTO personal (personal_id, dni_nif, nombre, apellidos, email, telefono, fecha_alta, activo)
  VALUES (v_id, '34567890C', 'Sara', 'Navarro Gil', 'sara.navarro@demo.com', '600555666', TRUNC(SYSDATE)-500, 'S');
  INSERT INTO comerciales (comercial_id, codigo_comercial, zona, objetivo_mensual)
  VALUES (v_id, 'COM-003', 'Cádiz', 13000);

  v_id := seq_personal.NEXTVAL;
  INSERT INTO personal (personal_id, dni_nif, nombre, apellidos, email, telefono, fecha_alta, activo)
  VALUES (v_id, '45678901D', 'Pablo', 'Iglesias Mora', 'pablo.iglesias@demo.com', '600777888', TRUNC(SYSDATE)-420, 'S');
  INSERT INTO comerciales (comercial_id, codigo_comercial, zona, objetivo_mensual)
  VALUES (v_id, 'COM-004', 'Córdoba', 11000);

  COMMIT;
END;
/

--------------------------------------------------------------------------------
-- 2) Clientes (10)
--------------------------------------------------------------------------------
BEGIN
  INSERT INTO clientes (cliente_id, cif_nif, razon_social, nombre_contacto, email, telefono, direccion, ciudad, provincia, cp, pais, fecha_alta, activo)
  VALUES (seq_clientes.NEXTVAL, 'B90000001', 'Talleres MotorSur S.L.', 'Antonio Ruiz', 'contacto@motorsur.com', '955111222','C/ Industria 12','Sevilla','Sevilla','41001','España',TRUNC(SYSDATE)-900,'S');

  INSERT INTO clientes VALUES (seq_clientes.NEXTVAL, 'B90000002', 'Neumáticos La Rueda S.L.', 'Carmen Lopez', 'info@larueda.com', '959333444',
                              'Av. Taller 5','Huelva','Huelva','21001','España',TRUNC(SYSDATE)-600,'S',
                              SYSTIMESTAMP, USER, NULL, NULL);

  INSERT INTO clientes (cliente_id, cif_nif, razon_social, nombre_contacto, email, telefono, direccion, ciudad, provincia, cp, pais, fecha_alta, activo)
  VALUES (seq_clientes.NEXTVAL, 'B90000003', 'ElectroAuto Norte S.L.', 'Javier Martin', 'ventas@electroauto.com', '954777888',
          'Polígono Norte 3','Sevilla','Sevilla','41015','España',TRUNC(SYSDATE)-520,'S');

  INSERT INTO clientes (cliente_id, cif_nif, razon_social, nombre_contacto, email, telefono, direccion, ciudad, provincia, cp, pais, fecha_alta, activo)
  VALUES (seq_clientes.NEXTVAL, 'B90000004', 'Chapa y Pintura Triana S.L.', 'Lucía Pérez', 'hola@triana-cyp.com', '954111999',
          'C/ Alfarería 20','Sevilla','Sevilla','41010','España',TRUNC(SYSDATE)-450,'S');

  INSERT INTO clientes (cliente_id, cif_nif, razon_social, nombre_contacto, email, telefono, direccion, ciudad, provincia, cp, pais, fecha_alta, activo)
  VALUES (seq_clientes.NEXTVAL, 'B90000005', 'Talleres Bahía S.L.', 'Iván Torres', 'info@talleresbahia.com', '956222333',
          'Av. Bahía 8','Cádiz','Cádiz','11011','España',TRUNC(SYSDATE)-430,'S');

  INSERT INTO clientes (cliente_id, cif_nif, razon_social, nombre_contacto, email, telefono, direccion, ciudad, provincia, cp, pais, fecha_alta, activo)
  VALUES (seq_clientes.NEXTVAL, 'B90000006', 'AutoService Córdoba S.L.', 'María León', 'contacto@autoservicecordoba.com', '957444555',
          'C/ Mezquita 1','Córdoba','Córdoba','14001','España',TRUNC(SYSDATE)-410,'S');

  INSERT INTO clientes (cliente_id, cif_nif, razon_social, nombre_contacto, email, telefono, direccion, ciudad, provincia, cp, pais, fecha_alta, activo)
  VALUES (seq_clientes.NEXTVAL, 'B90000007', 'Frenos y Embragues Sur S.L.', 'Diego Ramos', 'ventas@frenossur.com', '955666777',
          'C/ Motor 33','Dos Hermanas','Sevilla','41701','España',TRUNC(SYSDATE)-380,'S');

  INSERT INTO clientes (cliente_id, cif_nif, razon_social, nombre_contacto, email, telefono, direccion, ciudad, provincia, cp, pais, fecha_alta, activo)
  VALUES (seq_clientes.NEXTVAL, 'B90000008', 'Taller Rápido Centro S.L.', 'Noelia Blanco', 'hola@taller-rapido.com', '954222333',
          'Av. Centro 14','Sevilla','Sevilla','41002','España',TRUNC(SYSDATE)-360,'S');

  INSERT INTO clientes (cliente_id, cif_nif, razon_social, nombre_contacto, email, telefono, direccion, ciudad, provincia, cp, pais, fecha_alta, activo)
  VALUES (seq_clientes.NEXTVAL, 'B90000009', 'Talleres Sierra Norte S.L.', 'Rafael Cano', 'info@sierranorte.com', '955888999',
          'Ctra. Sierra km 2','Guillena','Sevilla','41210','España',TRUNC(SYSDATE)-340,'S');

  INSERT INTO clientes (cliente_id, cif_nif, razon_social, nombre_contacto, email, telefono, direccion, ciudad, provincia, cp, pais, fecha_alta, activo)
  VALUES (seq_clientes.NEXTVAL, 'B90000010', 'Diagnóstico Elite S.L.', 'Beatriz Solís', 'contacto@diagnosticoelite.com', '956999111',
          'C/ Electrónica 9','Jerez','Cádiz','11401','España',TRUNC(SYSDATE)-320,'S');

  COMMIT;
END;
/

--------------------------------------------------------------------------------
-- 3) Productos (12) con stock amplio para ventas+alquileres
--------------------------------------------------------------------------------
BEGIN
  INSERT INTO productos (producto_id, ref_producto, nombre, categoria, unidad_medida, stock_total, stock_reservado, precio_venta, precio_alquiler_mensual, permite_mantenimiento, activo)
  VALUES (seq_productos.NEXTVAL,'P-LLAVE-001','Llave dinamométrica 40-200Nm','Herramienta','ud',60,0,180,25,'S','S');

  INSERT INTO productos (producto_id, ref_producto, nombre, categoria, unidad_medida, stock_total, stock_reservado, precio_venta, precio_alquiler_mensual, permite_mantenimiento, activo)
  VALUES (seq_productos.NEXTVAL,'P-ELEV-002','Elevador hidráulico 2T','Maquinaria','ud',20,0,1250,160,'S','S');

  INSERT INTO productos (producto_id, ref_producto, nombre, categoria, unidad_medida, stock_total, stock_reservado, precio_venta, precio_alquiler_mensual, permite_mantenimiento, activo)
  VALUES (seq_productos.NEXTVAL,'P-DIAG-003','Equipo diagnosis OBD Pro','Electrónica','ud',50,0,520,70,'S','S');

  INSERT INTO productos (producto_id, ref_producto, nombre, categoria, unidad_medida, stock_total, stock_reservado, precio_venta, precio_alquiler_mensual, permite_mantenimiento, activo)
  VALUES (seq_productos.NEXTVAL,'P-CONS-004','Consumible limpieza inyectores (pack)','Consumible','pack',400,0,18,5,'N','S');

  INSERT INTO productos (producto_id, ref_producto, nombre, categoria, unidad_medida, stock_total, stock_reservado, precio_venta, precio_alquiler_mensual, permite_mantenimiento, activo)
  VALUES (seq_productos.NEXTVAL,'P-COMP-005','Compresor 50L profesional','Maquinaria','ud',25,0,390,55,'S','S');

  INSERT INTO productos (producto_id, ref_producto, nombre, categoria, unidad_medida, stock_total, stock_reservado, precio_venta, precio_alquiler_mensual, permite_mantenimiento, activo)
  VALUES (seq_productos.NEXTVAL,'P-GATO-006','Gato hidráulico 3T','Herramienta','ud',80,0,95,14,'S','S');

  INSERT INTO productos (producto_id, ref_producto, nombre, categoria, unidad_medida, stock_total, stock_reservado, precio_venta, precio_alquiler_mensual, permite_mantenimiento, activo)
  VALUES (seq_productos.NEXTVAL,'P-LAMP-007','Lámpara inspección LED','Herramienta','ud',200,0,22,4,'N','S');

  INSERT INTO productos (producto_id, ref_producto, nombre, categoria, unidad_medida, stock_total, stock_reservado, precio_venta, precio_alquiler_mensual, permite_mantenimiento, activo)
  VALUES (seq_productos.NEXTVAL,'P-NEUM-008','Equilibradora de ruedas','Maquinaria','ud',10,0,2100,260,'S','S');

  INSERT INTO productos (producto_id, ref_producto, nombre, categoria, unidad_medida, stock_total, stock_reservado, precio_venta, precio_alquiler_mensual, permite_mantenimiento, activo)
  VALUES (seq_productos.NEXTVAL,'P-CHAP-009','Soldador inverter 200A','Maquinaria','ud',18,0,480,65,'S','S');

  INSERT INTO productos (producto_id, ref_producto, nombre, categoria, unidad_medida, stock_total, stock_reservado, precio_venta, precio_alquiler_mensual, permite_mantenimiento, activo)
  VALUES (seq_productos.NEXTVAL,'P-EPI-010','Guantes nitrilo (caja 100)','Consumible','caja',800,0,9,2,'N','S');

  INSERT INTO productos (producto_id, ref_producto, nombre, categoria, unidad_medida, stock_total, stock_reservado, precio_venta, precio_alquiler_mensual, permite_mantenimiento, activo)
  VALUES (seq_productos.NEXTVAL,'P-FREN-011','Kit purgado frenos','Herramienta','ud',70,0,140,20,'S','S');

  INSERT INTO productos (producto_id, ref_producto, nombre, categoria, unidad_medida, stock_total, stock_reservado, precio_venta, precio_alquiler_mensual, permite_mantenimiento, activo)
  VALUES (seq_productos.NEXTVAL,'P-CARG-012','Cargador baterías inteligente','Electrónica','ud',90,0,120,18,'S','S');

  COMMIT;
END;
/

--------------------------------------------------------------------------------
-- 4) Generación masiva “controlada” usando packages
--    - 6 meses de actividad
--    - Ventas: ~60 (con algunas anuladas)
--    - Alquileres: ~30 (mix activo/finalizado/anulado)
--    - Mantenimientos: contratados + renovaciones + vencidos
--------------------------------------------------------------------------------
DECLARE
  TYPE t_numlist IS TABLE OF NUMBER;

  l_clientes   t_numlist := t_numlist();
  l_comerciales t_numlist := t_numlist();
  l_productos  t_numlist := t_numlist();

  -- Iteración
  i PLS_INTEGER;

  -- Temporales
  v_venta_id NUMBER;
  v_line_id  NUMBER;
  v_alq_id   NUMBER;
  v_alq_line_id NUMBER;

  v_cli NUMBER;
  v_com NUMBER;
  v_prod1 NUMBER;
  v_prod2 NUMBER;

  v_fecha DATE;
  v_mes_offset NUMBER;

  -- Para mantenimientos
  v_vl_mant NUMBER;
  v_mant_id NUMBER;
  v_mant_nuevo NUMBER;

  FUNCTION pick(p_list t_numlist) RETURN NUMBER IS
  BEGIN
    RETURN p_list(TRUNC(DBMS_RANDOM.VALUE(1, p_list.COUNT+1)));
  END;

  FUNCTION pick_qty(p_min NUMBER, p_max NUMBER) RETURN NUMBER IS
  BEGIN
    RETURN TRUNC(DBMS_RANDOM.VALUE(p_min, p_max+1));
  END;

BEGIN
  DBMS_RANDOM.SEED(42);

  SELECT cliente_id BULK COLLECT INTO l_clientes FROM clientes WHERE activo='S';
  SELECT comercial_id BULK COLLECT INTO l_comerciales FROM comerciales;
  SELECT producto_id BULK COLLECT INTO l_productos FROM productos WHERE activo='S';

  ------------------------------------------------------------------------------
  -- 4.1 Ventas (60)
  ------------------------------------------------------------------------------
  FOR i IN 1..60 LOOP
    v_cli := pick(l_clientes);
    v_com := pick(l_comerciales);

    -- Distribuimos en últimos 6 meses (0..-5)
    v_mes_offset := -TRUNC(DBMS_RANDOM.VALUE(0, 6));
    v_fecha := TRUNC(ADD_MONTHS(SYSDATE, v_mes_offset)) - TRUNC(DBMS_RANDOM.VALUE(0, 25));

    pkg_ventas.crear_venta(v_cli, v_com, v_fecha, 'Seed venta #'||i, v_venta_id);

    -- 1 a 3 líneas por venta
    v_prod1 := pick(l_productos);
    pkg_ventas.add_linea(v_venta_id, v_prod1, pick_qty(1, 5), NULL, v_line_id);

    IF DBMS_RANDOM.VALUE(0,1) < 0.65 THEN
      v_prod2 := pick(l_productos);
      IF v_prod2 != v_prod1 THEN
        pkg_ventas.add_linea(v_venta_id, v_prod2, pick_qty(1, 10), NULL, v_line_id);
      END IF;
    END IF;

    IF DBMS_RANDOM.VALUE(0,1) < 0.25 THEN
      v_prod2 := pick(l_productos);
      IF v_prod2 != v_prod1 THEN
        pkg_ventas.add_linea(v_venta_id, v_prod2, pick_qty(1, 3), NULL, v_line_id);
      END IF;
    END IF;

    -- Confirmar la mayoría; anular un pequeño %
    BEGIN
      pkg_ventas.confirmar_venta(v_venta_id, 'Seed confirmación venta #'||i);
      IF DBMS_RANDOM.VALUE(0,1) < 0.08 THEN
        pkg_ventas.anular_venta(v_venta_id, 'Seed anulación (error cliente) #'||i);
      END IF;
    EXCEPTION
      WHEN OTHERS THEN
        -- Si alguna venta falla por stock (muy improbable por stocks altos), la anulamos como borrador
        BEGIN
          pkg_ventas.anular_venta(v_venta_id, 'Seed anulación por error/stock #'||i);
        EXCEPTION
          WHEN OTHERS THEN NULL;
        END;
    END;
  END LOOP;

  ------------------------------------------------------------------------------
  -- 4.2 Alquileres (30)
  ------------------------------------------------------------------------------
  FOR i IN 1..30 LOOP
    v_cli := pick(l_clientes);
    v_com := pick(l_comerciales);

    v_mes_offset := -TRUNC(DBMS_RANDOM.VALUE(0, 6));
    v_fecha := TRUNC(ADD_MONTHS(SYSDATE, v_mes_offset)) - TRUNC(DBMS_RANDOM.VALUE(0, 15));

    -- Duración 15..90 días
    DECLARE
      v_ini DATE := v_fecha;
      v_fin DATE := v_fecha + TRUNC(DBMS_RANDOM.VALUE(15, 91));
      v_estado_target NUMBER := DBMS_RANDOM.VALUE(0,1);
      v_prod NUMBER;
    BEGIN
      pkg_alquileres.crear_alquiler(v_cli, v_com, v_ini, v_fin, 'Seed alquiler #'||i, v_alq_id);

      -- 1-2 líneas
      v_prod := pick(l_productos);
      pkg_alquileres.add_linea(v_alq_id, v_prod, pick_qty(1, 2), NULL, v_alq_line_id);

      IF DBMS_RANDOM.VALUE(0,1) < 0.4 THEN
        v_prod2 := pick(l_productos);
        IF v_prod2 != v_prod THEN
          pkg_alquileres.add_linea(v_alq_id, v_prod2, pick_qty(1, 2), NULL, v_alq_line_id);
        END IF;
      END IF;

      -- Estados: ~50% finalizados (si son antiguos), ~10% anulados, resto activos
      IF v_fin < TRUNC(SYSDATE) AND v_estado_target < 0.55 THEN
        pkg_alquileres.cerrar_alquiler(v_alq_id, 'Seed cierre alquiler #'||i);
      ELSIF v_estado_target < 0.10 THEN
        pkg_alquileres.anular_alquiler(v_alq_id, 'Seed anulación alquiler #'||i);
      ELSE
        NULL; -- ACTIVO
      END IF;

    EXCEPTION
      WHEN OTHERS THEN
        -- Si falla por disponibilidad, lo anulamos
        BEGIN
          pkg_alquileres.anular_alquiler(v_alq_id, 'Seed anulación por disponibilidad #'||i);
        EXCEPTION
          WHEN OTHERS THEN NULL;
        END;
    END;
  END LOOP;

  ------------------------------------------------------------------------------
  -- 4.3 Mantenimientos:
  --     - Contratamos para ~25 ventas_lineas de productos que permitan mantenimiento
  --     - Creamos algunos vencidos y renovamos parte de ellos
  ------------------------------------------------------------------------------
  FOR i IN 1..25 LOOP
    -- Elegimos una línea de una venta confirmada con producto que permite mantenimiento
    BEGIN
      SELECT vl.venta_linea_id
        INTO v_vl_mant
        FROM ventas_lineas vl
        JOIN ventas v ON v.venta_id = vl.venta_id
        JOIN productos p ON p.producto_id = vl.producto_id
       WHERE v.estado = 'CONFIRMADA'
         AND p.permite_mantenimiento = 'S'
       ORDER BY DBMS_RANDOM.VALUE
       FETCH FIRST 1 ROWS ONLY;

      -- 40% vencidos (inicio hace 18 meses), resto vigentes (inicio hace 1-4 meses)
      IF DBMS_RANDOM.VALUE(0,1) < 0.40 THEN
        pkg_mantenimientos.contratar(
          p_venta_linea_id   => v_vl_mant,
          p_fecha_inicio     => ADD_MONTHS(TRUNC(SYSDATE), -18),
          p_duracion_meses   => 12,
          p_comentario       => 'Seed mantenimiento antiguo #'||i,
          o_mantenimiento_id => v_mant_id
        );
        -- Renovamos ~60% de los vencidos
        IF DBMS_RANDOM.VALUE(0,1) < 0.60 THEN
          pkg_mantenimientos.renovar(
            p_mantenimiento_id_anterior => v_mant_id,
            p_fecha_inicio              => TRUNC(SYSDATE),
            p_duracion_meses            => 12,
            p_comentario                => 'Seed renovación #'||i,
            o_mantenimiento_id_nuevo    => v_mant_nuevo
          );
        END IF;
      ELSE
        pkg_mantenimientos.contratar(
          p_venta_linea_id   => v_vl_mant,
          p_fecha_inicio     => ADD_MONTHS(TRUNC(SYSDATE), -TRUNC(DBMS_RANDOM.VALUE(1, 5))),
          p_duracion_meses   => 12,
          p_comentario       => 'Seed mantenimiento vigente #'||i,
          o_mantenimiento_id => v_mant_id
        );
      END IF;
    EXCEPTION
      WHEN OTHERS THEN
        NULL; -- Si la regla evita duplicados vigentes, simplemente seguimos
    END;
  END LOOP;

  pkg_mantenimientos.marcar_vencidos(TRUNC(SYSDATE));

  COMMIT;
END;
/
-- Fin 90_seed_demo.sql