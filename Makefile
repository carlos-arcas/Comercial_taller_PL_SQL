.PHONY: install install-dev run test lint format

install:
	pip install .

install-dev:
	pip install -e .[dev]

run:
	uvicorn app.main:app --host 0.0.0.0 --port 8000 --reload

test:
	pytest

lint:
	ruff check src tests

format:
	black src tests
