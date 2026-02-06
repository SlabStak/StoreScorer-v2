-- ============================================
-- Review PostgreSQL Functions
-- StoreScorer Build Standard
-- ============================================

-- ============================================
-- CREATE REVIEW
-- ============================================
CREATE OR REPLACE FUNCTION create_review(
    p_user_id TEXT,
    p_audit_id TEXT,
    p_domain TEXT,
    p_helpful BOOLEAN,
    p_email TEXT DEFAULT NULL,
    p_rating INTEGER DEFAULT NULL,
    p_comment TEXT DEFAULT NULL,
    p_name TEXT DEFAULT NULL,
    p_store_name TEXT DEFAULT NULL,
    p_can_publish BOOLEAN DEFAULT FALSE
)
RETURNS JSONB
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
    l_id TEXT;
    l_result JSONB;
    l_now TIMESTAMPTZ := NOW();
BEGIN
    l_id := 'rev_' || gen_random_uuid()::TEXT;

    INSERT INTO reviews (
        id,
        audit_id,
        domain,
        email,
        rating,
        helpful,
        comment,
        name,
        store_name,
        can_publish,
        status,
        created_at,
        updated_at
    ) VALUES (
        l_id,
        p_audit_id,
        p_domain,
        p_email,
        p_rating,
        p_helpful,
        p_comment,
        p_name,
        p_store_name,
        p_can_publish,
        'PENDING',
        l_now,
        l_now
    );

    l_result := jsonb_build_object(
        'success', TRUE,
        'data', jsonb_build_object(
            'id', l_id,
            'audit_id', p_audit_id,
            'domain', p_domain,
            'helpful', p_helpful,
            'rating', p_rating,
            'status', 'PENDING',
            'created_at', l_now
        )
    );

    INSERT INTO function_log (
        function_name,
        user_id,
        input_params,
        output_result,
        execution_time_ms
    ) VALUES (
        'create_review',
        p_user_id,
        jsonb_build_object('audit_id', p_audit_id, 'domain', p_domain, 'helpful', p_helpful),
        jsonb_build_object('success', TRUE, 'id', l_id),
        EXTRACT(MILLISECONDS FROM (clock_timestamp() - l_now))::INTEGER
    );

    RETURN l_result;

EXCEPTION WHEN OTHERS THEN
    l_result := jsonb_build_object(
        'success', FALSE,
        'error', SQLERRM
    );
    RETURN l_result;
END;
$$;

-- ============================================
-- GET REVIEW
-- ============================================
CREATE OR REPLACE FUNCTION get_review(
    p_user_id TEXT,
    p_id TEXT
)
RETURNS JSONB
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
    l_result JSONB;
    l_record RECORD;
BEGIN
    SELECT *
    INTO l_record
    FROM reviews
    WHERE id = p_id
      AND is_deleted = FALSE;

    IF NOT FOUND THEN
        RETURN jsonb_build_object(
            'success', FALSE,
            'error', 'Review not found'
        );
    END IF;

    l_result := jsonb_build_object(
        'success', TRUE,
        'data', jsonb_build_object(
            'id', l_record.id,
            'audit_id', l_record.audit_id,
            'domain', l_record.domain,
            'email', l_record.email,
            'rating', l_record.rating,
            'helpful', l_record.helpful,
            'comment', l_record.comment,
            'name', l_record.name,
            'store_name', l_record.store_name,
            'can_publish', l_record.can_publish,
            'status', l_record.status,
            'created_at', l_record.created_at
        )
    );

    RETURN l_result;
END;
$$;

-- ============================================
-- LIST REVIEWS (Admin)
-- ============================================
CREATE OR REPLACE FUNCTION list_reviews(
    p_user_id TEXT,
    p_filters JSONB DEFAULT '{}'::JSONB,
    p_limit INTEGER DEFAULT 50,
    p_offset INTEGER DEFAULT 0
)
RETURNS JSONB
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
    l_result JSONB;
    l_items JSONB;
    l_total INTEGER;
    l_now TIMESTAMPTZ := NOW();
BEGIN
    SELECT COUNT(*)
    INTO l_total
    FROM reviews
    WHERE is_deleted = FALSE
      AND (p_filters->>'status' IS NULL
           OR status = (p_filters->>'status')::review_status);

    SELECT COALESCE(jsonb_agg(
        jsonb_build_object(
            'id', r.id,
            'audit_id', r.audit_id,
            'domain', r.domain,
            'email', r.email,
            'rating', r.rating,
            'helpful', r.helpful,
            'comment', r.comment,
            'name', r.name,
            'store_name', r.store_name,
            'can_publish', r.can_publish,
            'status', r.status,
            'created_at', r.created_at
        ) ORDER BY r.created_at DESC
    ), '[]'::JSONB)
    INTO l_items
    FROM reviews r
    WHERE r.is_deleted = FALSE
      AND (p_filters->>'status' IS NULL
           OR r.status = (p_filters->>'status')::review_status)
    LIMIT p_limit
    OFFSET p_offset;

    l_result := jsonb_build_object(
        'success', TRUE,
        'data', jsonb_build_object(
            'items', l_items,
            'total', l_total,
            'limit', p_limit,
            'offset', p_offset
        )
    );

    INSERT INTO function_log (
        function_name,
        user_id,
        input_params,
        output_result,
        execution_time_ms
    ) VALUES (
        'list_reviews',
        p_user_id,
        jsonb_build_object('filters', p_filters, 'limit', p_limit),
        jsonb_build_object('success', TRUE, 'total', l_total),
        EXTRACT(MILLISECONDS FROM (clock_timestamp() - l_now))::INTEGER
    );

    RETURN l_result;
END;
$$;

-- ============================================
-- LIST PUBLISHED TESTIMONIALS (Public)
-- ============================================
CREATE OR REPLACE FUNCTION list_testimonials(
    p_user_id TEXT,
    p_limit INTEGER DEFAULT 10
)
RETURNS JSONB
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
    l_result JSONB;
    l_items JSONB;
    l_now TIMESTAMPTZ := NOW();
BEGIN
    SELECT COALESCE(jsonb_agg(
        jsonb_build_object(
            'id', r.id,
            'domain', r.domain,
            'rating', r.rating,
            'comment', r.comment,
            'name', r.name,
            'store_name', r.store_name,
            'created_at', r.created_at
        ) ORDER BY r.created_at DESC
    ), '[]'::JSONB)
    INTO l_items
    FROM reviews r
    WHERE r.is_deleted = FALSE
      AND r.status = 'APPROVED'
      AND r.can_publish = TRUE
      AND r.comment IS NOT NULL
    LIMIT p_limit;

    l_result := jsonb_build_object(
        'success', TRUE,
        'data', jsonb_build_object(
            'items', l_items,
            'total', jsonb_array_length(l_items)
        )
    );

    RETURN l_result;
END;
$$;

-- ============================================
-- UPDATE REVIEW STATUS (Admin)
-- ============================================
CREATE OR REPLACE FUNCTION update_review_status(
    p_user_id TEXT,
    p_id TEXT,
    p_status TEXT
)
RETURNS JSONB
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
    l_result JSONB;
    l_exists BOOLEAN;
    l_now TIMESTAMPTZ := NOW();
BEGIN
    SELECT EXISTS(
        SELECT 1 FROM reviews
        WHERE id = p_id AND is_deleted = FALSE
    ) INTO l_exists;

    IF NOT l_exists THEN
        RETURN jsonb_build_object(
            'success', FALSE,
            'error', 'Review not found'
        );
    END IF;

    UPDATE reviews
    SET
        status = p_status::review_status,
        updated_at = l_now
    WHERE id = p_id;

    INSERT INTO function_log (
        function_name,
        user_id,
        input_params,
        output_result,
        execution_time_ms
    ) VALUES (
        'update_review_status',
        p_user_id,
        jsonb_build_object('id', p_id, 'status', p_status),
        jsonb_build_object('success', TRUE),
        EXTRACT(MILLISECONDS FROM (clock_timestamp() - l_now))::INTEGER
    );

    RETURN get_review(p_user_id, p_id);
END;
$$;
