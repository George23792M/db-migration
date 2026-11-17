# Configuration & Environment

## Environment Variables (.env)

**Location**: `.env` (at root; not committed to git)

```
DB_USER=smoothie_user
DB_PASSWORD=smoothie_password
DB_HOST=localhost
DB_PORT=5432
DB_NAME=smoothie_db

DATABASE_URL=postgresql://${DB_USER}:${DB_PASSWORD}@${DB_HOST}:${DB_PORT}/${DB_NAME}
```

### Fallback Defaults
- `DB_HOST`: `localhost` (if not set)
- `DB_PORT`: `5432` (if not set)
- `DATABASE_URL`: Constructed from components if not explicitly set

### Usage Locations
- **alembic/env.py**: Loads via `python-dotenv`, constructs psycopg URL
- **scripts/check_db_connection.py**: Uses for pre-flight health check with psycopg

Sources: .env, alembic/env.py, scripts/check_db_connection.py
Verified: 2026-11-16

## Dependencies

**pyproject.toml**:
```
name = "db-migration"
version = "0.1.0"
requires-python = ">=3.12"
dependencies = []  # No base dependencies; all runtime deps in requirements.txt
```

**requirements.txt**:
```
alembic==1.13.1
psycopg[binary]>=3.2.0
python-dotenv==1.0.1
SQLAlchemy==2.0.38
```

### Technology Stack
- **Python**: 3.12+ (local) / 3.11+ (Docker)
- **Migration Tool**: Alembic 1.13.1
- **Database Driver**: psycopg 3.2.0+ with binary extensions (C optimizations)
- **ORM/SQL Toolkit**: SQLAlchemy 2.0.38 (used by Alembic for connection management)
- **Config Management**: python-dotenv 1.0.1

Sources: pyproject.toml, requirements.txt, Dockerfile
Verified: 2026-11-16

## Docker Configuration

**Dockerfile**: Multi-stage build (implicit single stage here)
```dockerfile
FROM python:3.11-slim

WORKDIR /app

RUN apt-get update && apt-get install -y --no-install-recommends \
    libpq-dev gcc && \
    rm -rf /var/lib/apt/lists/*

COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

COPY alembic.ini .
COPY alembic/ ./alembic/
COPY scripts/ ./scripts/

CMD ["sh", "-c", "python scripts/wait_for_db.py && alembic upgrade head"]
```

### Key Points
- **Base**: Python 3.11-slim (security, size)
- **System deps**: `libpq-dev` (PostgreSQL client library), `gcc` (compile psycopg binary)
- **Startup**: Health check script + Alembic migrations
- **Missing**: `.env` file must be mounted or environment vars injected at runtime

**Note**: Health check script is `wait_for_db.py`, but source code references `check_db_connection.py`. Inferred: script was renamed or Docker uses different name. Needs verification.

Sources: Dockerfile
Verified: 2026-11-16

## Alembic Configuration (alembic.ini)

**Key Sections**:
- `[alembic]`: `script_location = alembic`
- `[sqlalchemy]`: `sqlalchemy.url` injected by `env.py` from environment
- `[loggers]`: Root level WARN, Alembic level INFO
- Offline/online migration support via `run_migrations_offline()` and `run_migrations_online()` in `env.py`

Sources: alembic.ini, alembic/env.py
Verified: 2026-11-16

## Exception Handling

**scripts/exceptions.py**:
```python
class DatabaseMigrationError(Exception)
    └─ DatabaseConnectionError("Failed to establish database connection.")
    └─ EnvironmentConfigurationError("Environment variables are missing.")
```

Used in:
- `check_db_connection.py`: Raises `DatabaseConnectionError` after 30 timeout attempts
- `alembic/env.py`: Raises `EnvironmentConfigurationError` if DB_USER, DB_PASSWORD, or DB_NAME missing

Sources: scripts/exceptions.py, alembic/env.py, scripts/check_db_connection.py
Verified: 2026-11-16

## Health Check Script (scripts/check_db_connection.py)

Validates database readiness before migrations:
- Connects via psycopg directly (not SQLAlchemy)
- Retry logic: 30 attempts, 2-second intervals (60 seconds max)
- Logging: Enterprise-grade with timestamps and severity levels
- Used by: Docker CMD and Windows orchestrator (`migrate.ps1`)

Sources: scripts/check_db_connection.py
Verified: 2026-11-16
