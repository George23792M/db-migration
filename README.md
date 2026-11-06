# Smoothie DB Migrations (Alembic + Raw SQL)

Standalone database migration project managing schemas and `pgvector` extensions using versioned raw SQL scripts.

## Quick Setup
1. Create virtual environment: `python -m venv venv && source venv/bin/activate`
2. Install dependencies: `pip install -r requirements.txt`
3. Set environment variables: `cp .env.example .env`
4. Run health check & migrations: `python scripts/wait_for_db.py && alembic upgrade head`

# Enterprise Database Migration Playbook & Rules

The Golden Rule of Immutability:
---------------------------------
1. Never modify a migration file after it has been applied to any shared environment (staging, production, or teammate's local DB).
2. Fix forward: If you need to fix a bug or change a table from a previous migration, generate a new migration file (alembic revision -m "fix_...") rather than editing an old one.

Standard File Naming & Directory Structure:
--------------------------------------------
1. Maintain a strict, predictable layout so automation scripts and developers instantly know where files belong.

Step-by-Step Workflow for New Migrations: 
-----------------------------------------
1. Generate the Revision (Run alembic revision -m "description_of_change" to generate a new revision script with a unique hash in alembic/versions/.)
2. Write Immutable SQL Files:Keep DDL separate from Python logic. (Create matching _up.sql and _down.sql files right alongside the revision script using the exact same revision hash prefix. Write your explicit PostgreSQL DDL inside them.)
3. Link the SQL files to the Alembic runner (Open the generated Python revision file and implement upgrade() and downgrade() to dynamically read and execute your raw SQL files using op.execute(f.read()).)
4. Execute and Validate:Run via orchestration script. (.\migrate.ps1)