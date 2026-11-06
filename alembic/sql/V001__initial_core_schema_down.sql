-- -----------------------------------------------------
-- 1. Drop Indexes First
-- -----------------------------------------------------
DROP INDEX IF EXISTS idx_customers_email;
DROP INDEX IF EXISTS idx_customer_preferences_customer_id;
DROP INDEX IF EXISTS recipe_embedding_hnsw_idx;
DROP INDEX IF EXISTS idx_recipe_history_customer;
DROP INDEX IF EXISTS idx_recipe_history_customer_day;
DROP INDEX IF EXISTS idx_customer_quote_history;
DROP INDEX IF EXISTS idx_workflow_runs_customer;
DROP INDEX IF EXISTS idx_workflow_runs_status;
DROP INDEX IF EXISTS idx_subscriptions_customer_id;
DROP INDEX IF EXISTS idx_subscriptions_status;

-- -----------------------------------------------------
-- 2. Drop Tables (Using CASCADE to handle foreign key dependencies cleanly)
-- -----------------------------------------------------
DROP TABLE IF EXISTS subscriptions CASCADE;
DROP TABLE IF EXISTS workflow_runs CASCADE;
DROP TABLE IF EXISTS customer_quote_history CASCADE;
DROP TABLE IF EXISTS motivational_quotes CASCADE;
DROP TABLE IF EXISTS recipe_history CASCADE;
DROP TABLE IF EXISTS customer_preferences CASCADE;
DROP TABLE IF EXISTS customers CASCADE;

-- -----------------------------------------------------
-- 3. Drop Extensions (Optional: Only if no other tables use vector)
-- -----------------------------------------------------
DROP EXTENSION IF EXISTS vector CASCADE;