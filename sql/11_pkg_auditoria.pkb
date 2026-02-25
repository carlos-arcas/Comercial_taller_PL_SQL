-- === File: sql/11_pkg_auditoria.pkb ===
CREATE OR REPLACE PACKAGE BODY pkg_auditoria AS

  ------------------------------------------------------------------------------
  -- Devuelve el actor:
  -- 1) Si estamos en sesión APEX -> v('APP_USER')
  -- 2) Si no -> USER
  ------------------------------------------------------------------------------
  FUNCTION get_actor RETURN VARCHAR2 IS
    l_actor VARCHAR2(128);
  BEGIN
    BEGIN
      -- Intentamos obtener APP_USER (solo funciona en sesión APEX)
      l_actor := NVL(v('APP_USER'), USER);
    EXCEPTION
      WHEN OTHERS THEN
        l_actor := USER;
    END;

    RETURN l_actor;
  END get_actor;


  ------------------------------------------------------------------------------
  -- Inserta evento de auditoría
  ------------------------------------------------------------------------------
  PROCEDURE log_event(
    p_modulo     IN VARCHAR2,
    p_accion     IN VARCHAR2,
    p_entidad    IN VARCHAR2,
    p_entidad_id IN NUMBER   DEFAULT NULL,
    p_detalle    IN VARCHAR2 DEFAULT NULL,
    p_ip_origen  IN VARCHAR2 DEFAULT NULL
  ) IS
    l_evento_id NUMBER;
    l_actor     VARCHAR2(128);
  BEGIN
    IF p_modulo IS NULL OR p_accion IS NULL OR p_entidad IS NULL THEN
      raise_application_error(-20001, 
        'pkg_auditoria.log_event: modulo, accion y entidad son obligatorios');
    END IF;

    l_evento_id := seq_auditoria_eventos.NEXTVAL;
    l_actor     := get_actor;

    INSERT INTO auditoria_eventos (
      evento_id,
      fecha_evento,
      actor,
      modulo,
      accion,
      entidad,
      entidad_id,
      detalle,
      ip_origen,
      created_at
    ) VALUES (
      l_evento_id,
      SYSTIMESTAMP,
      l_actor,
      p_modulo,
      p_accion,
      p_entidad,
      p_entidad_id,
      SUBSTR(p_detalle,1,2000),
      p_ip_origen,
      SYSTIMESTAMP
    );

  EXCEPTION
    WHEN OTHERS THEN
      -- Error crítico: la auditoría no puede fallar silenciosamente
      raise_application_error(-20002,
        'Error en pkg_auditoria.log_event: ' || SQLERRM);
  END log_event;

END pkg_auditoria;
/