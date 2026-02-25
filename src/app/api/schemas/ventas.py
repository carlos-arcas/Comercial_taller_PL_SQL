from pydantic import BaseModel, Field


class ConfirmarVentaRequest(BaseModel):
    venta_id: int = Field(gt=0)
    comentario: str = Field(min_length=1, max_length=500)


class VentaResponse(BaseModel):
    venta_id: int
    cliente: str
    total: float
    estado: str


class MessageResponse(BaseModel):
    ok: bool = True
    message: str
