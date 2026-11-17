# Learning Log

## 2026-11-16 – db-migration Initial Scan
- **Trigger**: User requested project analysis
- **What worked**:
  - Clear file structure (alembic/, scripts/, .env template)
  - README.md documents Golden Rule of Immutability and workflow steps
  - Migration revisions in chronological order with clear naming
  - SQL files separated from Python for auditability
  - Custom exception hierarchy for error handling
  - Health check script with retry logic (30× 2s = 60s timeout)
  
- **What went wrong / was missing**:
  - File naming inconsistency: 3rd migration revision (`3fa985e2456d_alter_schema_index_smoothie_tables.py`) references SQL file named `V001__initial_core_alter_indexes_up.sql` (should be `V003__...` to match revision sequence)
  - Downgrade logic incomplete: revisions 2 & 3 have empty `downgrade()` functions
  - Docker Dockerfile references `wait_for_db.py` in CMD but actual script is `check_db_connection.py` (possible discrepancy)
  - No integration tests or validation of rollback scenarios documented
  - Design Intelligence analysis not yet run
  
- **Lesson (actionable rule for next time)**:
  - Always check SQL file naming convention (V00X__description) against revision sequence order to catch off-by-one errors
  - For enterprise migration tools, validate that downgrade paths are complete before merge (especially in revision chains)
  - Cross-reference Docker CMD against actual script locations in source tree
  
- **KB files changed**:
  - `docs/kb/index.md` (created)
  - `docs/kb/overview.md` (created)
  - `docs/kb/database.md` (created)
  - `docs/kb/migration-workflow.md` (created)
  - `docs/kb/configuration.md` (created)
  - `docs/kb/architecture.md` (created)
  
- **Confidence**: high (all entries backed by actual file reads)
