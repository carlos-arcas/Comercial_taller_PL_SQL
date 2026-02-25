from http import HTTPStatus

from fastapi import FastAPI, Request
from fastapi.responses import JSONResponse


class AppError(Exception):
    def __init__(self, status_code: int, code: str, message: str) -> None:
        self.status_code = status_code
        self.code = code
        self.message = message
        super().__init__(message)


class NotFoundError(AppError):
    def __init__(self, message: str = "Resource not found") -> None:
        super().__init__(HTTPStatus.NOT_FOUND, "not_found", message)


class BadRequestError(AppError):
    def __init__(self, message: str = "Invalid request") -> None:
        super().__init__(HTTPStatus.BAD_REQUEST, "bad_request", message)


def register_exception_handlers(app: FastAPI) -> None:
    @app.exception_handler(AppError)
    async def app_error_handler(_: Request, exc: AppError) -> JSONResponse:
        return JSONResponse(
            status_code=exc.status_code,
            content={"ok": False, "error": {"code": exc.code, "message": exc.message}},
        )

    @app.exception_handler(Exception)
    async def generic_error_handler(_: Request, exc: Exception) -> JSONResponse:
        return JSONResponse(
            status_code=HTTPStatus.INTERNAL_SERVER_ERROR,
            content={
                "ok": False,
                "error": {"code": "internal_error", "message": "Unexpected server error"},
            },
        )
