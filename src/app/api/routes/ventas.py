from fastapi import APIRouter, Depends
import oracledb

from app.api.schemas.ventas import ConfirmarVentaRequest, MessageResponse, VentaResponse
from app.services import ventas_service
from app.db.pool import get_conn

router = APIRouter(prefix="/ventas", tags=["ventas"])


@router.post("/confirmar", response_model=MessageResponse)
def confirmar_venta(
    body: ConfirmarVentaRequest,
    conn: oracledb.Connection = Depends(get_conn),
) -> MessageResponse:
    ventas_service.confirmar_venta(conn=conn, venta_id=body.venta_id, comentario=body.comentario)
    return MessageResponse(message=f"Venta {body.venta_id} confirmada")


@router.get("/{venta_id}", response_model=VentaResponse)
def obtener_venta(venta_id: int, conn: oracledb.Connection = Depends(get_conn)) -> VentaResponse:
    data = ventas_service.obtener_venta(conn=conn, venta_id=venta_id)
    return VentaResponse(**data)
