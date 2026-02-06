-- ============================================
-- User PostgreSQL Functions
-- StoreScorer Build Standard
-- ============================================

-- ============================================
-- CREATE USER
-- ============================================
CREATE OR REPLACE FUNCTION create_user(
    p_user_id TEXT,
    p_clerk_id TEXT,
    p_email TEXT,
    p_first_name TEXT DEFAULT NULL,
    p_last_name TEXT DEFAULT NULL
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
    -- Generate prefixed UUID
    l_id := 'usr_' || gen_random_uuid()::TEXT;

    -- Insert record
    INSERT INTO users (
        id,
        clerk_id,
        email,
        first_name,
        last_name,
        created_at,
        updated_at
    ) VALUES (
        l_id,
        p_clerk_id,
        p_email,
        p_first_name,
        p_last_name,
        l_now,
        l_now
    );

    -- Build result
    l_result := jsonb_build_object(
        'success', TRUE,
        'data', jsonb_build_object(
            'id', l_id,
            'clerk_id', p_clerk_id,
            'email', p_email,
            'first_name', p_first_name,
            'last_name', p_last_name,
            'email_notifications', TRUE,
            'is_admin', FALSE,
            'subscription_status', 'NONE',
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
        'create_user',
        p_user_id,
        jsonb_build_object('clerk_id', p_clerk_id, 'email', p_email),
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
        'create_user',
        p_user_id,
        jsonb_build_object('clerk_id', p_clerk_id, 'email', p_email),
        l_result,
        SQLERRM
    );

    RETURN l_result;
END;
$$;

-- ============================================
-- GET USER BY ID
-- ============================================
CREATE OR REPLACE FUNCTION get_user(
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
    FROM users
    WHERE id = p_id
      AND is_deleted = FALSE;

    IF NOT FOUND THEN
        RETURN jsonb_build_object(
            'success', FALSE,
            'error', 'User not found'
        );
    END IF;

    l_result := jsonb_build_object(
        'success', TRUE,
        'data', jsonb_build_object(
            'id', l_record.id,
            'clerk_id', l_record.clerk_id,
            'email', l_record.email,
            'first_name', l_record.first_name,
            'last_name', l_record.last_name,
            'email_notifications', l_record.email_notifications,
            'is_admin', l_record.is_admin,
            'stripe_customer_id', l_record.stripe_customer_id,
            'stripe_subscription_id', l_record.stripe_subscription_id,
            'subscription_status', l_record.subscription_status,
            'subscription_expires_at', l_record.subscription_expires_at,
            'created_at', l_record.created_at,
            'updated_at', l_record.updated_at
        )
    );

    INSERT INTO function_log (
        function_name,
        user_id,
        input_params,
        output_result,
        execution_time_ms
    ) VALUES (
        'get_user',
        p_user_id,
        jsonb_build_object('id', p_id),
        jsonb_build_object('success', TRUE),
        EXTRACT(MILLISECONDS FROM (clock_timestamp() - l_now))::INTEGER
    );

    RETURN l_result;
END;
$$;

-- ============================================
-- GET USER BY CLERK ID
-- ============================================
CREATE OR REPLACE FUNCTION get_user_by_clerk_id(
    p_user_id TEXT,
    p_clerk_id TEXT
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
    FROM users
    WHERE clerk_id = p_clerk_id
      AND is_deleted = FALSE;

    IF NOT FOUND THEN
        RETURN jsonb_build_object(
            'success', FALSE,
            'error', 'User not found'
        );
    END IF;

    l_result := jsonb_build_object(
        'success', TRUE,
        'data', jsonb_build_object(
            'id', l_record.id,
            'clerk_id', l_record.clerk_id,
            'email', l_record.email,
            'first_name', l_record.first_name,
            'last_name', l_record.last_name,
            'email_notifications', l_record.email_notifications,
            'is_admin', l_record.is_admin,
            'stripe_customer_id', l_record.stripe_customer_id,
            'stripe_subscription_id', l_record.stripe_subscription_id,
            'subscription_status', l_record.subscription_status,
            'subscription_expires_at', l_record.subscription_expires_at,
            'created_at', l_record.created_at,
            'updated_at', l_record.updated_at
        )
    );

    INSERT INTO function_log (
        function_name,
        user_id,
        input_params,
        output_result,
        execution_time_ms
    ) VALUES (
        'get_user_by_clerk_id',
        p_user_id,
        jsonb_build_object('clerk_id', p_clerk_id),
        jsonb_build_object('success', TRUE),
        EXTRACT(MILLISECONDS FROM (clock_timestamp() - l_now))::INTEGER
    );

    RETURN l_result;
END;
$$;

-- ============================================
-- GET USER BY EMAIL
-- ============================================
CREATE OR REPLACE FUNCTION get_user_by_email(
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
    l_record RECORD;
    l_now TIMESTAMPTZ := NOW();
BEGIN
    SELECT *
    INTO l_record
    FROM users
    WHERE email = LOWER(p_email)
      AND is_deleted = FALSE;

    IF NOT FOUND THEN
        RETURN jsonb_build_object(
            'success', FALSE,
            'error', 'User not found'
        );
    END IF;

    l_result := jsonb_build_object(
        'success', TRUE,
        'data', jsonb_build_object(
            'id', l_record.id,
            'clerk_id', l_record.clerk_id,
            'email', l_record.email,
            'first_name', l_record.first_name,
            'last_name', l_record.last_name,
            'email_notifications', l_record.email_notifications,
            'is_admin', l_record.is_admin,
            'stripe_customer_id', l_record.stripe_customer_id,
            'subscription_status', l_record.subscription_status,
            'created_at', l_record.created_at,
            'updated_at', l_record.updated_at
        )
    );

    INSERT INTO function_log (
        function_name,
        user_id,
        input_params,
        output_result,
        execution_time_ms
    ) VALUES (
        'get_user_by_email',
        p_user_id,
        jsonb_build_object('email', p_email),
        jsonb_build_object('success', TRUE),
        EXTRACT(MILLISECONDS FROM (clock_timestamp() - l_now))::INTEGER
    );

    RETURN l_result;
END;
$$;

-- ============================================
-- UPDATE USER
-- ============================================
CREATE OR REPLACE FUNCTION update_user(
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
        SELECT 1 FROM users
        WHERE id = p_id AND is_deleted = FALSE
    ) INTO l_exists;

    IF NOT l_exists THEN
        RETURN jsonb_build_object(
            'success', FALSE,
            'error', 'User not found'
        );
    END IF;

    UPDATE users
    SET
        first_name = COALESCE(p_updates->>'first_name', first_name),
        last_name = COALESCE(p_updates->>'last_name', last_name),
        email_notifications = COALESCE((p_updates->>'email_notifications')::BOOLEAN, email_notifications),
        stripe_customer_id = COALESCE(p_updates->>'stripe_customer_id', stripe_customer_id),
        stripe_subscription_id = COALESCE(p_updates->>'stripe_subscription_id', stripe_subscription_id),
        subscription_status = COALESCE((p_updates->>'subscription_status')::subscription_status, subscription_status),
        subscription_expires_at = CASE
            WHEN p_updates ? 'subscription_expires_at' THEN (p_updates->>'subscription_expires_at')::TIMESTAMPTZ
            ELSE subscription_expires_at
        END,
        updated_at = l_now
    WHERE id = p_id;

    RETURN get_user(p_user_id, p_id);

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
        'update_user',
        p_user_id,
        jsonb_build_object('id', p_id, 'updates', p_updates),
        l_result,
        SQLERRM
    );

    RETURN l_result;
END;
$$;

-- ============================================
-- DELETE USER (Soft Delete)
-- ============================================
CREATE OR REPLACE FUNCTION delete_user(
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
        SELECT 1 FROM users
        WHERE id = p_id AND is_deleted = FALSE
    ) INTO l_exists;

    IF NOT l_exists THEN
        RETURN jsonb_build_object(
            'success', FALSE,
            'error', 'User not found'
        );
    END IF;

    UPDATE users
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
        'delete_user',
        p_user_id,
        jsonb_build_object('id', p_id),
        l_result,
        EXTRACT(MILLISECONDS FROM (clock_timestamp() - l_now))::INTEGER
    );

    RETURN l_result;
END;
$$;

-- ============================================
-- LIST USERS (Admin only)
-- ============================================
CREATE OR REPLACE FUNCTION list_users(
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
    FROM users
    WHERE is_deleted = FALSE
      AND (p_filters->>'subscription_status' IS NULL
           OR subscription_status = (p_filters->>'subscription_status')::subscription_status);

    SELECT COALESCE(jsonb_agg(
        jsonb_build_object(
            'id', u.id,
            'clerk_id', u.clerk_id,
            'email', u.email,
            'first_name', u.first_name,
            'last_name', u.last_name,
            'is_admin', u.is_admin,
            'subscription_status', u.subscription_status,
            'created_at', u.created_at
        ) ORDER BY u.created_at DESC
    ), '[]'::JSONB)
    INTO l_items
    FROM users u
    WHERE u.is_deleted = FALSE
      AND (p_filters->>'subscription_status' IS NULL
           OR u.subscription_status = (p_filters->>'subscription_status')::subscription_status)
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
        'list_users',
        p_user_id,
        jsonb_build_object('filters', p_filters, 'limit', p_limit, 'offset', p_offset),
        jsonb_build_object('success', TRUE, 'total', l_total),
        EXTRACT(MILLISECONDS FROM (clock_timestamp() - l_now))::INTEGER
    );

    RETURN l_result;
END;
$$;
