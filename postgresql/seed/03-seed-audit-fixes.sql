-- 03-seed-audit-fixes.sql
-- Seed test audit fixes

-- Fixes for completed audit
INSERT INTO audit_fixes (id, audit_id, rank, title, category, impact, description, evidence, recommendation, confidence, created_at)
VALUES
(
    'afx_test-001',
    'aud_test-completed-001',
    1,
    'Missing Product Reviews',
    'Trust & Credibility',
    'high',
    'Product pages lack customer reviews, which are crucial for building trust and increasing conversions.',
    'Analyzed 15 product pages. 0 out of 15 have visible customer reviews.',
    'Install a reviews app like Judge.me or Loox to collect and display customer reviews on product pages.',
    0.95,
    NOW() - INTERVAL '25 days'
),
(
    'afx_test-002',
    'aud_test-completed-001',
    2,
    'Slow Page Load Time',
    'Performance',
    'high',
    'Homepage takes over 4 seconds to load on mobile, which can significantly impact bounce rates.',
    'Page load time measured at 4.2s on 3G connection. Google recommends under 3s.',
    'Optimize images using WebP format, lazy load below-the-fold content, and minimize JavaScript.',
    0.88,
    NOW() - INTERVAL '25 days'
),
(
    'afx_test-003',
    'aud_test-completed-001',
    3,
    'No Clear Value Proposition',
    'Conversion Optimization',
    'medium',
    'The homepage does not clearly communicate why customers should buy from this store.',
    'Hero section contains only a product slider without messaging about brand benefits or unique selling points.',
    'Add a clear headline and subheadline explaining what makes this store special and why customers should shop here.',
    0.82,
    NOW() - INTERVAL '25 days'
),
(
    'afx_test-004',
    'aud_test-completed-001',
    4,
    'Missing Trust Badges',
    'Trust & Credibility',
    'medium',
    'No visible trust indicators like SSL badge, payment icons, or security seals on checkout pages.',
    'Checkout page analysis shows no trust badges present.',
    'Add payment method icons, SSL certificate badge, and any relevant security certifications to the checkout page.',
    0.90,
    NOW() - INTERVAL '25 days'
),
(
    'afx_test-005',
    'aud_test-completed-001',
    5,
    'Poor Mobile Navigation',
    'User Experience',
    'low',
    'Mobile menu is difficult to use with small tap targets and no search functionality.',
    'Mobile menu button is 32x32px (recommended: 48x48px). Search icon not visible in mobile header.',
    'Increase mobile menu button size and add a prominent search icon in the mobile header.',
    0.75,
    NOW() - INTERVAL '25 days'
);

-- Fixes for anonymous audit
INSERT INTO audit_fixes (id, audit_id, rank, title, category, impact, description, evidence, recommendation, confidence, created_at)
VALUES
(
    'afx_test-006',
    'aud_test-anonymous-001',
    1,
    'No Email Capture',
    'Marketing',
    'high',
    'The store has no visible email signup form to capture visitor information.',
    'No email popup, footer signup, or lead magnet found on any analyzed pages.',
    'Implement an email capture popup offering a discount code or free shipping for newsletter subscribers.',
    0.92,
    NOW() - INTERVAL '3 days'
),
(
    'afx_test-007',
    'aud_test-anonymous-001',
    2,
    'Missing Social Proof',
    'Trust & Credibility',
    'medium',
    'No customer testimonials, press mentions, or social media follower counts displayed.',
    'Checked homepage, about page, and product pages - no social proof elements found.',
    'Add a testimonials section to the homepage and display social media follower counts if significant.',
    0.85,
    NOW() - INTERVAL '3 days'
);
