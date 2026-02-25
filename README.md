# Comercial API (FastAPI + Oracle Autonomous Database Wallet mTLS)

Proyecto backend profesional con FastAPI y `python-oracledb` (thin mode), preparado para conectarse a Oracle Autonomous Database usando wallet mTLS (`tnsnames.ora` + `ewallet.pem`) y pool global de conexiones.

## Características

- FastAPI con estructura `src/` por capas.
- Pool global de Oracle inicializado en startup.
- Wallet mTLS validado al arranque.
- Endpoints:
  - `GET /health` → ejecuta `select 1 from dual`.
  - `GET /version` → metadata de la app.
  - `POST /ventas/confirmar` → ejemplo PL/SQL (`pkg_ventas.confirmar_venta`).
  - `GET /ventas/{venta_id}` → query ejemplo para obtener una venta.
- Manejo de errores consistente JSON (`400/404/500`).
- Logging estructurado mínimo con `request_id`.
- Tests mínimos con pytest para `/health` ejecutables sin Oracle real (mock).
- Dockerfile, Makefile y script `.bat` para Windows.

## Estructura

```text
.
├─ src/app/
│  ├─ api/
│  │  ├─ routes/
│  │  │  ├─ health.py
│  │  │  ├─ version.py
│  │  │  └─ ventas.py
│  │  └─ schemas/ventas.py
│  ├─ core/
│  │  ├─ config.py
│  │  ├─ errors.py
│  │  └─ logging.py
│  ├─ db/pool.py
│  ├─ services/ventas_service.py
│  └─ main.py
├─ tests/
├─ Dockerfile
├─ Makefile
├─ .env.example
└─ pyproject.toml
```

## Requisitos

- Python 3.11+
- Wallet de Oracle Autonomous Database descargado desde OCI

## Configuración de wallet (obligatorio)

1. Descarga el Wallet ZIP desde Oracle Cloud (Autonomous DB).
2. Descomprime el zip en `./wallet` (no commitear).
3. Verifica que existan al menos:
   - `wallet/tnsnames.ora`
   - `wallet/ewallet.pem`
4. Configura variables de entorno:
   - `DB_USER` (ejemplo: `COMERCIAL`)
   - `DB_PASSWORD` (nunca hardcodeado)
   - `DB_DSN` (alias en `tnsnames.ora`, ejemplo: `comtaller_high`)
   - `WALLET_DIR` (por defecto `./wallet`)

> El arranque valida wallet y falla con error claro si falta `WALLET_DIR` o `tnsnames.ora`/`ewallet.pem`.

## Variables de entorno

Copia `.env.example` a `.env` y completa:

```bash
cp .env.example .env
```

Campos clave:

- `APP_ENV=local`
- `DB_USER=COMERCIAL`
- `DB_PASSWORD=...`
- `DB_DSN=comtaller_high`
- `WALLET_DIR=./wallet`

## Instalación y ejecución local

```bash
python -m venv .venv
source .venv/bin/activate  # Windows: .venv\Scripts\activate
pip install -e .[dev]
make run
```

También en Windows:

```bat
scripts\run_dev.bat
```

Servidor en: `http://localhost:8000`
Docs: `http://localhost:8000/docs`

## Endpoints

### `GET /health`
Ejecuta `select 1 from dual`.

### `GET /version`
Retorna nombre, ambiente y commit placeholder.

### `POST /ventas/confirmar`
Body:

```json
{
  "venta_id": 123,
  "comentario": "Confirmación manual"
}
```

Internamente:

```plsql
pkg_ventas.confirmar_venta(:venta_id, :comentario)
```

### `GET /ventas/{venta_id}`
Usa query ejemplo sobre tabla/vista `ventas`. Si tu objeto real difiere (por ejemplo `vw_ventas`), cámbialo en `src/app/services/ventas_service.py`.

## Tests

Ejecutar tests unitarios (sin Oracle real):

```bash
make test
```

Los tests mockean la dependencia de conexión.

Para pruebas de integración reales, setea wallet y variables Oracle válidas y ejecuta endpoints manualmente o agrega tests específicos de integración según tu entorno.

## Docker

Construcción:

```bash
docker build -t comercial-api:local .
```

Ejecución (montando wallet local):

```bash
docker run --rm -p 8000:8000 \
  -e DB_USER=COMERCIAL \
  -e DB_PASSWORD='***' \
  -e DB_DSN=comtaller_high \
  -e WALLET_DIR=/app/wallet \
  -v $(pwd)/wallet:/app/wallet:ro \
  comercial-api:local
```

> Nunca incluyas el wallet real dentro de la imagen ni en git.

## Calidad de código (opcional)

```bash
make lint
make format
```

Si usas pre-commit:

```bash
pip install pre-commit
pre-commit install
```
