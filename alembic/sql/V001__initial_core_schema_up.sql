-- 1. Enable the pgvector extension
CREATE EXTENSION IF NOT EXISTS vector;

-- 2. Customers Table
CREATE TABLE IF NOT EXISTS customers (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    first_name VARCHAR(100) NOT NULL,
    last_name VARCHAR(100) NOT NULL,
    middle_name VARCHAR(100),
    preferred_name VARCHAR(100),
    email VARCHAR(255) UNIQUE NOT NULL,
    is_active BOOLEAN DEFAULT TRUE,
    cre_ts TIMESTAMP WITH TIME ZONE DEFAULT (CURRENT_TIMESTAMP AT TIME ZONE 'UTC'),
    updt_ts TIMESTAMP WITH TIME ZONE DEFAULT (CURRENT_TIMESTAMP AT TIME ZONE 'UTC'),
    CONSTRAINT uq_customer_identity UNIQUE (first_name, last_name, email)
);

CREATE INDEX IF NOT EXISTS idx_customers_email ON customers(email);

-- 3. Customer Preferences Table
CREATE TABLE IF NOT EXISTS customer_preferences (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    customer_id UUID REFERENCES customers(id) ON DELETE CASCADE,
    profile_name VARCHAR(100) DEFAULT 'Default Profile',
    days INT DEFAULT 7,
    max_calories INT DEFAULT 500,
    nut_free BOOLEAN DEFAULT FALSE,
    gluten_free BOOLEAN DEFAULT FALSE,
    dairy_free BOOLEAN DEFAULT FALSE,
    soy_free BOOLEAN DEFAULT FALSE,
    cre_ts TIMESTAMP WITH TIME ZONE DEFAULT (CURRENT_TIMESTAMP AT TIME ZONE 'UTC'),
    updt_ts TIMESTAMP WITH TIME ZONE DEFAULT (CURRENT_TIMESTAMP AT TIME ZONE 'UTC')
);

CREATE INDEX IF NOT EXISTS idx_customer_preferences_customer_id ON customer_preferences(customer_id);

-- 4. Recipe History Table
CREATE TABLE IF NOT EXISTS recipe_history (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    customer_id UUID REFERENCES customers(id) ON DELETE CASCADE,
    recipe_name VARCHAR(255) NOT NULL,
    day_number INT NOT NULL,
    ingredients TEXT NOT NULL,
    instructions TEXT NOT NULL,
    calories INT,
    embedding vector(1536), 
    generated_at TIMESTAMP WITH TIME ZONE DEFAULT (CURRENT_TIMESTAMP AT TIME ZONE 'UTC')
);

CREATE INDEX IF NOT EXISTS recipe_embedding_hnsw_idx ON recipe_history USING hnsw (embedding vector_cosine_ops);
CREATE INDEX IF NOT EXISTS idx_recipe_history_customer ON recipe_history(customer_id);
CREATE INDEX IF NOT EXISTS idx_recipe_history_customer_day ON recipe_history(customer_id, day_number);

-- 5. Motivational Quotes Master Table
CREATE TABLE IF NOT EXISTS motivational_quotes (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    category VARCHAR(50) DEFAULT 'Weight Loss',
    message TEXT NOT NULL,
    cre_ts TIMESTAMP WITH TIME ZONE DEFAULT (CURRENT_TIMESTAMP AT TIME ZONE 'UTC')
);

-- 6. Customer Quote History Table
CREATE TABLE IF NOT EXISTS customer_quote_history (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    customer_id UUID REFERENCES customers(id) ON DELETE CASCADE,
    quote_id UUID REFERENCES motivational_quotes(id) ON DELETE CASCADE,
    sent_at TIMESTAMP WITH TIME ZONE DEFAULT (CURRENT_TIMESTAMP AT TIME ZONE 'UTC'),
    CONSTRAINT uq_customer_quote UNIQUE (customer_id, quote_id)
);

CREATE INDEX IF NOT EXISTS idx_customer_quote_history ON customer_quote_history(customer_id, quote_id);

-- 7. Workflow Runs Table
CREATE TABLE IF NOT EXISTS workflow_runs (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    customer_id UUID REFERENCES customers(id) ON DELETE CASCADE,
    status VARCHAR(50) NOT NULL DEFAULT 'PENDING',
    attempt_count INT DEFAULT 0,
    validation_errors TEXT,
    email_status VARCHAR(50) DEFAULT 'PENDING',
    workflow_type VARCHAR(50) NOT NULL DEFAULT 'NEW_REGISTRATION',
    started_at TIMESTAMP WITH TIME ZONE DEFAULT (CURRENT_TIMESTAMP AT TIME ZONE 'UTC'),
    completed_at TIMESTAMP WITH TIME ZONE DEFAULT (CURRENT_TIMESTAMP AT TIME ZONE 'UTC')
);

CREATE INDEX IF NOT EXISTS idx_workflow_runs_customer ON workflow_runs(customer_id);
CREATE INDEX IF NOT EXISTS idx_workflow_runs_status ON workflow_runs(status);

-- 8. Subscriptions Table
CREATE TABLE IF NOT EXISTS subscriptions (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    customer_id UUID REFERENCES customers(id) ON DELETE CASCADE,
    plan_name VARCHAR(100) NOT NULL DEFAULT 'Standard Smoothie Plan',
    status VARCHAR(50) NOT NULL DEFAULT 'ACTIVE',
    start_date DATE DEFAULT (CURRENT_DATE),
    end_date DATE,
    cre_ts TIMESTAMP WITH TIME ZONE DEFAULT (CURRENT_TIMESTAMP AT TIME ZONE 'UTC'),
    updt_ts TIMESTAMP WITH TIME ZONE DEFAULT (CURRENT_TIMESTAMP AT TIME ZONE 'UTC')
);

CREATE INDEX IF NOT EXISTS idx_subscriptions_customer_id ON subscriptions(customer_id);
CREATE INDEX IF NOT EXISTS idx_subscriptions_status ON subscriptions(status);