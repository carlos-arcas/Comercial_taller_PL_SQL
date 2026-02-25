import logging

from fastapi import APIRouter, Depends
import oracledb

from app.db.pool import get_conn

router = APIRouter(tags=["health"])
logger = logging.getLogger(__name__)


@router.get("/health")
def health(conn: oracledb.Connection = Depends(get_conn)) -> dict[str, object]:
    with conn.cursor() as cur:
        cur.execute("select 1 from dual")
        value = cur.fetchone()

    ok = bool(value and value[0] == 1)
    logger.info("Health check executed")
    return {"ok": ok, "db": "up" if ok else "down"}
