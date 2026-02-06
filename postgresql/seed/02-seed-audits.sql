-- 02-seed-audits.sql
-- Seed test audits for development

-- Completed audit for admin user
INSERT INTO audits (id, user_id, domain, status, overall_score, share_token, email, created_at, updated_at)
VALUES (
    'aud_test-completed-001',
    'usr_test-admin-001',
    'example-store.myshopify.com',
    'completed',
    85,
    'share_abc123def456',
    'admin@test.storescorer.com',
    NOW() - INTERVAL '25 days',
    NOW() - INTERVAL '25 days'
);

-- Processing audit for pro user
INSERT INTO audits (id, user_id, domain, status, overall_score, email, created_at, updated_at)
VALUES (
    'aud_test-processing-001',
    'usr_test-pro-001',
    'pro-test-store.myshopify.com',
    'processing',
    NULL,
    'pro@test.storescorer.com',
    NOW() - INTERVAL '1 hour',
    NOW() - INTERVAL '1 hour'
);

-- Pending audit for free user
INSERT INTO audits (id, user_id, domain, status, overall_score, email, created_at, updated_at)
VALUES (
    'aud_test-pending-001',
    'usr_test-free-001',
    'free-test-store.myshopify.com',
    'pending',
    NULL,
    'free@test.storescorer.com',
    NOW() - INTERVAL '5 minutes',
    NOW() - INTERVAL '5 minutes'
);

-- Anonymous audit (no user)
INSERT INTO audits (id, domain, status, overall_score, share_token, email, created_at, updated_at)
VALUES (
    'aud_test-anonymous-001',
    'anonymous-store.myshopify.com',
    'completed',
    72,
    'share_anon123xyz',
    'visitor@example.com',
    NOW() - INTERVAL '3 days',
    NOW() - INTERVAL '3 days'
);
