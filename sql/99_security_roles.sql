-- ============================================================================
-- 99_security_roles.sql
-- Seguridad basada en ROLE (modelo profesional)
-- ============================================================================

-- ==============================
-- 1) Crear ROLE de aplicación
-- ==============================

CREATE ROLE ROLE_APP_CORE;

-- ==============================
-- 2) Permisos sobre PACKAGES
-- ==============================

GRANT EXECUTE ON pkg_ventas         TO ROLE_APP_CORE;
GRANT EXECUTE ON pkg_alquileres     TO ROLE_APP_CORE;
GRANT EXECUTE ON pkg_mantenimientos TO ROLE_APP_CORE;
GRANT EXECUTE ON pkg_auditoria      TO ROLE_APP_CORE;

-- ==============================
-- 3) Permisos de lectura (BI)
-- ==============================

GRANT SELECT ON vw_ventas_kpi          TO ROLE_APP_CORE;
GRANT SELECT ON vw_alquileres_kpi      TO ROLE_APP_CORE;
GRANT SELECT ON vw_mantenimientos_kpi  TO ROLE_APP_CORE;

-- ==============================
-- 4) Secuencias (si fueran necesarias externamente)
-- ==============================

GRANT SELECT ON seq_ventas         TO ROLE_APP_CORE;
GRANT SELECT ON seq_ventas_lineas  TO ROLE_APP_CORE;

-- ==============================
-- 5) Asignar ROLE al usuario aplicación
-- ==============================

GRANT ROLE_APP_CORE TO APP_USER;

-- ============================================================================
-- IMPORTANTE:
-- NO conceder INSERT/UPDATE/DELETE directos sobre tablas de negocio
-- ============================================================================