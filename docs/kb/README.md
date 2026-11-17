# db-migration Knowledge Base – Welcome 👋

This knowledge base contains comprehensive documentation of the **db-migration** project, a production-grade PostgreSQL schema versioning tool for the Smoothie AI Generator ecosystem.

## 📚 Start Here

### For Quick Understanding (5 min)
1. **[QUICK_REFERENCE.md](QUICK_REFERENCE.md)** – One-page cheat sheet with commands, schema, issues, and env vars
2. **[DIAGRAMS.md](DIAGRAMS.md)** – Visual flows and system architecture

### For Complete Analysis (15 min)
3. **[ANALYSIS_SUMMARY.md](ANALYSIS_SUMMARY.md)** – Full project breakdown with 5 issues found and recommended fixes

### For Specific Deep Dives
- **[overview.md](overview.md)** – Project purpose, features, workflows
- **[architecture.md](architecture.md)** – Layered design, patterns, deployment strategies
- **[database.md](database.md)** – 8 tables, 15+ indexes, relationships, constraints
- **[migration-workflow.md](migration-workflow.md)** – Alembic setup, 3 revisions, migration pattern
- **[configuration.md](configuration.md)** – Environment variables, dependencies, Docker, exceptions

### For Maintenance
- **[learnings.md](learnings.md)** – Scan history, lessons learned, what to watch for
- **[index.md](index.md)** – Master index with TOC and known gaps

---

## 🎯 Key Facts at a Glance

| Aspect | Details |
|--------|---------|
| **Purpose** | PostgreSQL schema versioning for Smoothie AI ecosystem |
| **Tech Stack** | Python 3.12+, Alembic 1.13.1, PostgreSQL, psycopg 3.2.0, SQLAlchemy 2.0.38 |
| **Database** | 8 tables (customers, recipes with 1536-dim embeddings, workflows, templates, etc.) |
| **Migrations** | 3 revisions applied (Nov 6, 2026): Core schema → Email templates → Indexes & constraints |
| **Pattern** | Alembic + raw SQL files, immutable versioning, environment-driven config |
| **Reliability** | Health check with 30 retry × 2s timeout, exit codes for CI/CD integration |
| **Status** | ✅ Production-ready, with ⚠️ 5 minor/medium issues documented |

---

## ⚠️ Critical Issues Found

### 1. **SQL File Naming Mismatch** (Medium)
Revision 3 references `V001__...` should be `V003__...`

### 2. **Incomplete Downgrade Logic** (High)
Revisions 2 & 3 have empty `downgrade()` functions – cannot safely rollback

### 3. **Docker Script Name** (Low)
Dockerfile references non-existent `wait_for_db.py`

### 4. **Missing .env.example** (Low)
Template file referenced in README doesn't exist

### 5. **No Rollback Tests** (Medium)
Downgrade paths not validated in CI/CD

👉 **See [ANALYSIS_SUMMARY.md](ANALYSIS_SUMMARY.md) for detailed fixes and priority ranking.**

---

## 🔧 Common Workflows

### Create a New Migration
```bash
# 1. Generate
alembic revision -m "description_of_change"

# 2. Write SQL files
# - alembic/sql/V00X__description_up.sql
# - alembic/sql/V00X__description_down.sql

# 3. Edit Python file (alembic/versions/<hash>_*.py)
# - Implement upgrade() to read V00X__..._up.sql
# - Implement downgrade() to read V00X__..._down.sql

# 4. Run
alembic upgrade head
# or
.\migrate.ps1  # Windows
```

### Rollback a Migration
```bash
alembic downgrade -1  # Go back one revision
alembic downgrade 0f2b2c3f7ff5  # Go back to specific revision
```

### Docker Deployment
```bash
docker build -t smoothie-db-migration .
docker run -e DB_USER=smoothie_user -e DB_PASSWORD=... -e DB_HOST=postgres \
  smoothie-db-migration
```

---

## 📖 Document Structure

### Analysis & Reference (Read First)
- **QUICK_REFERENCE.md** – 1-page cheat sheet
- **DIAGRAMS.md** – Visual system diagrams
- **ANALYSIS_SUMMARY.md** – Full findings + issues + fixes

### Core Knowledge (Deep Dive)
- **overview.md** – What it does and why
- **architecture.md** – How it's built (layers, patterns)
- **database.md** – Schema details (tables, indexes, relationships)
- **migration-workflow.md** – Migration process and Alembic setup
- **configuration.md** – Environment, dependencies, exceptions

### Maintenance & History
- **index.md** – Master TOC and known gaps
- **learnings.md** – Scan log and lessons for future work

---

## 🔍 Knowledge Base Metadata

- **Last Scan**: 2026-11-16
- **Git Commit**: 912e176794aebf45252a3332fbbc19f822d3b3dc
- **KB Size**: ~52 KB across 10 files
- **Coverage**: Architecture, schema, migrations, config, deployment, diagrams, analysis

---

## 💡 Next Steps

1. **High Priority**: Implement downgrade logic for revisions 2 & 3
2. **Medium Priority**: Fix SQL file naming (V001 → V003) and Docker reference
3. **Medium Priority**: Add CI/CD rollback tests
4. **Low Priority**: Create .env.example template

For detailed recommendations, see **[ANALYSIS_SUMMARY.md → Recommended Next Steps](ANALYSIS_SUMMARY.md#recommended-next-steps)**.

---

## 📞 Questions?

Refer to the specific KB files linked above, or check [learnings.md](learnings.md) for lessons learned during the scan.

**All information verified against source code as of commit 912e1767. Last verified: 2026-11-16.**
