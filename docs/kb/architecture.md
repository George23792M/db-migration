# Architecture

## High-Level Design
Standalone PostgreSQL schema management service using version-controlled SQL scripts wrapped in Alembic Python revisions. Supports immutable versioning, enterprise rollback, and pgvector extensions for AI-generated recipe embeddings.

```
┌─────────────────────────────────────────────────────────┐
│                   Orchestration Layer                   │
│         (migrate.ps1 or docker CMD)                     │
└────────────────────┬────────────────────────────────────┘
                     │
        ┌────────────┴────────────┐
        │                         │
   ┌────▼─────┐          ┌────────▼────────┐
   │ Health   │          │  Alembic Upgrade│
   │  Check   │          │  (env.py +      │
   │ Script   │          │   revisions)    │
   └────┬─────┘          └────────┬────────┘
        │                         │
        └────────────┬────────────┘
                     │
        ┌────────────▼────────────┐
        │  PostgreSQL Database    │
        │  (customers, recipes,   │
        │   workflows, etc.)      │
        └─────────────────────────┘
```

## Component Layers

### 1. Orchestration Layer
**Purpose**: Coordination and health assurance
- **Windows**: `migrate.ps1` – PowerShell orchestrator
  - Cleans up lingering processes
  - Runs health check → migration in sequence
  - Provides colored status feedback
- **Docker**: `Dockerfile` CMD – Health check + Alembic
  - Ensures DB is ready before migrations
  - Single-purpose container

### 2. Health Check Layer
**Purpose**: Pre-flight validation, retry logic
- **Script**: `scripts/check_db_connection.py`
- **Driver**: psycopg (direct connection, no ORM)
- **Logic**: Retry up to 30 times with 2-second intervals
- **Exit Codes**: 0 (success) / 1 (timeout or config error)

### 3. Configuration Layer
**Purpose**: Environment management, secrets
- **Source**: `.env` file (local) / environment vars (Docker)
- **Components**: 
  - `DB_USER`, `DB_PASSWORD`, `DB_HOST`, `DB_PORT`, `DB_NAME`
  - `DATABASE_URL` (optional, inferred if not set)
- **Validation**: `alembic/env.py` raises `EnvironmentConfigurationError` if required vars missing
- **Used by**: Alembic connection, health check script

### 4. Migration Layer (Alembic)
**Purpose**: Version control and execution of schema changes
- **Config**: `alembic.ini` + `alembic/env.py`
- **Revisions**: `alembic/versions/` (Python wrapper files)
- **SQL Scripts**: `alembic/sql/` (raw DDL/DML)
- **Connection**: SQLAlchemy engine (online mode) or dry-run (offline mode)
- **Pattern**: Each Python revision reads corresponding `_up.sql` or `_down.sql`, executes via `op.execute()`

### 5. Database Layer
**Purpose**: Schema persistence
- **Engine**: PostgreSQL 3.11+ (Docker) / 3.12+ (local)
- **Driver**: psycopg 3.2.0+ (with binary)
- **Extensions**: pgvector (for vector embeddings)
- **Tables**: 8 core tables (customers, recipes, workflows, etc.)
- **Indexes**: 15+ indexes for performance (HNSW, B-tree, partial)

## Data Flow: Migration Execution

```
1. User/CI runs: alembic upgrade head  (or .\migrate.ps1)
                      │
2. Orchestrator (if Windows):
   - Kill lingering processes
   - Run health check script
                      │
3. Health Check Script:
   - Connect to PostgreSQL (retry × 30)
   - Raise EnvironmentConfigurationError if config missing
   - Raise DatabaseConnectionError if timeout
   - Exit code 0 (success) or 1 (failure)
                      │
4. Alembic:
   - Load alembic.ini
   - Execute env.py:
     • Load .env
     • Validate DB_USER, DB_PASSWORD, DB_NAME
     • Build psycopg URL
     • Inject into config
   - Query alembic_version table (created by Alembic if missing)
   - For each pending revision (in order):
     • Load Python revision file (e.g., 0f2b2c3f7ff5)
     • Execute upgrade():
       - Open V001__initial_core_schema_up.sql
       - op.execute(sql_content)
     • Insert revision hash into alembic_version
   - Repeat until upgrade head reached
                      │
5. Result:
   - Database schema updated
   - alembic_version table shows applied revisions
   - Exit code 0 (success) or 1 (failure)
```

## Design Patterns

### 1. Immutable Versioning (Golden Rule)
- Never modify applied migrations
- Always create new revision for fixes (alembic revision -m "fix_...")
- Prevents out-of-sync issues across environments

**Enforcement**: Convention + documentation (not code-enforced)

Sources: README.md
Verified: 2026-11-16

### 2. Separation of Concerns: SQL & Python
- **Python**: Orchestration and Alembic integration
- **SQL**: Business logic (DDL/DML)
- **Benefit**: DBA-friendly SQL, version control of raw scripts, easier review

**Implementation**: 
- Python revision reads SQL file at runtime
- SQL files committed to git alongside Python
- Both versioned with same hash prefix

Sources: alembic/versions/, alembic/sql/
Verified: 2026-11-16

### 3. Health Check Before Migration
- Prevents partial migrations due to connectivity
- Retry logic handles temporary network issues
- Atomic success/failure (exit code)

**Implementation**: 
- `check_db_connection.py` runs before Alembic
- Powers both CLI (migrate.ps1) and Docker

Sources: scripts/check_db_connection.py, migrate.ps1, Dockerfile
Verified: 2026-11-16

### 4. Environment-Driven Configuration
- No hardcoded DB credentials
- Supports local, staging, production via .env or environment vars
- Alembic config injected at runtime

**Implementation**: 
- Load .env → construct URL → inject into config
- Fallback defaults for host/port
- Validation with custom exceptions

Sources: alembic/env.py, scripts/check_db_connection.py
Verified: 2026-11-16

## Deployment Strategies

### Local Development
1. `python -m venv venv && source venv/bin/activate`
2. `pip install -r requirements.txt`
3. `cp .env .env` (adjust values)
4. `python scripts/check_db_connection.py`
5. `alembic upgrade head` (or `.\migrate.ps1` on Windows)

### Docker
1. Build: `docker build -t smoothie-db-migration .`
2. Run: `docker run -e DB_USER=... -e DB_PASSWORD=... -e DB_HOST=postgres -e DB_PORT=5432 -e DB_NAME=smoothie_db smoothie-db-migration`
   - Or mount `.env` file: `-v /path/to/.env:/app/.env`

### CI/CD Pipeline
- Trigger: `alembic upgrade head` after PostgreSQL container is ready
- Health check handles startup timing issues
- Exit code 0/1 for pass/fail reporting

Sources: Dockerfile, migrate.ps1
Verified: 2026-11-16
