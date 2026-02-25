import logging
import uuid
from contextvars import ContextVar

request_id_ctx_var: ContextVar[str] = ContextVar("request_id", default="-")


class RequestIdFilter(logging.Filter):
    def filter(self, record: logging.LogRecord) -> bool:
        record.request_id = request_id_ctx_var.get()
        return True


def setup_logging(level: int = logging.INFO) -> None:
    formatter = logging.Formatter(
        fmt="%(asctime)s | %(levelname)s | %(name)s | request_id=%(request_id)s | %(message)s"
    )
    handler = logging.StreamHandler()
    handler.setFormatter(formatter)
    handler.addFilter(RequestIdFilter())

    root_logger = logging.getLogger()
    root_logger.setLevel(level)
    root_logger.handlers.clear()
    root_logger.addHandler(handler)


def bind_request_id(request_id: str | None = None) -> str:
    rid = request_id or str(uuid.uuid4())
    request_id_ctx_var.set(rid)
    return rid
