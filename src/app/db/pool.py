from collections.abc import Generator
from pathlib import Path

import oracledb

from app.core.config import Settings

pool: oracledb.ConnectionPool | None = None


class WalletConfigError(RuntimeError):
    """Raised when wallet files are missing or invalid."""


def _validate_wallet(wallet_path: Path) -> None:
    if not wallet_path.exists() or not wallet_path.is_dir():
        raise WalletConfigError(
            f"Wallet directory not found: {wallet_path}. Set WALLET_DIR to a valid path."
        )

    required_files = ["tnsnames.ora", "ewallet.pem"]
    missing = [name for name in required_files if not (wallet_path / name).exists()]
    if missing:
        missing_text = ", ".join(missing)
        raise WalletConfigError(
            f"Wallet is incomplete in {wallet_path}. Missing required file(s): {missing_text}."
        )


def init_pool(settings: Settings) -> None:
    global pool
    if pool is not None:
        return

    wallet_path = settings.wallet_path
    _validate_wallet(wallet_path)

    pool = oracledb.create_pool(
        user=settings.db_user,
        password=settings.db_password,
        dsn=settings.db_dsn,
        config_dir=str(wallet_path),
        wallet_location=str(wallet_path),
        min=settings.db_pool_min,
        max=settings.db_pool_max,
        increment=settings.db_pool_increment,
    )


def close_pool() -> None:
    global pool
    if pool is not None:
        pool.close()
        pool = None


def get_conn() -> Generator[oracledb.Connection, None, None]:
    if pool is None:
        raise RuntimeError("Oracle pool is not initialized")

    conn = pool.acquire()
    try:
        yield conn
    finally:
        pool.release(conn)
