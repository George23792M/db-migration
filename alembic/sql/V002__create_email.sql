
--Create email_templates table (Stores pre-generated/master email copy)
CREATE TABLE IF NOT EXISTS email_templates (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    template_name VARCHAR(100) NOT NULL,
    version INT NOT NULL DEFAULT 1,
    subject TEXT NOT NULL,
    body_html TEXT NOT NULL,
    placeholders TEXT[],
    status VARCHAR(20) DEFAULT 'ACTIVE',
    cre_ts TIMESTAMPTZ DEFAULT (CURRENT_TIMESTAMP AT TIME ZONE 'UTC'),
    
    CONSTRAINT uq_template_name_version UNIQUE (template_name, version)
);

-- Partial unique index to enforce only one active version per template name
CREATE UNIQUE INDEX IF NOT EXISTS idx_email_templates_active_unique 
    ON email_templates (template_name) 
    WHERE status = 'ACTIVE';