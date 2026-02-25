import logging
import time

from fastapi import FastAPI, Request
from fastapi.responses import JSONResponse

from app.api.routes.health import router as health_router
from app.api.routes.version import router as version_router
from app.api.routes.ventas import router as ventas_router
from app.core.config import get_settings
from app.core.errors import register_exception_handlers
from app.core.logging import bind_request_id, setup_logging
from app.db.pool import WalletConfigError, close_pool, init_pool

settings = get_settings()
setup_logging()
logger = logging.getLogger(__name__)

app = FastAPI(title=settings.app_name)
register_exception_handlers(app)


@app.middleware("http")
async def request_context_middleware(request: Request, call_next):  # type: ignore[no-untyped-def]
    request_id = request.headers.get("X-Request-ID")
    bound_request_id = bind_request_id(request_id)
    start = time.perf_counter()

    response = await call_next(request)
    duration_ms = (time.perf_counter() - start) * 1000
    response.headers["X-Request-ID"] = bound_request_id

    logger.info(
        "%s %s status=%s duration_ms=%.2f",
        request.method,
        request.url.path,
        response.status_code,
        duration_ms,
    )
    return response


@app.on_event("startup")
def startup_event() -> None:
    try:
        init_pool(settings)
        logger.info("Oracle pool initialized successfully")
    except WalletConfigError as exc:
        logger.error("Wallet configuration error: %s", exc)
        raise


@app.on_event("shutdown")
def shutdown_event() -> None:
    close_pool()
    logger.info("Oracle pool closed")


@app.get("/")
def root() -> JSONResponse:
    return JSONResponse({"ok": True, "message": "Comercial API running"})


app.include_router(health_router)
app.include_router(version_router)
app.include_router(ventas_router)
