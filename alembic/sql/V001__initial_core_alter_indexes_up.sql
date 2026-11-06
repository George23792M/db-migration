-- =====================================================================
-- Migration 002: MCP Architecture & Workflow Enhancements
-- =====================================================================

-- 1. Modify workflow_runs table
ALTER TABLE workflow_runs 
    ADD COLUMN IF NOT EXISTS updt_ts TIMESTAMPTZ DEFAULT (CURRENT_TIMESTAMP AT TIME ZONE 'UTC'),
    ADD COLUMN IF NOT EXISTS claimed_by VARCHAR(100);

-- Make completed_at nullable with no default
ALTER TABLE workflow_runs ALTER COLUMN completed_at DROP DEFAULT;
ALTER TABLE workflow_runs ALTER COLUMN completed_at DROP NOT NULL;

-- Set existing PENDING rows to have a NULL completed_at
UPDATE workflow_runs 
SET completed_at = NULL 
WHERE status = 'PENDING';

-- Add indexes for optimized worker claiming and concurrency control
CREATE INDEX IF NOT EXISTS idx_workflow_claim 
    ON workflow_runs(workflow_type, status, started_at);

CREATE UNIQUE INDEX IF NOT EXISTS uq_workflow_active 
    ON workflow_runs(customer_id, workflow_type) 
    WHERE status IN ('PENDING', 'RUNNING', 'SUCCESS');


-- 2. Modify recipe_history table
-- Prevents duplicate recipe entries for the same customer on the same day
ALTER TABLE recipe_history 
    ADD CONSTRAINT uq_recipe_customer_day UNIQUE (customer_id, day_number);


-- 3. Modify customer_preferences table
ALTER TABLE customer_preferences 
    ADD COLUMN IF NOT EXISTS is_active BOOLEAN DEFAULT TRUE;

CREATE INDEX IF NOT EXISTS idx_customer_preferences_active
    ON customer_preferences(customer_id) WHERE is_active;