-- 01-seed-users.sql
-- Seed test users for development

-- Test admin user
INSERT INTO users (id, clerk_id, email, first_name, last_name, tier, credits, created_at, updated_at)
VALUES (
    'usr_test-admin-001',
    'user_test_admin_001',
    'admin@test.storescorer.com',
    'Admin',
    'User',
    'enterprise',
    1000,
    NOW() - INTERVAL '30 days',
    NOW()
);

-- Test pro user
INSERT INTO users (id, clerk_id, email, first_name, last_name, tier, credits, created_at, updated_at)
VALUES (
    'usr_test-pro-001',
    'user_test_pro_001',
    'pro@test.storescorer.com',
    'Pro',
    'User',
    'pro',
    100,
    NOW() - INTERVAL '14 days',
    NOW()
);

-- Test free user
INSERT INTO users (id, clerk_id, email, first_name, last_name, tier, credits, created_at, updated_at)
VALUES (
    'usr_test-free-001',
    'user_test_free_001',
    'free@test.storescorer.com',
    'Free',
    'User',
    'free',
    3,
    NOW() - INTERVAL '7 days',
    NOW()
);
