-- ============================================
-- StoreScorer Security Setup
-- Run this AFTER creating all tables and functions
-- ============================================

-- Create function_log table for audit trail
CREATE TABLE IF NOT EXISTS function_log (
    id BIGSERIAL PRIMARY KEY,
    function_name TEXT NOT NULL,
    user_id TEXT,
    input_params JSONB DEFAULT '{}'::JSONB,
    output_result JSONB DEFAULT '{}'::JSONB,
    error_message TEXT,
    execution_time_ms INTEGER,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- Indexes for function_log
CREATE INDEX IF NOT EXISTS idx_function_log_function_name
    ON function_log(function_name);

CREATE INDEX IF NOT EXISTS idx_function_log_user_id
    ON function_log(user_id);

CREATE INDEX IF NOT EXISTS idx_function_log_created_at
    ON function_log(created_at DESC);

CREATE INDEX IF NOT EXISTS idx_function_log_function_created
    ON function_log(function_name, created_at DESC);

-- ============================================
-- Create restricted API user
-- ============================================

DO $$
BEGIN
    IF NOT EXISTS (SELECT FROM pg_roles WHERE rolname = 'app_api') THEN
        CREATE ROLE app_api WITH LOGIN PASSWORD 'CHANGE_ME_IN_PRODUCTION';
    END IF;
END
$$;

-- Revoke all default privileges from app_api
REVOKE ALL ON ALL TABLES IN SCHEMA public FROM app_api;
REVOKE ALL ON ALL SEQUENCES IN SCHEMA public FROM app_api;
REVOKE ALL ON ALL FUNCTIONS IN SCHEMA public FROM app_api;

-- Grant connect to database
GRANT CONNECT ON DATABASE storescorer TO app_api;

-- Grant usage on schema
GRANT USAGE ON SCHEMA public TO app_api;

-- Grant EXECUTE on all functions (the ONLY way app_api accesses data)
GRANT EXECUTE ON ALL FUNCTIONS IN SCHEMA public TO app_api;

-- Set default privileges for future functions
ALTER DEFAULT PRIVILEGES IN SCHEMA public
    GRANT EXECUTE ON FUNCTIONS TO app_api;

-- Explicitly deny direct table access
REVOKE SELECT, INSERT, UPDATE, DELETE ON ALL TABLES IN SCHEMA public FROM app_api;

-- ============================================
-- Comments
-- ============================================

COMMENT ON TABLE function_log IS 'Audit log for all PostgreSQL function calls';
COMMENT ON COLUMN function_log.function_name IS 'Name of the PostgreSQL function called';
COMMENT ON COLUMN function_log.user_id IS 'Clerk user ID or system identifier';
COMMENT ON COLUMN function_log.input_params IS 'Input parameters (sanitized, no secrets)';
COMMENT ON COLUMN function_log.output_result IS 'Result summary (not full data)';
COMMENT ON COLUMN function_log.error_message IS 'Error message if function failed';
COMMENT ON COLUMN function_log.execution_time_ms IS 'Function execution time in milliseconds';

-- ============================================
-- The app_api user can ONLY:
-- 1. Connect to the database
-- 2. Execute functions (which use SECURITY DEFINER to access tables)
-- 3. Nothing else - NO direct table access
-- ============================================
