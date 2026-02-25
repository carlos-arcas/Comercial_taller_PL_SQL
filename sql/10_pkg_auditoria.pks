-- === File: sql/10_pkg_auditoria.pks ===
CREATE OR REPLACE PACKAGE pkg_auditoria AS
  ------------------------------------------------------------------------------
  -- Auditoría centralizada (APEX-friendly)
  -- - Actor: v('APP_USER') si hay sesión APEX; si no, USER
  -- - Inserta en AUDITORIA_EVENTOS
  -- - Se recomienda usarlo desde TODOS los packages de negocio
  ------------------------------------------------------------------------------

  -- Constantes de módulos (recomendación)
  c_mod_ventas         CONSTANT VARCHAR2(60) := 'VENTAS';
  c_mod_alquileres     CONSTANT VARCHAR2(60) := 'ALQUILERES';
  c_mod_mantenimientos CONSTANT VARCHAR2(60) := 'MANTENIMIENTOS';
  c_mod_stock          CONSTANT VARCHAR2(60) := 'STOCK';
  c_mod_apex           CONSTANT VARCHAR2(60) := 'APEX';

  -- Devuelve actor (APEX APP_USER si existe, si no USER)
  FUNCTION get_actor RETURN VARCHAR2;

  -- Inserta un evento de auditoría
  PROCEDURE log_event(
    p_modulo     IN VARCHAR2,
    p_accion     IN VARCHAR2,
    p_entidad    IN VARCHAR2,
    p_entidad_id IN NUMBER   DEFAULT NULL,
    p_detalle    IN VARCHAR2 DEFAULT NULL,
    p_ip_origen  IN VARCHAR2 DEFAULT NULL
  );

END pkg_auditoria;
/