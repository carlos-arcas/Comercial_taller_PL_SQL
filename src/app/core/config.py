from functools import lru_cache
from pathlib import Path

from pydantic import Field
from pydantic_settings import BaseSettings, SettingsConfigDict


class Settings(BaseSettings):
    model_config = SettingsConfigDict(env_file=".env", env_file_encoding="utf-8", extra="ignore")

    app_name: str = Field(default="Comercial API", alias="APP_NAME")
    app_env: str = Field(default="local", alias="APP_ENV")
    app_host: str = Field(default="0.0.0.0", alias="APP_HOST")
    app_port: int = Field(default=8000, alias="APP_PORT")
    app_commit: str = Field(default="dev", alias="APP_COMMIT")

    db_user: str = Field(default="COMERCIAL", alias="DB_USER")
    db_password: str = Field(default="", alias="DB_PASSWORD")
    db_dsn: str = Field(default="comtaller_high", alias="DB_DSN")
    wallet_dir: str = Field(default="./wallet", alias="WALLET_DIR")
    db_pool_min: int = Field(default=1, alias="DB_POOL_MIN")
    db_pool_max: int = Field(default=5, alias="DB_POOL_MAX")
    db_pool_increment: int = Field(default=1, alias="DB_POOL_INCREMENT")

    @property
    def wallet_path(self) -> Path:
        return Path(self.wallet_dir).resolve()


@lru_cache
def get_settings() -> Settings:
    return Settings()
