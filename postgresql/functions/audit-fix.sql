-- ============================================
-- Audit Fix PostgreSQL Functions
-- StoreScorer Build Standard
-- ============================================

-- ============================================
-- CREATE AUDIT FIX
-- ============================================
CREATE OR REPLACE FUNCTION create_audit_fix(
    p_user_id TEXT,
    p_audit_id TEXT,
    p_rank INTEGER,
    p_title TEXT,
    p_category TEXT,
    p_impact TEXT,
    p_description TEXT,
    p_evidence TEXT,
    p_recommendation TEXT,
    p_confidence REAL
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
    l_id := 'afx_' || gen_random_uuid()::TEXT;

    INSERT INTO audit_fixes (
        id,
        audit_id,
        rank,
        title,
        category,
        impact,
        description,
        evidence,
        recommendation,
        confidence,
        created_at
    ) VALUES (
        l_id,
        p_audit_id,
        p_rank,
        p_title,
        p_category,
        p_impact::impact_level,
        p_description,
        p_evidence,
        p_recommendation,
        p_confidence,
        l_now
    );

    l_result := jsonb_build_object(
        'success', TRUE,
        'data', jsonb_build_object(
            'id', l_id,
            'audit_id', p_audit_id,
            'rank', p_rank,
            'title', p_title,
            'category', p_category,
            'impact', p_impact,
            'confidence', p_confidence,
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
        'create_audit_fix',
        p_user_id,
        jsonb_build_object('audit_id', p_audit_id, 'rank', p_rank, 'title', p_title),
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
-- GET AUDIT FIX
-- ============================================
CREATE OR REPLACE FUNCTION get_audit_fix(
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
    FROM audit_fixes
    WHERE id = p_id
      AND is_deleted = FALSE;

    IF NOT FOUND THEN
        RETURN jsonb_build_object(
            'success', FALSE,
            'error', 'Audit fix not found'
        );
    END IF;

    l_result := jsonb_build_object(
        'success', TRUE,
        'data', jsonb_build_object(
            'id', l_record.id,
            'audit_id', l_record.audit_id,
            'rank', l_record.rank,
            'title', l_record.title,
            'category', l_record.category,
            'impact', l_record.impact,
            'description', l_record.description,
            'evidence', l_record.evidence,
            'recommendation', l_record.recommendation,
            'confidence', l_record.confidence,
            'created_at', l_record.created_at
        )
    );

    RETURN l_result;
END;
$$;

-- ============================================
-- LIST AUDIT FIXES
-- ============================================
CREATE OR REPLACE FUNCTION list_audit_fixes(
    p_user_id TEXT,
    p_audit_id TEXT
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
            'id', f.id,
            'rank', f.rank,
            'title', f.title,
            'category', f.category,
            'impact', f.impact,
            'description', f.description,
            'evidence', f.evidence,
            'recommendation', f.recommendation,
            'confidence', f.confidence,
            'created_at', f.created_at
        ) ORDER BY f.rank
    ), '[]'::JSONB)
    INTO l_items
    FROM audit_fixes f
    WHERE f.audit_id = p_audit_id
      AND f.is_deleted = FALSE;

    l_result := jsonb_build_object(
        'success', TRUE,
        'data', jsonb_build_object(
            'items', l_items,
            'total', jsonb_array_length(l_items)
        )
    );

    INSERT INTO function_log (
        function_name,
        user_id,
        input_params,
        output_result,
        execution_time_ms
    ) VALUES (
        'list_audit_fixes',
        p_user_id,
        jsonb_build_object('audit_id', p_audit_id),
        jsonb_build_object('success', TRUE, 'count', jsonb_array_length(l_items)),
        EXTRACT(MILLISECONDS FROM (clock_timestamp() - l_now))::INTEGER
    );

    RETURN l_result;
END;
$$;

-- ============================================
-- BULK CREATE AUDIT FIXES
-- ============================================
CREATE OR REPLACE FUNCTION bulk_create_audit_fixes(
    p_user_id TEXT,
    p_audit_id TEXT,
    p_fixes JSONB
)
RETURNS JSONB
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
    l_fix JSONB;
    l_id TEXT;
    l_ids TEXT[] := '{}';
    l_result JSONB;
    l_now TIMESTAMPTZ := NOW();
BEGIN
    FOR l_fix IN SELECT * FROM jsonb_array_elements(p_fixes)
    LOOP
        l_id := 'afx_' || gen_random_uuid()::TEXT;
        l_ids := array_append(l_ids, l_id);

        INSERT INTO audit_fixes (
            id,
            audit_id,
            rank,
            title,
            category,
            impact,
            description,
            evidence,
            recommendation,
            confidence,
            created_at
        ) VALUES (
            l_id,
            p_audit_id,
            (l_fix->>'rank')::INTEGER,
            l_fix->>'title',
            l_fix->>'category',
            (l_fix->>'impact')::impact_level,
            l_fix->>'description',
            l_fix->>'evidence',
            l_fix->>'recommendation',
            (l_fix->>'confidence')::REAL,
            l_now
        );
    END LOOP;

    l_result := jsonb_build_object(
        'success', TRUE,
        'data', jsonb_build_object(
            'ids', to_jsonb(l_ids),
            'count', array_length(l_ids, 1)
        )
    );

    INSERT INTO function_log (
        function_name,
        user_id,
        input_params,
        output_result,
        execution_time_ms
    ) VALUES (
        'bulk_create_audit_fixes',
        p_user_id,
        jsonb_build_object('audit_id', p_audit_id, 'count', jsonb_array_length(p_fixes)),
        l_result,
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
-- DELETE AUDIT FIXES FOR AUDIT
-- ============================================
CREATE OR REPLACE FUNCTION delete_audit_fixes_for_audit(
    p_user_id TEXT,
    p_audit_id TEXT
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
    UPDATE audit_fixes
    SET
        is_deleted = TRUE,
        deleted_at = l_now,
        deleted_by = p_user_id
    WHERE audit_id = p_audit_id
      AND is_deleted = FALSE;

    GET DIAGNOSTICS l_count = ROW_COUNT;

    l_result := jsonb_build_object(
        'success', TRUE,
        'data', jsonb_build_object(
            'deleted_count', l_count
        )
    );

    INSERT INTO function_log (
        function_name,
        user_id,
        input_params,
        output_result,
        execution_time_ms
    ) VALUES (
        'delete_audit_fixes_for_audit',
        p_user_id,
        jsonb_build_object('audit_id', p_audit_id),
        l_result,
        EXTRACT(MILLISECONDS FROM (clock_timestamp() - l_now))::INTEGER
    );

    RETURN l_result;
END;
$$;
