# Database Schema

## Engine & Extensions
- **Database**: PostgreSQL (3.11+ Docker / 3.12+ local)
- **Connection Library**: psycopg[binary] >=3.2.0
- **Extensions**: pgvector (for vector embeddings)
- **ORM/Migration Tool**: Alembic 1.13.1, SQLAlchemy 2.0.38

## Core Tables

### 1. customers
Stores customer identity and contact information.
- **id** (UUID, PK): `gen_random_uuid()`
- **first_name, last_name** (VARCHAR 100, NOT NULL)
- **middle_name, preferred_name** (VARCHAR 100, nullable)
- **email** (VARCHAR 255, UNIQUE, NOT NULL)
- **is_active** (BOOLEAN, DEFAULT TRUE)
- **cre_ts, updt_ts** (TIMESTAMPTZ, UTC, auto-updated)
- **Constraints**: `uq_customer_identity` (first_name + last_name + email)
- **Indexes**: `idx_customers_email`

Sources: alembic/sql/V001__initial_core_schema_up.sql
Verified: 2026-11-16

### 2. customer_preferences
Customizable user dietary and generation preferences.
- **id** (UUID, PK)
- **customer_id** (UUID, FK → customers, CASCADE)
- **profile_name** (VARCHAR 100, DEFAULT 'Default Profile')
- **days, max_calories** (INT, defaults 7 / 500)
- **dietary flags** (BOOLEAN): nut_free, gluten_free, dairy_free, soy_free
- **is_active** (BOOLEAN, DEFAULT TRUE, added in V001__initial_core_alter_indexes_up.sql)
- **cre_ts, updt_ts** (TIMESTAMPTZ, UTC)
- **Indexes**: `idx_customer_preferences_customer_id`, `idx_customer_preferences_active` (WHERE is_active = TRUE)

Sources: alembic/sql/V001__initial_core_schema_up.sql, V001__initial_core_alter_indexes_up.sql
Verified: 2026-11-16

### 3. recipe_history
AI-generated smoothie recipes with vector embeddings for semantic search.
- **id** (UUID, PK)
- **customer_id** (UUID, FK → customers, CASCADE)
- **recipe_name** (VARCHAR 255, NOT NULL)
- **day_number** (INT, NOT NULL)
- **ingredients, instructions** (TEXT)
- **calories** (INT, nullable)
- **embedding** (vector(1536), nullable): 1536-dim vector from AI model
- **generated_at** (TIMESTAMPTZ, UTC)
- **Constraints**: `uq_recipe_customer_day` (customer_id + day_number, added in V001__initial_core_alter_indexes_up.sql)
- **Indexes**: 
  - `recipe_embedding_hnsw_idx` (HNSW, vector_cosine_ops)
  - `idx_recipe_history_customer`
  - `idx_recipe_history_customer_day`

Sources: alembic/sql/V001__initial_core_schema_up.sql, V001__initial_core_alter_indexes_up.sql
Verified: 2026-11-16

### 4. motivational_quotes
Master table of motivational quotes by category.
- **id** (UUID, PK)
- **category** (VARCHAR 50, DEFAULT 'Weight Loss')
- **message** (TEXT, NOT NULL)
- **cre_ts** (TIMESTAMPTZ, UTC)

Sources: alembic/sql/V001__initial_core_schema_up.sql
Verified: 2026-11-16

### 5. customer_quote_history
Junction table linking customers to quotes they've received.
- **id** (UUID, PK)
- **customer_id** (UUID, FK → customers, CASCADE)
- **quote_id** (UUID, FK → motivational_quotes, CASCADE)
- **sent_at** (TIMESTAMPTZ, UTC)
- **Constraints**: `uq_customer_quote` (customer_id + quote_id)
- **Indexes**: `idx_customer_quote_history`

Sources: alembic/sql/V001__initial_core_schema_up.sql
Verified: 2026-11-16

### 6. workflow_runs
Tracks async workflow execution (registration, email, etc.) for observability and retry logic.
- **id** (UUID, PK)
- **customer_id** (UUID, FK → customers, CASCADE)
- **status** (VARCHAR 50, DEFAULT 'PENDING'): PENDING, RUNNING, SUCCESS, FAILED
- **attempt_count** (INT, DEFAULT 0)
- **validation_errors** (TEXT, nullable)
- **email_status** (VARCHAR 50, DEFAULT 'PENDING'): PENDING, SENT, FAILED
- **workflow_type** (VARCHAR 50, DEFAULT 'NEW_REGISTRATION'): NEW_REGISTRATION, etc.
- **started_at** (TIMESTAMPTZ, UTC)
- **completed_at** (TIMESTAMPTZ, UTC, nullable, added in V001__initial_core_alter_indexes_up.sql)
- **updt_ts, claimed_by** (added in V001__initial_core_alter_indexes_up.sql)
- **Indexes**:
  - `idx_workflow_runs_customer`
  - `idx_workflow_runs_status`
  - `idx_workflow_claim` (workflow_type + status + started_at)
  - `uq_workflow_active` (customer_id + workflow_type, partial WHERE status IN ('PENDING', 'RUNNING', 'SUCCESS'))

Sources: alembic/sql/V001__initial_core_schema_up.sql, V001__initial_core_alter_indexes_up.sql
Verified: 2026-11-16

### 7. subscriptions
Customer subscription plan tracking.
- **id** (UUID, PK)
- **customer_id** (UUID, FK → customers, CASCADE)
- **plan_name** (VARCHAR 100, DEFAULT 'Standard Smoothie Plan')
- **status** (VARCHAR 50, DEFAULT 'ACTIVE')
- **start_date, end_date** (DATE, end_date nullable)
- **cre_ts, updt_ts** (TIMESTAMPTZ, UTC)
- **Indexes**: `idx_subscriptions_customer_id`, `idx_subscriptions_status`

Sources: alembic/sql/V001__initial_core_schema_up.sql
Verified: 2026-11-16

### 8. email_templates
Master templates for outbound email campaigns (added in migration 00484a8120a9).
- **id** (UUID, PK)
- **template_name** (VARCHAR 100, NOT NULL)
- **version** (INT, DEFAULT 1)
- **subject** (TEXT, NOT NULL)
- **body_html** (TEXT, NOT NULL)
- **placeholders** (TEXT[], nullable): Variable names for template substitution
- **status** (VARCHAR 20, DEFAULT 'ACTIVE'): ACTIVE, INACTIVE, ARCHIVED
- **cre_ts** (TIMESTAMPTZ, UTC)
- **Constraints**: `uq_template_name_version` (template_name + version)
- **Indexes**: `idx_email_templates_active_unique` (partial, template_name WHERE status = 'ACTIVE')

Sources: alembic/sql/V002__create_email.sql
Verified: 2026-11-16

## Relationships
```
customers (1) ──→ (n) customer_preferences
customers (1) ──→ (n) recipe_history
customers (1) ──→ (n) customer_quote_history
customers (1) ──→ (n) workflow_runs
customers (1) ──→ (n) subscriptions
motivational_quotes (1) ──→ (n) customer_quote_history
```

All foreign keys use `ON DELETE CASCADE` to maintain referential integrity.

Sources: alembic/sql/V001__initial_core_schema_up.sql, V001__initial_core_alter_indexes_up.sql, V002__create_email.sql
Verified: 2026-11-16
