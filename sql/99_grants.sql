-- ============================================================================
-- 99_grants.sql
-- Seguridad: acceso SOLO vía packages (no DML directo a tablas)
-- ============================================================================

-- ==============================
-- 1) Permisos sobre PACKAGES
-- ==============================

GRANT EXECUTE ON pkg_ventas         TO APP_USER;
GRANT EXECUTE ON pkg_alquileres     TO APP_USER;
GRANT EXECUTE ON pkg_mantenimientos TO APP_USER;
GRANT EXECUTE ON pkg_auditoria      TO APP_USER;


-- ==============================
-- 2) Permisos de lectura para BI
-- ==============================

GRANT SELECT ON vw_ventas_kpi       TO APP_USER;
GRANT SELECT ON vw_alquileres_kpi   TO APP_USER;
GRANT SELECT ON vw_mantenimientos_kpi TO APP_USER;


-- ==============================
-- 3) NO conceder DML sobre tablas
-- ==============================
-- (NO dar INSERT/UPDATE/DELETE sobre tablas de negocio)

-- Ejemplo: NO hacer esto:
-- GRANT INSERT, UPDATE, DELETE ON ventas TO APP_USER;
-- GRANT INSERT, UPDATE, DELETE ON ventas_lineas TO APP_USER;
-- GRANT INSERT, UPDATE, DELETE ON productos TO APP_USER;

-- ==============================
-- 4) Permitir uso de secuencias (si fueran necesarias)
-- ==============================

GRANT SELECT ON seq_ventas         TO APP_USER;
GRANT SELECT ON seq_ventas_lineas  TO APP_USER;

-- ============================================================================
-- FIN
-- ============================================================================