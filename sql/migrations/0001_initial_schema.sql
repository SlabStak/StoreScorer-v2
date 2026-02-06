-- ============================================
-- StoreScorer Initial Schema
-- Migration: 0001_initial_schema.sql
-- ============================================

-- Enable required extensions
CREATE EXTENSION IF NOT EXISTS "pgcrypto";

-- ============================================
-- ENUM TYPES
-- ============================================

CREATE TYPE subscription_status AS ENUM ('NONE', 'ACTIVE', 'CANCELED', 'PAST_DUE');
CREATE TYPE audit_status AS ENUM ('PENDING', 'PAYMENT_PENDING', 'PAYMENT_COMPLETE', 'CRAWLING', 'ANALYZING', 'COMPLETED', 'FAILED');
CREATE TYPE payment_status AS ENUM ('PENDING', 'PROCESSING', 'COMPLETED', 'FAILED', 'REFUNDED');
CREATE TYPE page_type AS ENUM ('HOMEPAGE', 'PRODUCT', 'COLLECTION', 'POLICY', 'CART', 'CHECKOUT', 'FAQ', 'BLOG', 'ABOUT', 'CONTACT', 'OTHER');
CREATE TYPE impact_level AS ENUM ('HIGH', 'MEDIUM', 'LOW');
CREATE TYPE job_status AS ENUM ('PENDING', 'PROCESSING', 'COMPLETED', 'FAILED');
CREATE TYPE chat_role AS ENUM ('USER', 'ASSISTANT');
CREATE TYPE review_status AS ENUM ('PENDING', 'APPROVED', 'REJECTED');
CREATE TYPE conversion_event_type AS ENUM ('LANDING_VIEW', 'CHECKOUT_INITIATED', 'PAYMENT_COMPLETE', 'AUDIT_DELIVERED');

-- ============================================
-- USERS TABLE
-- ============================================

CREATE TABLE users (
    id TEXT PRIMARY KEY,
    clerk_id TEXT UNIQUE NOT NULL,
    email TEXT UNIQUE NOT NULL,
    first_name TEXT,
    last_name TEXT,
    email_notifications BOOLEAN DEFAULT TRUE,
    is_admin BOOLEAN DEFAULT FALSE,

    -- Stripe subscription
    stripe_customer_id TEXT UNIQUE,
    stripe_subscription_id TEXT UNIQUE,
    subscription_status subscription_status DEFAULT 'NONE',
    subscription_expires_at TIMESTAMPTZ,

    -- Soft delete
    is_deleted BOOLEAN DEFAULT FALSE,
    deleted_at TIMESTAMPTZ,
    deleted_by TEXT,

    -- Timestamps
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX idx_users_email ON users(email);
CREATE INDEX idx_users_clerk_id ON users(clerk_id);
CREATE INDEX idx_users_stripe_customer_id ON users(stripe_customer_id);
CREATE INDEX idx_users_is_deleted ON users(is_deleted) WHERE is_deleted = FALSE;

-- ============================================
-- AUDITS TABLE
-- ============================================

CREATE TABLE audits (
    id TEXT PRIMARY KEY,
    domain TEXT NOT NULL,
    status audit_status DEFAULT 'PENDING',

    -- User relation (optional)
    user_id TEXT REFERENCES users(id) ON DELETE SET NULL,

    -- Share settings
    share_token TEXT UNIQUE NOT NULL,
    share_active BOOLEAN DEFAULT TRUE,
    share_view_count INTEGER DEFAULT 0,

    -- Results
    mekell_score INTEGER,
    synthesis JSONB,
    error_message TEXT,
    warning_message TEXT,
    token_usage INTEGER DEFAULT 0,

    -- Lead capture
    email TEXT,
    marketing_consent BOOLEAN DEFAULT FALSE,
    created_ip TEXT,
    user_agent TEXT,
    utm_source TEXT,
    utm_medium TEXT,
    utm_campaign TEXT,

    -- Email tracking
    payment_email_sent_at TIMESTAMPTZ,
    report_email_sent_at TIMESTAMPTZ,

    -- Soft delete
    is_deleted BOOLEAN DEFAULT FALSE,
    deleted_at TIMESTAMPTZ,
    deleted_by TEXT,

    -- Timestamps
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW(),
    completed_at TIMESTAMPTZ
);

CREATE INDEX idx_audits_domain ON audits(domain);
CREATE INDEX idx_audits_email ON audits(email);
CREATE INDEX idx_audits_share_token ON audits(share_token);
CREATE INDEX idx_audits_status ON audits(status);
CREATE INDEX idx_audits_user_id ON audits(user_id);
CREATE INDEX idx_audits_created_at ON audits(created_at DESC);
CREATE INDEX idx_audits_status_created ON audits(status, created_at DESC);
CREATE INDEX idx_audits_is_deleted ON audits(is_deleted) WHERE is_deleted = FALSE;

-- ============================================
-- PAYMENTS TABLE
-- ============================================

CREATE TABLE payments (
    id TEXT PRIMARY KEY,
    audit_id TEXT UNIQUE NOT NULL REFERENCES audits(id) ON DELETE CASCADE,

    stripe_session_id TEXT UNIQUE NOT NULL,
    stripe_payment_id TEXT UNIQUE,

    amount INTEGER NOT NULL,
    currency TEXT DEFAULT 'usd',
    status payment_status DEFAULT 'PENDING',

    -- Soft delete
    is_deleted BOOLEAN DEFAULT FALSE,
    deleted_at TIMESTAMPTZ,
    deleted_by TEXT,

    -- Timestamps
    created_at TIMESTAMPTZ DEFAULT NOW(),
    paid_at TIMESTAMPTZ
);

CREATE INDEX idx_payments_stripe_session ON payments(stripe_session_id);
CREATE INDEX idx_payments_stripe_payment ON payments(stripe_payment_id);
CREATE INDEX idx_payments_status ON payments(status);
CREATE INDEX idx_payments_audit_id ON payments(audit_id);

-- ============================================
-- AUDIT PAGES TABLE
-- ============================================

CREATE TABLE audit_pages (
    id TEXT PRIMARY KEY,
    audit_id TEXT NOT NULL REFERENCES audits(id) ON DELETE CASCADE,

    url TEXT NOT NULL,
    page_type page_type NOT NULL,

    title TEXT,
    html TEXT NOT NULL,
    clean_text TEXT NOT NULL,
    analysis JSONB,

    -- Soft delete
    is_deleted BOOLEAN DEFAULT FALSE,
    deleted_at TIMESTAMPTZ,
    deleted_by TEXT,

    -- Timestamps
    crawled_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX idx_audit_pages_audit_id ON audit_pages(audit_id);
CREATE INDEX idx_audit_pages_page_type ON audit_pages(page_type);

-- ============================================
-- AUDIT FIXES TABLE
-- ============================================

CREATE TABLE audit_fixes (
    id TEXT PRIMARY KEY,
    audit_id TEXT NOT NULL REFERENCES audits(id) ON DELETE CASCADE,

    rank INTEGER NOT NULL,
    title TEXT NOT NULL,
    category TEXT NOT NULL,
    impact impact_level NOT NULL,

    description TEXT NOT NULL,
    evidence TEXT NOT NULL,
    recommendation TEXT NOT NULL,

    confidence REAL NOT NULL,

    -- Soft delete
    is_deleted BOOLEAN DEFAULT FALSE,
    deleted_at TIMESTAMPTZ,
    deleted_by TEXT,

    -- Timestamps
    created_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX idx_audit_fixes_audit_id ON audit_fixes(audit_id);
CREATE INDEX idx_audit_fixes_rank ON audit_fixes(rank);
CREATE INDEX idx_audit_fixes_audit_rank ON audit_fixes(audit_id, rank);

-- ============================================
-- AUDIT JOBS TABLE
-- ============================================

CREATE TABLE audit_jobs (
    id TEXT PRIMARY KEY,
    audit_id TEXT NOT NULL REFERENCES audits(id) ON DELETE CASCADE,

    status job_status DEFAULT 'PENDING',
    attempts INTEGER DEFAULT 0,
    last_error TEXT,
    locked_at TIMESTAMPTZ,

    -- Soft delete
    is_deleted BOOLEAN DEFAULT FALSE,
    deleted_at TIMESTAMPTZ,
    deleted_by TEXT,

    -- Timestamps
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX idx_audit_jobs_audit_id ON audit_jobs(audit_id);
CREATE INDEX idx_audit_jobs_status_locked ON audit_jobs(status, locked_at);

-- ============================================
-- CHAT MESSAGES TABLE
-- ============================================

CREATE TABLE chat_messages (
    id TEXT PRIMARY KEY,
    audit_id TEXT NOT NULL REFERENCES audits(id) ON DELETE CASCADE,
    user_id TEXT NOT NULL REFERENCES users(id) ON DELETE CASCADE,

    role chat_role NOT NULL,
    content TEXT NOT NULL,

    -- Soft delete
    is_deleted BOOLEAN DEFAULT FALSE,
    deleted_at TIMESTAMPTZ,
    deleted_by TEXT,

    -- Timestamps
    created_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX idx_chat_messages_audit_id ON chat_messages(audit_id);
CREATE INDEX idx_chat_messages_user_id ON chat_messages(user_id);
CREATE INDEX idx_chat_messages_audit_created ON chat_messages(audit_id, created_at);

-- ============================================
-- REVIEWS TABLE
-- ============================================

CREATE TABLE reviews (
    id TEXT PRIMARY KEY,
    audit_id TEXT NOT NULL REFERENCES audits(id) ON DELETE CASCADE,

    domain TEXT NOT NULL,
    email TEXT,
    rating INTEGER,
    helpful BOOLEAN NOT NULL,
    comment TEXT,
    name TEXT,
    store_name TEXT,
    can_publish BOOLEAN DEFAULT FALSE,
    status review_status DEFAULT 'PENDING',

    -- Soft delete
    is_deleted BOOLEAN DEFAULT FALSE,
    deleted_at TIMESTAMPTZ,
    deleted_by TEXT,

    -- Timestamps
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX idx_reviews_audit_id ON reviews(audit_id);
CREATE INDEX idx_reviews_status ON reviews(status);
CREATE INDEX idx_reviews_status_publish ON reviews(status, can_publish);
CREATE INDEX idx_reviews_created_at ON reviews(created_at DESC);

-- ============================================
-- PAGE VIEWS TABLE (Analytics)
-- ============================================

CREATE TABLE page_views (
    id TEXT PRIMARY KEY,
    path TEXT NOT NULL,
    referrer TEXT,
    utm_source TEXT,
    utm_medium TEXT,
    utm_campaign TEXT,
    user_agent TEXT,
    ip_hash TEXT,
    session_id TEXT,
    user_id TEXT REFERENCES users(id) ON DELETE SET NULL,

    -- Timestamps
    created_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX idx_page_views_created_at ON page_views(created_at DESC);
CREATE INDEX idx_page_views_path_created ON page_views(path, created_at DESC);
CREATE INDEX idx_page_views_session_id ON page_views(session_id);

-- ============================================
-- CONVERSION EVENTS TABLE (Analytics)
-- ============================================

CREATE TABLE conversion_events (
    id TEXT PRIMARY KEY,
    event_type conversion_event_type NOT NULL,
    session_id TEXT,
    user_id TEXT REFERENCES users(id) ON DELETE SET NULL,
    audit_id TEXT REFERENCES audits(id) ON DELETE SET NULL,
    metadata JSONB,

    -- Timestamps
    created_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX idx_conversion_events_type_created ON conversion_events(event_type, created_at DESC);
CREATE INDEX idx_conversion_events_session_id ON conversion_events(session_id);
CREATE INDEX idx_conversion_events_created_at ON conversion_events(created_at DESC);

-- ============================================
-- RATE LIMIT EVENTS TABLE
-- ============================================

CREATE TABLE rate_limit_events (
    id TEXT PRIMARY KEY,
    key TEXT NOT NULL,
    type TEXT NOT NULL,

    -- Timestamps
    created_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX idx_rate_limit_key_created ON rate_limit_events(key, created_at DESC);
CREATE INDEX idx_rate_limit_type_created ON rate_limit_events(type, created_at DESC);

-- ============================================
-- UPDATED_AT TRIGGER FUNCTION
-- ============================================

CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Apply updated_at triggers
CREATE TRIGGER update_users_updated_at
    BEFORE UPDATE ON users
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_audits_updated_at
    BEFORE UPDATE ON audits
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_audit_jobs_updated_at
    BEFORE UPDATE ON audit_jobs
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_reviews_updated_at
    BEFORE UPDATE ON reviews
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_at_column();
