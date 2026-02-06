-- ============================================
-- Chat Message PostgreSQL Functions
-- StoreScorer Build Standard
-- ============================================

-- ============================================
-- CREATE CHAT MESSAGE
-- ============================================
CREATE OR REPLACE FUNCTION create_chat_message(
    p_user_id TEXT,
    p_audit_id TEXT,
    p_role TEXT,
    p_content TEXT
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
    l_id := 'cmsg_' || gen_random_uuid()::TEXT;

    INSERT INTO chat_messages (
        id,
        audit_id,
        user_id,
        role,
        content,
        created_at
    ) VALUES (
        l_id,
        p_audit_id,
        p_user_id,
        p_role::chat_role,
        p_content,
        l_now
    );

    l_result := jsonb_build_object(
        'success', TRUE,
        'data', jsonb_build_object(
            'id', l_id,
            'audit_id', p_audit_id,
            'user_id', p_user_id,
            'role', p_role,
            'content', p_content,
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
        'create_chat_message',
        p_user_id,
        jsonb_build_object('audit_id', p_audit_id, 'role', p_role, 'content_length', LENGTH(p_content)),
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
-- LIST CHAT MESSAGES FOR AUDIT
-- ============================================
CREATE OR REPLACE FUNCTION list_chat_messages(
    p_user_id TEXT,
    p_audit_id TEXT,
    p_limit INTEGER DEFAULT 100
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
            'id', m.id,
            'audit_id', m.audit_id,
            'user_id', m.user_id,
            'role', m.role,
            'content', m.content,
            'created_at', m.created_at
        ) ORDER BY m.created_at ASC
    ), '[]'::JSONB)
    INTO l_items
    FROM chat_messages m
    WHERE m.audit_id = p_audit_id
      AND m.is_deleted = FALSE
    LIMIT p_limit;

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
        'list_chat_messages',
        p_user_id,
        jsonb_build_object('audit_id', p_audit_id, 'limit', p_limit),
        jsonb_build_object('success', TRUE, 'count', jsonb_array_length(l_items)),
        EXTRACT(MILLISECONDS FROM (clock_timestamp() - l_now))::INTEGER
    );

    RETURN l_result;
END;
$$;

-- ============================================
-- COUNT CHAT MESSAGES FOR USER
-- ============================================
CREATE OR REPLACE FUNCTION count_user_chat_messages(
    p_user_id TEXT,
    p_since TIMESTAMPTZ DEFAULT NULL
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
    l_since TIMESTAMPTZ := COALESCE(p_since, NOW() - INTERVAL '24 hours');
BEGIN
    SELECT COUNT(*)
    INTO l_count
    FROM chat_messages
    WHERE user_id = p_user_id
      AND role = 'USER'
      AND created_at >= l_since
      AND is_deleted = FALSE;

    l_result := jsonb_build_object(
        'success', TRUE,
        'data', jsonb_build_object(
            'count', l_count,
            'since', l_since
        )
    );

    RETURN l_result;
END;
$$;

-- ============================================
-- DELETE CHAT MESSAGES FOR AUDIT
-- ============================================
CREATE OR REPLACE FUNCTION delete_chat_messages_for_audit(
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
    UPDATE chat_messages
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
        'delete_chat_messages_for_audit',
        p_user_id,
        jsonb_build_object('audit_id', p_audit_id),
        l_result,
        EXTRACT(MILLISECONDS FROM (clock_timestamp() - l_now))::INTEGER
    );

    RETURN l_result;
END;
$$;
