-- ============================================
-- Audit PostgreSQL Functions
-- StoreScorer Build Standard
-- ============================================

-- ============================================
-- CREATE AUDIT
-- ============================================
CREATE OR REPLACE FUNCTION create_audit(
    p_user_id TEXT,
    p_domain TEXT,
    p_email TEXT DEFAULT NULL,
    p_marketing_consent BOOLEAN DEFAULT FALSE,
    p_created_ip TEXT DEFAULT NULL,
    p_user_agent TEXT DEFAULT NULL,
    p_utm_source TEXT DEFAULT NULL,
    p_utm_medium TEXT DEFAULT NULL,
    p_utm_campaign TEXT DEFAULT NULL
)
RETURNS JSONB
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
    l_id TEXT;
    l_share_token TEXT;
    l_result JSONB;
    l_now TIMESTAMPTZ := NOW();
BEGIN
    -- Generate prefixed UUID
    l_id := 'aud_' || gen_random_uuid()::TEXT;
    l_share_token := gen_random_uuid()::TEXT;

    -- Insert record
    INSERT INTO audits (
        id,
        domain,
        user_id,
        share_token,
        email,
        marketing_consent,
        created_ip,
        user_agent,
        utm_source,
        utm_medium,
        utm_campaign,
        created_at,
        updated_at
    ) VALUES (
        l_id,
        p_domain,
        NULLIF(p_user_id, 'system'),
        l_share_token,
        p_email,
        p_marketing_consent,
        p_created_ip,
        p_user_agent,
        p_utm_source,
        p_utm_medium,
        p_utm_campaign,
        l_now,
        l_now
    );

    -- Build result
    l_result := jsonb_build_object(
        'success', TRUE,
        'data', jsonb_build_object(
            'id', l_id,
            'domain', p_domain,
            'status', 'PENDING',
            'user_id', NULLIF(p_user_id, 'system'),
            'share_token', l_share_token,
            'share_active', TRUE,
            'email', p_email,
            'created_at', l_now,
            'updated_at', l_now
        )
    );

    -- Log operation
    INSERT INTO function_log (
        function_name,
        user_id,
        input_params,
        output_result,
        execution_time_ms
    ) VALUES (
        'create_audit',
        p_user_id,
        jsonb_build_object('domain', p_domain, 'email', p_email),
        jsonb_build_object('success', TRUE, 'id', l_id),
        EXTRACT(MILLISECONDS FROM (clock_timestamp() - l_now))::INTEGER
    );

    RETURN l_result;

EXCEPTION WHEN OTHERS THEN
    l_result := jsonb_build_object(
        'success', FALSE,
        'error', SQLERRM
    );

    INSERT INTO function_log (
        function_name,
        user_id,
        input_params,
        output_result,
        error_message
    ) VALUES (
        'create_audit',
        p_user_id,
        jsonb_build_object('domain', p_domain),
        l_result,
        SQLERRM
    );

    RETURN l_result;
END;
$$;

-- ============================================
-- GET AUDIT
-- ============================================
CREATE OR REPLACE FUNCTION get_audit(
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
    l_now TIMESTAMPTZ := NOW();
BEGIN
    SELECT *
    INTO l_record
    FROM audits
    WHERE id = p_id
      AND is_deleted = FALSE;

    IF NOT FOUND THEN
        RETURN jsonb_build_object(
            'success', FALSE,
            'error', 'Audit not found'
        );
    END IF;

    l_result := jsonb_build_object(
        'success', TRUE,
        'data', jsonb_build_object(
            'id', l_record.id,
            'domain', l_record.domain,
            'status', l_record.status,
            'user_id', l_record.user_id,
            'share_token', l_record.share_token,
            'share_active', l_record.share_active,
            'share_view_count', l_record.share_view_count,
            'mekell_score', l_record.mekell_score,
            'synthesis', l_record.synthesis,
            'error_message', l_record.error_message,
            'warning_message', l_record.warning_message,
            'token_usage', l_record.token_usage,
            'email', l_record.email,
            'marketing_consent', l_record.marketing_consent,
            'utm_source', l_record.utm_source,
            'utm_medium', l_record.utm_medium,
            'utm_campaign', l_record.utm_campaign,
            'payment_email_sent_at', l_record.payment_email_sent_at,
            'report_email_sent_at', l_record.report_email_sent_at,
            'created_at', l_record.created_at,
            'updated_at', l_record.updated_at,
            'completed_at', l_record.completed_at
        )
    );

    INSERT INTO function_log (
        function_name,
        user_id,
        input_params,
        output_result,
        execution_time_ms
    ) VALUES (
        'get_audit',
        p_user_id,
        jsonb_build_object('id', p_id),
        jsonb_build_object('success', TRUE),
        EXTRACT(MILLISECONDS FROM (clock_timestamp() - l_now))::INTEGER
    );

    RETURN l_result;
END;
$$;

-- ============================================
-- GET AUDIT BY SHARE TOKEN
-- ============================================
CREATE OR REPLACE FUNCTION get_audit_by_share_token(
    p_user_id TEXT,
    p_share_token TEXT
)
RETURNS JSONB
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
    l_result JSONB;
    l_record RECORD;
    l_now TIMESTAMPTZ := NOW();
BEGIN
    SELECT *
    INTO l_record
    FROM audits
    WHERE share_token = p_share_token
      AND share_active = TRUE
      AND is_deleted = FALSE;

    IF NOT FOUND THEN
        RETURN jsonb_build_object(
            'success', FALSE,
            'error', 'Audit not found'
        );
    END IF;

    -- Increment view count
    UPDATE audits
    SET share_view_count = share_view_count + 1
    WHERE id = l_record.id;

    l_result := jsonb_build_object(
        'success', TRUE,
        'data', jsonb_build_object(
            'id', l_record.id,
            'domain', l_record.domain,
            'status', l_record.status,
            'mekell_score', l_record.mekell_score,
            'synthesis', l_record.synthesis,
            'share_view_count', l_record.share_view_count + 1,
            'created_at', l_record.created_at,
            'completed_at', l_record.completed_at
        )
    );

    INSERT INTO function_log (
        function_name,
        user_id,
        input_params,
        output_result,
        execution_time_ms
    ) VALUES (
        'get_audit_by_share_token',
        p_user_id,
        jsonb_build_object('share_token', LEFT(p_share_token, 8) || '...'),
        jsonb_build_object('success', TRUE),
        EXTRACT(MILLISECONDS FROM (clock_timestamp() - l_now))::INTEGER
    );

    RETURN l_result;
END;
$$;

-- ============================================
-- GET AUDIT WITH FIXES
-- ============================================
CREATE OR REPLACE FUNCTION get_audit_with_fixes(
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
    l_audit JSONB;
    l_fixes JSONB;
    l_pages JSONB;
    l_payment JSONB;
    l_now TIMESTAMPTZ := NOW();
BEGIN
    -- Get audit
    l_audit := get_audit(p_user_id, p_id);

    IF NOT (l_audit->>'success')::BOOLEAN THEN
        RETURN l_audit;
    END IF;

    -- Get fixes
    SELECT COALESCE(jsonb_agg(
        jsonb_build_object(
            'id', f.id,
            'rank', f.rank,
            'title', f.title,
            'category', f.category,
            'impact', f.impact,
            'description', f.description,
            'evidence', f.evidence,
            'recommendation', f.recommendation,
            'confidence', f.confidence
        ) ORDER BY f.rank
    ), '[]'::JSONB)
    INTO l_fixes
    FROM audit_fixes f
    WHERE f.audit_id = p_id
      AND f.is_deleted = FALSE;

    -- Get pages (without html for performance)
    SELECT COALESCE(jsonb_agg(
        jsonb_build_object(
            'id', p.id,
            'url', p.url,
            'page_type', p.page_type,
            'title', p.title,
            'analysis', p.analysis
        )
    ), '[]'::JSONB)
    INTO l_pages
    FROM audit_pages p
    WHERE p.audit_id = p_id
      AND p.is_deleted = FALSE;

    -- Get payment
    SELECT jsonb_build_object(
        'id', py.id,
        'amount', py.amount,
        'currency', py.currency,
        'status', py.status,
        'paid_at', py.paid_at
    )
    INTO l_payment
    FROM payments py
    WHERE py.audit_id = p_id
      AND py.is_deleted = FALSE;

    l_result := jsonb_build_object(
        'success', TRUE,
        'data', (l_audit->'data') || jsonb_build_object(
            'fixes', l_fixes,
            'pages', l_pages,
            'payment', l_payment
        )
    );

    INSERT INTO function_log (
        function_name,
        user_id,
        input_params,
        output_result,
        execution_time_ms
    ) VALUES (
        'get_audit_with_fixes',
        p_user_id,
        jsonb_build_object('id', p_id),
        jsonb_build_object('success', TRUE, 'fixes_count', jsonb_array_length(l_fixes)),
        EXTRACT(MILLISECONDS FROM (clock_timestamp() - l_now))::INTEGER
    );

    RETURN l_result;
END;
$$;

-- ============================================
-- UPDATE AUDIT
-- ============================================
CREATE OR REPLACE FUNCTION update_audit(
    p_user_id TEXT,
    p_id TEXT,
    p_updates JSONB
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
        SELECT 1 FROM audits
        WHERE id = p_id AND is_deleted = FALSE
    ) INTO l_exists;

    IF NOT l_exists THEN
        RETURN jsonb_build_object(
            'success', FALSE,
            'error', 'Audit not found'
        );
    END IF;

    UPDATE audits
    SET
        status = COALESCE((p_updates->>'status')::audit_status, status),
        user_id = COALESCE(p_updates->>'user_id', user_id),
        share_active = COALESCE((p_updates->>'share_active')::BOOLEAN, share_active),
        mekell_score = COALESCE((p_updates->>'mekell_score')::INTEGER, mekell_score),
        synthesis = COALESCE(p_updates->'synthesis', synthesis),
        error_message = COALESCE(p_updates->>'error_message', error_message),
        warning_message = COALESCE(p_updates->>'warning_message', warning_message),
        token_usage = COALESCE((p_updates->>'token_usage')::INTEGER, token_usage),
        payment_email_sent_at = CASE
            WHEN p_updates ? 'payment_email_sent_at' THEN (p_updates->>'payment_email_sent_at')::TIMESTAMPTZ
            ELSE payment_email_sent_at
        END,
        report_email_sent_at = CASE
            WHEN p_updates ? 'report_email_sent_at' THEN (p_updates->>'report_email_sent_at')::TIMESTAMPTZ
            ELSE report_email_sent_at
        END,
        completed_at = CASE
            WHEN p_updates ? 'completed_at' THEN (p_updates->>'completed_at')::TIMESTAMPTZ
            WHEN (p_updates->>'status') = 'COMPLETED' AND completed_at IS NULL THEN l_now
            ELSE completed_at
        END,
        updated_at = l_now
    WHERE id = p_id;

    INSERT INTO function_log (
        function_name,
        user_id,
        input_params,
        output_result,
        execution_time_ms
    ) VALUES (
        'update_audit',
        p_user_id,
        jsonb_build_object('id', p_id, 'updates', p_updates - 'synthesis'),
        jsonb_build_object('success', TRUE),
        EXTRACT(MILLISECONDS FROM (clock_timestamp() - l_now))::INTEGER
    );

    RETURN get_audit(p_user_id, p_id);

EXCEPTION WHEN OTHERS THEN
    l_result := jsonb_build_object(
        'success', FALSE,
        'error', SQLERRM
    );

    INSERT INTO function_log (
        function_name,
        user_id,
        input_params,
        output_result,
        error_message
    ) VALUES (
        'update_audit',
        p_user_id,
        jsonb_build_object('id', p_id),
        l_result,
        SQLERRM
    );

    RETURN l_result;
END;
$$;

-- ============================================
-- DELETE AUDIT (Soft Delete)
-- ============================================
CREATE OR REPLACE FUNCTION delete_audit(
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
    l_exists BOOLEAN;
    l_now TIMESTAMPTZ := NOW();
BEGIN
    SELECT EXISTS(
        SELECT 1 FROM audits
        WHERE id = p_id AND is_deleted = FALSE
    ) INTO l_exists;

    IF NOT l_exists THEN
        RETURN jsonb_build_object(
            'success', FALSE,
            'error', 'Audit not found'
        );
    END IF;

    UPDATE audits
    SET
        is_deleted = TRUE,
        deleted_at = l_now,
        deleted_by = p_user_id,
        updated_at = l_now
    WHERE id = p_id;

    l_result := jsonb_build_object(
        'success', TRUE,
        'data', jsonb_build_object(
            'id', p_id,
            'deleted', TRUE
        )
    );

    INSERT INTO function_log (
        function_name,
        user_id,
        input_params,
        output_result,
        execution_time_ms
    ) VALUES (
        'delete_audit',
        p_user_id,
        jsonb_build_object('id', p_id),
        l_result,
        EXTRACT(MILLISECONDS FROM (clock_timestamp() - l_now))::INTEGER
    );

    RETURN l_result;
END;
$$;

-- ============================================
-- LIST AUDITS FOR USER
-- ============================================
CREATE OR REPLACE FUNCTION list_audits_for_user(
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
    FROM audits
    WHERE is_deleted = FALSE
      AND user_id = p_user_id
      AND (p_filters->>'status' IS NULL
           OR status = (p_filters->>'status')::audit_status);

    SELECT COALESCE(jsonb_agg(
        jsonb_build_object(
            'id', a.id,
            'domain', a.domain,
            'status', a.status,
            'mekell_score', a.mekell_score,
            'share_token', a.share_token,
            'created_at', a.created_at,
            'completed_at', a.completed_at
        ) ORDER BY a.created_at DESC
    ), '[]'::JSONB)
    INTO l_items
    FROM audits a
    WHERE a.is_deleted = FALSE
      AND a.user_id = p_user_id
      AND (p_filters->>'status' IS NULL
           OR a.status = (p_filters->>'status')::audit_status)
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
        'list_audits_for_user',
        p_user_id,
        jsonb_build_object('filters', p_filters, 'limit', p_limit, 'offset', p_offset),
        jsonb_build_object('success', TRUE, 'total', l_total),
        EXTRACT(MILLISECONDS FROM (clock_timestamp() - l_now))::INTEGER
    );

    RETURN l_result;
END;
$$;

-- ============================================
-- LIST ALL AUDITS (Admin)
-- ============================================
CREATE OR REPLACE FUNCTION list_audits(
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
    FROM audits
    WHERE is_deleted = FALSE
      AND (p_filters->>'status' IS NULL
           OR status = (p_filters->>'status')::audit_status)
      AND (p_filters->>'domain' IS NULL
           OR domain ILIKE '%' || (p_filters->>'domain') || '%');

    SELECT COALESCE(jsonb_agg(
        jsonb_build_object(
            'id', a.id,
            'domain', a.domain,
            'status', a.status,
            'email', a.email,
            'mekell_score', a.mekell_score,
            'user_id', a.user_id,
            'created_at', a.created_at,
            'completed_at', a.completed_at
        ) ORDER BY a.created_at DESC
    ), '[]'::JSONB)
    INTO l_items
    FROM audits a
    WHERE a.is_deleted = FALSE
      AND (p_filters->>'status' IS NULL
           OR a.status = (p_filters->>'status')::audit_status)
      AND (p_filters->>'domain' IS NULL
           OR a.domain ILIKE '%' || (p_filters->>'domain') || '%')
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
        'list_audits',
        p_user_id,
        jsonb_build_object('filters', p_filters, 'limit', p_limit, 'offset', p_offset),
        jsonb_build_object('success', TRUE, 'total', l_total),
        EXTRACT(MILLISECONDS FROM (clock_timestamp() - l_now))::INTEGER
    );

    RETURN l_result;
END;
$$;

-- ============================================
-- CLAIM AUDITS BY EMAIL (for new user signup)
-- ============================================
CREATE OR REPLACE FUNCTION claim_audits_by_email(
    p_user_id TEXT,
    p_email TEXT
)
RETURNS JSONB
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
    l_result JSONB;
    l_count INTEGER;
    l_now TIMESTAMPTZ := NOW();
BEGIN
    UPDATE audits
    SET
        user_id = p_user_id,
        updated_at = l_now
    WHERE email = LOWER(p_email)
      AND user_id IS NULL
      AND is_deleted = FALSE;

    GET DIAGNOSTICS l_count = ROW_COUNT;

    l_result := jsonb_build_object(
        'success', TRUE,
        'data', jsonb_build_object(
            'claimed_count', l_count
        )
    );

    INSERT INTO function_log (
        function_name,
        user_id,
        input_params,
        output_result,
        execution_time_ms
    ) VALUES (
        'claim_audits_by_email',
        p_user_id,
        jsonb_build_object('email', p_email),
        l_result,
        EXTRACT(MILLISECONDS FROM (clock_timestamp() - l_now))::INTEGER
    );

    RETURN l_result;
END;
$$;
