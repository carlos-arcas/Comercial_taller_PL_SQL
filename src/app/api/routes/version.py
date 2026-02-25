from fastapi import APIRouter

from app.core.config import get_settings

router = APIRouter(tags=["version"])


@router.get("/version")
def version() -> dict[str, str]:
    settings = get_settings()
    return {
        "name": settings.app_name,
        "env": settings.app_env,
        "commit": settings.app_commit,
    }
