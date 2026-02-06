-- ============================================
-- Payment PostgreSQL Functions
-- StoreScorer Build Standard
-- ============================================

-- ============================================
-- CREATE PAYMENT
-- ============================================
CREATE OR REPLACE FUNCTION create_payment(
    p_user_id TEXT,
    p_audit_id TEXT,
    p_stripe_session_id TEXT,
    p_amount INTEGER,
    p_currency TEXT DEFAULT 'usd'
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
    l_id := 'pay_' || gen_random_uuid()::TEXT;

    INSERT INTO payments (
        id,
        audit_id,
        stripe_session_id,
        amount,
        currency,
        status,
        created_at
    ) VALUES (
        l_id,
        p_audit_id,
        p_stripe_session_id,
        p_amount,
        p_currency,
        'PENDING',
        l_now
    );

    l_result := jsonb_build_object(
        'success', TRUE,
        'data', jsonb_build_object(
            'id', l_id,
            'audit_id', p_audit_id,
            'stripe_session_id', p_stripe_session_id,
            'amount', p_amount,
            'currency', p_currency,
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
        'create_payment',
        p_user_id,
        jsonb_build_object('audit_id', p_audit_id, 'amount', p_amount),
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
        'create_payment',
        p_user_id,
        jsonb_build_object('audit_id', p_audit_id),
        l_result,
        SQLERRM
    );

    RETURN l_result;
END;
$$;

-- ============================================
-- GET PAYMENT
-- ============================================
CREATE OR REPLACE FUNCTION get_payment(
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
    FROM payments
    WHERE id = p_id
      AND is_deleted = FALSE;

    IF NOT FOUND THEN
        RETURN jsonb_build_object(
            'success', FALSE,
            'error', 'Payment not found'
        );
    END IF;

    l_result := jsonb_build_object(
        'success', TRUE,
        'data', jsonb_build_object(
            'id', l_record.id,
            'audit_id', l_record.audit_id,
            'stripe_session_id', l_record.stripe_session_id,
            'stripe_payment_id', l_record.stripe_payment_id,
            'amount', l_record.amount,
            'currency', l_record.currency,
            'status', l_record.status,
            'created_at', l_record.created_at,
            'paid_at', l_record.paid_at
        )
    );

    RETURN l_result;
END;
$$;

-- ============================================
-- GET PAYMENT BY STRIPE SESSION
-- ============================================
CREATE OR REPLACE FUNCTION get_payment_by_stripe_session(
    p_user_id TEXT,
    p_stripe_session_id TEXT
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
    FROM payments
    WHERE stripe_session_id = p_stripe_session_id
      AND is_deleted = FALSE;

    IF NOT FOUND THEN
        RETURN jsonb_build_object(
            'success', FALSE,
            'error', 'Payment not found'
        );
    END IF;

    l_result := jsonb_build_object(
        'success', TRUE,
        'data', jsonb_build_object(
            'id', l_record.id,
            'audit_id', l_record.audit_id,
            'stripe_session_id', l_record.stripe_session_id,
            'stripe_payment_id', l_record.stripe_payment_id,
            'amount', l_record.amount,
            'currency', l_record.currency,
            'status', l_record.status,
            'created_at', l_record.created_at,
            'paid_at', l_record.paid_at
        )
    );

    INSERT INTO function_log (
        function_name,
        user_id,
        input_params,
        output_result,
        execution_time_ms
    ) VALUES (
        'get_payment_by_stripe_session',
        p_user_id,
        jsonb_build_object('stripe_session_id', LEFT(p_stripe_session_id, 20) || '...'),
        jsonb_build_object('success', TRUE),
        EXTRACT(MILLISECONDS FROM (clock_timestamp() - l_now))::INTEGER
    );

    RETURN l_result;
END;
$$;

-- ============================================
-- UPDATE PAYMENT
-- ============================================
CREATE OR REPLACE FUNCTION update_payment(
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
        SELECT 1 FROM payments
        WHERE id = p_id AND is_deleted = FALSE
    ) INTO l_exists;

    IF NOT l_exists THEN
        RETURN jsonb_build_object(
            'success', FALSE,
            'error', 'Payment not found'
        );
    END IF;

    UPDATE payments
    SET
        stripe_payment_id = COALESCE(p_updates->>'stripe_payment_id', stripe_payment_id),
        status = COALESCE((p_updates->>'status')::payment_status, status),
        paid_at = CASE
            WHEN p_updates ? 'paid_at' THEN (p_updates->>'paid_at')::TIMESTAMPTZ
            WHEN (p_updates->>'status') = 'COMPLETED' AND paid_at IS NULL THEN l_now
            ELSE paid_at
        END
    WHERE id = p_id;

    INSERT INTO function_log (
        function_name,
        user_id,
        input_params,
        output_result,
        execution_time_ms
    ) VALUES (
        'update_payment',
        p_user_id,
        jsonb_build_object('id', p_id, 'status', p_updates->>'status'),
        jsonb_build_object('success', TRUE),
        EXTRACT(MILLISECONDS FROM (clock_timestamp() - l_now))::INTEGER
    );

    RETURN get_payment(p_user_id, p_id);

EXCEPTION WHEN OTHERS THEN
    l_result := jsonb_build_object(
        'success', FALSE,
        'error', SQLERRM
    );
    RETURN l_result;
END;
$$;

-- ============================================
-- COMPLETE PAYMENT (Webhook handler)
-- ============================================
CREATE OR REPLACE FUNCTION complete_payment(
    p_user_id TEXT,
    p_stripe_session_id TEXT,
    p_stripe_payment_id TEXT
)
RETURNS JSONB
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
    l_result JSONB;
    l_payment_id TEXT;
    l_audit_id TEXT;
    l_now TIMESTAMPTZ := NOW();
BEGIN
    -- Find payment by stripe session
    SELECT id, audit_id
    INTO l_payment_id, l_audit_id
    FROM payments
    WHERE stripe_session_id = p_stripe_session_id
      AND is_deleted = FALSE;

    IF l_payment_id IS NULL THEN
        RETURN jsonb_build_object(
            'success', FALSE,
            'error', 'Payment not found'
        );
    END IF;

    -- Update payment
    UPDATE payments
    SET
        stripe_payment_id = p_stripe_payment_id,
        status = 'COMPLETED',
        paid_at = l_now
    WHERE id = l_payment_id;

    -- Update audit status
    UPDATE audits
    SET
        status = 'PAYMENT_COMPLETE',
        updated_at = l_now
    WHERE id = l_audit_id;

    l_result := jsonb_build_object(
        'success', TRUE,
        'data', jsonb_build_object(
            'payment_id', l_payment_id,
            'audit_id', l_audit_id,
            'status', 'COMPLETED'
        )
    );

    INSERT INTO function_log (
        function_name,
        user_id,
        input_params,
        output_result,
        execution_time_ms
    ) VALUES (
        'complete_payment',
        p_user_id,
        jsonb_build_object('stripe_session_id', LEFT(p_stripe_session_id, 20) || '...'),
        l_result,
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
        'complete_payment',
        p_user_id,
        jsonb_build_object('stripe_session_id', LEFT(p_stripe_session_id, 20) || '...'),
        l_result,
        SQLERRM
    );

    RETURN l_result;
END;
$$;
