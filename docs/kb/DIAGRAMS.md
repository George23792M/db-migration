# db-migration – System Diagrams

## 1. Data Flow: Running a Migration

```
User / CI Pipeline
       │
       v
   .\migrate.ps1  (Windows) OR  alembic upgrade head (Direct)
       │
   ┌───┴──────────────────────────────────────┐
   │ Orchestration Layer                       │
   │ (Windows: PowerShell orchestrator)        │
   │ (Docker: CMD)                             │
   └───┬──────────────────────────────────────┘
       │
       v
   Kill lingering processes (Windows only)
       │
       v
   ┌───────────────────────────────────────────┐
   │ Health Check: scripts/check_db_connection.py│
   │                                            │
   │ 1. Connect to PostgreSQL                  │
   │ 2. Retry logic: 30 × 2s intervals         │
   │ 3. Exit 0 (success) or 1 (failure)        │
   └───┬──────────────────────────────────────┘
       │
       v
   ┌───────────────────────────────────────────┐
   │ Alembic: alembic upgrade head             │
   │                                            │
   │ 1. Load alembic.ini                       │
   │ 2. Run env.py:                            │
   │    - Load .env → validate DB_* vars       │
   │    - Build psycopg URL                    │
   │    - Inject into config                   │
   │ 3. Query alembic_version table            │
   │ 4. For each pending revision:             │
   │    a. Load Python file (e.g., 0f2b2c3f7ff5)
   │    b. Execute upgrade():                  │
   │       - Open V00X__description_up.sql     │
   │       - op.execute(sql_content)           │
   │    c. Insert revision hash → alembic_version
   │ 5. Exit 0 (success) or 1 (failure)        │
   └───┬──────────────────────────────────────┘
       │
       v
   PostgreSQL Database
   ├── Tables updated
   ├── Indexes created
   ├── alembic_version: [0f2b2c3f7ff5, 00484a8120a9, 3fa985e2456d]
   └── pgvector extension enabled
       │
       v
   Report Success / Failure (CI/CD pipeline)
```

## 2. Database Schema Relationship Diagram

```
                          ┌─────────────────────────┐
                          │     customers (PK: id)  │
                          │  UNIQUE: email          │
                          │  UNIQUE: fname+lname+email
                          └────────┬────────────────┘
                                   │ 1
                   ┌───────────────┼───────────────┐
                   │               │               │
                 (n)↓             (n)↓             (n)↓
        ┌──────────────────┐ ┌──────────────┐ ┌──────────────────┐
        │customer_preferences│ │recipe_history│ │workflow_runs      │
        │(FK: customer_id)  │ │(FK: customer_id)
        │UNIQUE: cust_id+day│ │1536-dim embedding (pgvector)
        │dietary flags      │ │HNSW vector index   │
        │is_active          │ │UNIQUE: cust+day    │
        └──────────────────┘ └──────────────┘ │status: PENDING..  │
                                              │claimed_by (worker)│
                                              │updt_ts, cre_ts    │
                                              └──────────────────┘

        ┌──────────────────┐ ┌──────────────┐ ┌──────────────────┐
        │subscriptions     │ │motivational_ │ │email_templates   │
        │(FK: customer_id) │ │quotes        │ │template_name+ver │
        │plan_name         │ │(standalone)  │ │UNIQUE active ver │
        │status: ACTIVE..  │ │category      │ │subject, body_html│
        └──────────────────┘ └──────┬───────┘ │placeholders      │
                                   │          └──────────────────┘
                                 (n)↓
                       ┌─────────────────────┐
                       │customer_quote_history
                       │(FKs: customer_id,  │
                       │      quote_id)      │
                       │UNIQUE: cust+quote   │
                       │sent_at              │
                       └─────────────────────┘
```

## 3. Alembic Migration Chain

```
Revision 0 (Initial state)
│
│  Apply: 0f2b2c3f7ff5_creating_initial_smoothie_tables
│  SQL: V001__initial_core_schema_up.sql
│  - CREATE EXTENSION pgvector
│  - CREATE TABLE customers (UUID, email UNIQUE, ...)
│  - CREATE TABLE customer_preferences (...)
│  - CREATE TABLE recipe_history (embedding vector(1536), HNSW index, ...)
│  - CREATE TABLE motivational_quotes (...)
│  - CREATE TABLE customer_quote_history (...)
│  - CREATE TABLE workflow_runs (...)
│  - CREATE TABLE subscriptions (...)
│  - CREATE 11 indexes
│
v
Revision 1: 0f2b2c3f7ff5 ✓ Applied
│
│  Apply: 00484a8120a9_create_email_table
│  SQL: V002__create_email.sql
│  - CREATE TABLE email_templates (template_name, version, subject, body_html, placeholders)
│  - CREATE UNIQUE INDEX email_templates_active_unique (partial, WHERE status = 'ACTIVE')
│
v
Revision 2: 00484a8120a9 ✓ Applied
│
│  Apply: 3fa985e2456d_alter_schema_index_smoothie_tables
│  SQL: V001__initial_core_alter_indexes_up.sql (⚠️ Naming issue: should be V003__)
│  - ALTER TABLE workflow_runs: ADD updt_ts, claimed_by
│  - ALTER TABLE workflow_runs: ALTER completed_at (nullable)
│  - ALTER TABLE workflow_runs: ADD 2 indexes (claiming, active workflow concurrency)
│  - ALTER TABLE recipe_history: ADD UNIQUE(customer_id, day_number)
│  - ALTER TABLE customer_preferences: ADD is_active, partial index
│
v
Revision 3: 3fa985e2456d ✓ Applied
│
└─ Ready for next migration
```

## 4. Configuration & Credential Flow

```
Environment Sources:
  ┌─────────────────────────┐
  │  .env (local dev)       │  OR  Environment Variables (Docker/CI)
  │  DB_USER=smoothie_user  │      DB_USER=...
  │  DB_PASSWORD=...        │      DB_PASSWORD=...
  │  DB_HOST=localhost      │      DB_HOST=postgres
  │  DB_PORT=5432           │      DB_PORT=5432
  │  DB_NAME=smoothie_db    │      DB_NAME=smoothie_db
  └────────────┬────────────┘
               │
               v
       Load via python-dotenv
               │
   ┌───────────┴───────────────┐
   │                           │
   v                           v
alembic/env.py      scripts/check_db_connection.py
   │                           │
   ├─ Validate required        ├─ Validate required
   │  vars                     │  vars
   │  (DB_USER, DB_PASSWORD,   │  (DB_USER, DB_PASSWORD,
   │   DB_NAME)                │   DB_NAME)
   │                           │
   ├─ Build psycopg URL:       ├─ Build psycopg URL:
   │  postgresql+psycopg://    │  postgresql://
   │  {user}:{pwd}@{host}:{port
   │  /{db_name}               │  {user}:{pwd}@{host}:{port}
   │                           │  /{db_name}
   │                           │
   ├─ Inject to Alembic config ├─ Retry logic: 30 × 2s
   │                           │
   └───────────┬───────────────┘
               │
               v
         PostgreSQL Database
         (psycopg3 connection)
```

## 5. File Naming & Versioning

```
When you create a new migration:

1. Run: alembic revision -m "add_some_feature"
   → Creates: alembic/versions/<hash>_add_some_feature.py

2. Create SQL files:
   → alembic/sql/V00X__add_some_feature_up.sql
   → alembic/sql/V00X__add_some_feature_down.sql
   
   Where V00X is incremented:
   - V001__ (first migration)
   - V002__ (second migration)
   - V003__ (third migration) ⚠️ Current code has V001__ - NAMING BUG
   - V004__, etc.

3. Edit Python file to reference SQL:

   def upgrade() -> None:
       sql_path = os.path.join(
           os.path.dirname(__file__),
           '../sql/V00X__add_some_feature_up.sql'
       )
       with open(sql_path, 'r', encoding='utf-8') as f:
           op.execute(f.read())

   def downgrade() -> None:
       sql_path = os.path.join(
           os.path.dirname(__file__),
           '../sql/V00X__add_some_feature_down.sql'
       )
       with open(sql_path, 'r', encoding='utf-8') as f:
           op.execute(f.read())

4. Commit both files to git:
   - alembic/versions/<hash>_add_some_feature.py (Python wrapper)
   - alembic/sql/V00X__add_some_feature_up.sql (DDL)
   - alembic/sql/V00X__add_some_feature_down.sql (Rollback)
   
   Benefits:
   ✓ DBA can review raw SQL before run
   ✓ Git diffs show exact schema changes
   ✓ Immutable: never edit after applied
   ✓ Reversible: downgrade via downgrade()
```

## 6. Docker Deployment Flow

```
docker build -t smoothie-db-migration .
│
v
Dockerfile builds image:
├─ FROM python:3.11-slim
├─ WORKDIR /app
├─ Install: libpq-dev, gcc
├─ pip install -r requirements.txt
├─ COPY alembic.ini, alembic/, scripts/
└─ CMD ["sh", "-c", "python scripts/check_db_connection.py && alembic upgrade head"]

docker run \
  -e DB_USER=smoothie_user \
  -e DB_PASSWORD=... \
  -e DB_HOST=postgres \
  -e DB_PORT=5432 \
  -e DB_NAME=smoothie_db \
  smoothie-db-migration
│
v
Container startup:
├─ Run health check (wait for postgres, 30 retries)
├─ Run alembic upgrade head
└─ Exit 0 (success) or 1 (failure) → Docker exit code
   
Used in docker-compose:
   services:
     postgres:
       image: postgres:15
       environment:
         POSTGRES_USER: smoothie_user
         POSTGRES_PASSWORD: ...
         POSTGRES_DB: smoothie_db
     
     db-migrator:
       build: ./db-migration
       depends_on:
         - postgres
       environment:
         DB_HOST: postgres
         DB_USER: smoothie_user
         ...
       # Runs migrations on startup
```

---

**All diagrams represent current state as of 2026-11-16 commit 912e1767...**
