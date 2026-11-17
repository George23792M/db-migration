# db-migration – Quick Reference Card

## What It Does
Manages PostgreSQL schema changes for Smoothie AI Generator using **Alembic** + **raw SQL** + **immutable versioning**.

## Project Stats
- **8 tables**: customers, preferences, recipes (with AI embeddings), workflows, subscriptions, quotes, templates
- **3 migrations**: Core schema (Nov 6, 08:55) → Email templates (10:04) → Indexes & constraints (11:32)
- **15+ indexes**: HNSW vector, B-tree, partial indexes for performance
- **Stack**: Python 3.12+, Alembic 1.13.1, PostgreSQL, psycopg 3.2.0, SQLAlchemy 2.0.38

## Directory Layout
```
db-migration/
├── alembic/
│   ├── env.py                           # Loads .env, constructs DB URL, runs migrations
│   ├── versions/                        # 3 Python revision files
│   │   ├── 0f2b2c3f7ff5_creating_initial_smoothie_tables.py
│   │   ├── 00484a8120a9_create_email_table.py
│   │   └── 3fa985e2456d_alter_schema_index_smoothie_tables.py
│   └── sql/                             # 4 raw SQL scripts
│       ├── V001__initial_core_schema_up.sql
│       ├── V001__initial_core_schema_down.sql
│       ├── V001__initial_core_alter_indexes_up.sql
│       └── V002__create_email.sql
├── scripts/
│   ├── check_db_connection.py           # Health check: 30 retries × 2s
│   └── exceptions.py                    # Custom exception hierarchy
├── migrate.ps1                          # Windows orchestrator
├── Dockerfile                           # Docker image
├── alembic.ini                          # Alembic config
├── requirements.txt                     # Dependencies
├── .env                                 # DB credentials (not committed)
└── docs/kb/                             # Knowledge base
    ├── ANALYSIS_SUMMARY.md              # This analysis
    ├── architecture.md                  # Layers, design patterns, deployment
    ├── configuration.md                 # Environment, deps, exceptions
    ├── database.md                      # 8 tables, 15+ indexes, relationships
    ├── migration-workflow.md            # Alembic setup, 3 revisions, commands
    ├── overview.md                      # Project purpose, features, workflows
    └── learnings.md                     # Scan log, issues, lessons
```

## Golden Rules
1. **Never modify applied migrations** – always create new revisions
2. **SQL separate from Python** – DBA review, easy diffs in git
3. **Health check before migration** – prevents partial deployments
4. **Environment-driven config** – no hardcoded secrets

## Common Commands
```bash
# Generate new migration
alembic revision -m "description_of_change"

# Apply all pending migrations
alembic upgrade head

# Rollback one migration
alembic downgrade -1

# Show migration history
alembic history

# Show current applied revision
alembic current

# Windows orchestrator (health check + upgrade)
.\migrate.ps1

# Docker build & run
docker build -t smoothie-db-migration .
docker run -e DB_USER=... -e DB_PASSWORD=... -e DB_HOST=postgres \
  smoothie-db-migration
```

## 5 Issues Found ⚠️

| Issue | Severity | Description | Fix |
|-------|----------|-------------|-----|
| **SQL naming mismatch** | Medium | Rev 3 reads `V001__...` should be `V003__...` | Rename file, update path |
| **Incomplete downgrade** | High | Revs 2 & 3 have empty downgrade() | Implement downgrade SQL |
| **Docker script name** | Low | Dockerfile references `wait_for_db.py` (doesn't exist) | Update to `check_db_connection.py` |
| **Missing .env.example** | Low | README says `cp .env.example .env` but file missing | Create template with defaults |
| **No rollback tests** | Medium | Downgrade paths not validated in CI | Add integration tests |

## Critical Data Models

### customers
- **PK**: id (UUID)
- **UK**: email, (first_name + last_name + email)
- **Timestamps**: cre_ts, updt_ts (UTC)

### recipe_history
- **Embedding**: 1536-dim vector (pgvector HNSW)
- **UK**: customer_id + day_number
- **Indexes**: HNSW vector similarity, customer lookups, day range

### workflow_runs
- **Status**: PENDING → RUNNING → SUCCESS|FAILED
- **Concurrency**: claimed_by (worker ID), unique active workflows per customer
- **Indexes**: workflow_type + status + started_at (for claiming), partial index on active

### email_templates
- **Versioning**: template_name + version
- **Partial UK**: Only one ACTIVE version per template name
- **Placeholders**: TEXT[] array for variable substitution

## Environment Variables (.env)
```
DB_USER=smoothie_user
DB_PASSWORD=smoothie_password
DB_HOST=localhost              # Default if not set
DB_PORT=5432                   # Default if not set
DB_NAME=smoothie_db

DATABASE_URL=...               # Optional; constructed if not set
```

## Health Check Behavior
- **Script**: `scripts/check_db_connection.py`
- **Retries**: 30 attempts
- **Interval**: 2 seconds
- **Timeout**: 60 seconds total
- **Used by**: Docker CMD, `migrate.ps1`

## Latest Scan Info
- **Date**: 2026-11-16
- **Git Commit**: 912e176794aebf45252a3332fbbc19f822d3b3dc
- **KB Size**: ~36 KB across 7 files
- **Coverage**: Architecture, schema, migrations, config, workflows

---

For detailed analysis, see **[ANALYSIS_SUMMARY.md](ANALYSIS_SUMMARY.md)** or specific KB files linked in [index.md](index.md).
