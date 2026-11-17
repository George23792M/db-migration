# Migration Workflow & Alembic Setup

## Alembic Configuration
- **Script location**: `alembic/`
- **Config file**: `alembic.ini`
- **SQLAlchemy URL source**: Loaded from environment in `alembic/env.py`
- **Migration versions**: `alembic/versions/`
- **Raw SQL scripts**: `alembic/sql/`

### Environment Setup (alembic/env.py)
Implements online and offline migration modes:
1. Loads `.env` file via `python-dotenv`
2. Constructs database URL from components:
   - `DB_USER`, `DB_PASSWORD`, `DB_HOST` (default: localhost), `DB_PORT` (default: 5432), `DB_NAME`
   - Format: `postgresql+psycopg://{user}:{password}@{host}:{port}/{db_name}`
3. Injects URL into Alembic config
4. Runs migrations via `run_migrations_online()` (default for Docker/server) or `run_migrations_offline()` (SQL preview mode)
5. Uses `NullPool` to avoid connection pooling issues in short-lived processes

Sources: alembic/env.py
Verified: 2026-11-16

## Migration Revisions

### Revision 1: 0f2b2c3f7ff5 (creating_initial_smoothie_tables)
**Date**: 2026-11-06 08:55:39
**Revises**: None (initial)
**SQL Files**: 
- Up: `V001__initial_core_schema_up.sql` (creates 7 tables + pgvector extension)
- Down: `V001__initial_core_schema_down.sql` (drops all in order, CASCADE)
**Purpose**: Create core Smoothie AI schema with customers, preferences, recipes, quotes, workflows, subscriptions, pgvector for embeddings.

Sources: alembic/versions/0f2b2c3f7ff5_creating_initial_smoothie_tables.py
Verified: 2026-11-16

### Revision 2: 00484a8120a9 (create_email_table)
**Date**: 2026-11-06 10:04:13
**Revises**: 0f2b2c3f7ff5
**SQL Files**: 
- Up: `V002__create_email.sql` (creates email_templates table)
- Down: Empty (no downgrade logic implemented)
**Purpose**: Add email template management for campaigns.
**Note**: No downgrade implemented; this is a limitation documented in `learnings.md`.

Sources: alembic/versions/00484a8120a9_create_email_table.py
Verified: 2026-11-16

### Revision 3: 3fa985e2456d (alter_schema_index_smoothie_tables)
**Date**: 2026-11-06 11:32:41
**Revises**: 00484a8120a9
**SQL Files**: 
- Up: `V001__initial_core_alter_indexes_up.sql` (adds indexes and constraints to workflow_runs, recipe_history, customer_preferences)
- Down: Empty (no downgrade logic implemented)
**Purpose**: Performance enhancements and data integrity constraints (unique indexes, partial indexes for active rows, workflow claiming).
**Note**: Naming convention issue: file named `V001__...` but applied as 3rd revision (should be `V003__...`).

Sources: alembic/versions/3fa985e2456d_alter_schema_index_smoothie_tables.py
Verified: 2026-11-16

## Workflow Pattern (from README.md)

### Step 1: Generate Revision
```
alembic revision -m "description_of_change"
```
Creates new Python file in `alembic/versions/` with unique hash prefix.

### Step 2: Write SQL Files
Create matching `_up.sql` and `_down.sql` files in `alembic/sql/` with exact revision hash prefix.
- `_up.sql`: Forward migration (CREATE, ALTER, INSERT)
- `_down.sql`: Rollback (DROP, DELETE)

### Step 3: Link SQL to Python
Edit the generated Python revision file:
```python
def upgrade() -> None:
    sql_path = os.path.join(os.path.dirname(__file__), '../sql/V00X__description_up.sql')
    with open(sql_path, 'r', encoding='utf-8') as f:
        op.execute(f.read())

def downgrade() -> None:
    sql_path = os.path.join(os.path.dirname(__file__), '../sql/V00X__description_down.sql')
    with open(sql_path, 'r', encoding='utf-8') as f:
        op.execute(f.read())
```

### Step 4: Execute & Validate
Run via PowerShell orchestrator or directly:
```
.\migrate.ps1
# or
alembic upgrade head
```

Sources: README.md, migrate.ps1
Verified: 2026-11-16

## Orchestration (migrate.ps1)

Windows PowerShell script with three phases:
1. **Cleanup**: Kill lingering Python migration processes
2. **Health Check**: Run `scripts/check_db_connection.py` (up to 30 retries × 2s)
3. **Migrate**: Execute `alembic upgrade head`
4. **Status**: Report success or failure with colored output

Error handling: Exit with code 1 if any phase fails; prevents partial migrations.

Sources: migrate.ps1
Verified: 2026-11-16

## Migration Commands

| Command | Purpose |
|---------|---------|
| `alembic revision -m "description"` | Generate new revision |
| `alembic upgrade head` | Apply all pending migrations |
| `alembic downgrade -1` | Rollback one migration |
| `alembic history` | Show migration chain |
| `alembic current` | Show current applied revision |
| `.\migrate.ps1` | Windows orchestrator (health check + upgrade) |

Sources: alembic CLI documentation (inferred from usage patterns)
Verified: 2026-11-16
