# db-migration Project Overview

## Purpose
Standalone PostgreSQL database migration service for the Smoothie AI Generator ecosystem. Manages versioned database schema changes using Alembic and raw SQL scripts, supporting pgvector for vector embeddings.

## Key Features
- **Alembic-based versioning**: Tracks migration history with immutable revision files
- **Raw SQL support**: DDL logic separated into `_up.sql` and `_down.sql` files alongside Python revision wrappers
- **pgvector integration**: Creates HNSW vector indexes for semantic recipe search
- **Health checks**: Pre-flight database connectivity validation with retry logic (30 attempts, 2s intervals)
- **Docker deployment**: Containerized setup with health check and automatic migrations on startup
- **Enterprise playbook**: Golden Rule of Immutability: never modify applied migrations; fix forward with new revisions

## Target Databases
- PostgreSQL (3.11+ in Docker, 3.12+ minimum in `pyproject.toml`)
- Local development: `localhost:5432`, database `smoothie_db`

## Supported Workflows
1. Create new migration: `alembic revision -m "description"`
2. Write SQL files: `V001__description_up.sql`, `V001__description_down.sql`
3. Link SQL to Python revision file: edit generated revision, use `op.execute(f.read())`
4. Execute: `.\migrate.ps1` (Windows) or `alembic upgrade head` (direct)
5. Rollback: `alembic downgrade -1` (by revision count)

Sources: README.md, pyproject.toml, Dockerfile, alembic.ini
Verified: 2026-11-16
