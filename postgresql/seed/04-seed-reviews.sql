-- 04-seed-reviews.sql
-- Seed test reviews/testimonials

-- Published testimonials
INSERT INTO reviews (id, audit_id, domain, email, rating, helpful, comment, name, store_name, can_publish, status, created_at, updated_at)
VALUES
(
    'rev_test-001',
    'aud_test-completed-001',
    'example-store.myshopify.com',
    'happy@customer.com',
    5,
    true,
    'StoreScorer helped me identify exactly what was wrong with my store. I implemented the top 3 fixes and saw a 25% increase in conversions within a month!',
    'Sarah M.',
    'SarahsShop',
    true,
    'approved',
    NOW() - INTERVAL '20 days',
    NOW() - INTERVAL '18 days'
),
(
    'rev_test-002',
    'aud_test-anonymous-001',
    'anonymous-store.myshopify.com',
    'merchant@example.com',
    4,
    true,
    'Very detailed analysis. The AI chat feature was surprisingly helpful in explaining the recommendations.',
    'Mike T.',
    NULL,
    true,
    'approved',
    NOW() - INTERVAL '2 days',
    NOW() - INTERVAL '1 day'
);

-- Pending review
INSERT INTO reviews (id, audit_id, domain, email, rating, helpful, comment, name, store_name, can_publish, status, created_at, updated_at)
VALUES
(
    'rev_test-003',
    'aud_test-completed-001',
    'example-store.myshopify.com',
    'another@user.com',
    5,
    true,
    'Great tool! Would love to see more detailed technical recommendations in the future.',
    'John D.',
    'JohnsStore',
    true,
    'pending',
    NOW() - INTERVAL '1 day',
    NOW() - INTERVAL '1 day'
);

-- Anonymous feedback (not for publishing)
INSERT INTO reviews (id, audit_id, domain, helpful, comment, can_publish, status, created_at, updated_at)
VALUES
(
    'rev_test-004',
    'aud_test-anonymous-001',
    'anonymous-store.myshopify.com',
    false,
    'Some of the suggestions were too generic.',
    false,
    'approved',
    NOW() - INTERVAL '3 days',
    NOW() - INTERVAL '3 days'
);
