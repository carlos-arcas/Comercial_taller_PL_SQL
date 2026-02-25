from typing import Any

import oracledb

from app.core.errors import NotFoundError


def confirmar_venta(conn: oracledb.Connection, venta_id: int, comentario: str) -> None:
    with conn.cursor() as cur:
        cur.callproc("pkg_ventas.confirmar_venta", [venta_id, comentario])
    conn.commit()


def obtener_venta(conn: oracledb.Connection, venta_id: int) -> dict[str, Any]:
    # Ajusta esta query a tu objeto real (tabla o vista), por ejemplo: vw_ventas o ventas.
    query = """
        SELECT
            v.venta_id,
            v.cliente_nombre,
            v.total,
            v.estado
        FROM ventas v
        WHERE v.venta_id = :venta_id
    """
    with conn.cursor() as cur:
        cur.execute(query, {"venta_id": venta_id})
        row = cur.fetchone()

    if not row:
        raise NotFoundError(f"Venta {venta_id} no encontrada")

    return {
        "venta_id": int(row[0]),
        "cliente": str(row[1]),
        "total": float(row[2]),
        "estado": str(row[3]),
    }
