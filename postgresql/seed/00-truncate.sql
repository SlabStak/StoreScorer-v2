-- 00-truncate.sql
-- Truncate all tables in correct order (respecting foreign keys)
-- Run this before seeding to reset the database

TRUNCATE TABLE
    function_log,
    rate_limit_events,
    conversion_events,
    page_views,
    reviews,
    chat_messages,
    audit_jobs,
    audit_fixes,
    audit_pages,
    payments,
    audits,
    users
CASCADE;

-- Reset function_log sequence
ALTER SEQUENCE IF EXISTS function_log_id_seq RESTART WITH 1;
