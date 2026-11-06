# Smoothie DB Migrations (Alembic + Raw SQL)

Standalone database migration project managing schemas and `pgvector` extensions using versioned raw SQL scripts.

## Quick Setup
1. Create virtual environment: `python -m venv venv && source venv/bin/activate`
2. Install dependencies: `pip install -r requirements.txt`
3. Set environment variables: `cp .env.example .env`
4. Run health check & migrations: `python scripts/wait_for_db.py && alembic upgrade head`