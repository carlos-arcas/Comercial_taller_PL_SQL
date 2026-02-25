from collections.abc import Generator
import sys
from pathlib import Path

import pytest
from fastapi.testclient import TestClient

ROOT = Path(__file__).resolve().parents[1]
SRC = ROOT / "src"
if str(SRC) not in sys.path:
    sys.path.insert(0, str(SRC))

from app.db.pool import get_conn  # noqa: E402
from app.main import app  # noqa: E402


class DummyCursor:
    def __init__(self) -> None:
        self._row = (1,)

    def execute(self, _query: str, _params=None) -> None:  # type: ignore[no-untyped-def]
        return None

    def fetchone(self):  # type: ignore[no-untyped-def]
        return self._row

    def __enter__(self):  # type: ignore[no-untyped-def]
        return self

    def __exit__(self, exc_type, exc, tb) -> None:  # type: ignore[no-untyped-def]
        return None


class DummyConn:
    def cursor(self) -> DummyCursor:
        return DummyCursor()


def _dummy_conn_dependency() -> Generator[DummyConn, None, None]:
    yield DummyConn()


@pytest.fixture()
def client(monkeypatch: pytest.MonkeyPatch) -> Generator[TestClient, None, None]:
    monkeypatch.setattr("app.main.init_pool", lambda *_args, **_kwargs: None)
    monkeypatch.setattr("app.main.close_pool", lambda *_args, **_kwargs: None)

    app.dependency_overrides[get_conn] = _dummy_conn_dependency
    with TestClient(app) as test_client:
        yield test_client
    app.dependency_overrides.clear()
