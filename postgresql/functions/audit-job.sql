-- ============================================
-- Audit Job PostgreSQL Functions
-- StoreScorer Build Standard
-- ============================================

-- ============================================
-- CREATE AUDIT JOB
-- ============================================
CREATE OR REPLACE FUNCTION create_audit_job(
    p_user_id TEXT,
    p_audit_id TEXT
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
    l_id := 'ajob_' || gen_random_uuid()::TEXT;

    INSERT INTO audit_jobs (
        id,
        audit_id,
        status,
        attempts,
        created_at,
        updated_at
    ) VALUES (
        l_id,
        p_audit_id,
        'PENDING',
        0,
        l_now,
        l_now
    );

    l_result := jsonb_build_object(
        'success', TRUE,
        'data', jsonb_build_object(
            'id', l_id,
            'audit_id', p_audit_id,
            'status', 'PENDING',
            'attempts', 0,
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
        'create_audit_job',
        p_user_id,
        jsonb_build_object('audit_id', p_audit_id),
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
-- GET PENDING JOBS (for worker)
-- ============================================
CREATE OR REPLACE FUNCTION get_pending_jobs(
    p_user_id TEXT,
    p_limit INTEGER DEFAULT 10,
    p_lock_timeout_minutes INTEGER DEFAULT 5
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
    l_lock_threshold TIMESTAMPTZ := NOW() - (p_lock_timeout_minutes || ' minutes')::INTERVAL;
BEGIN
    -- Get jobs that are pending or have stale locks
    SELECT COALESCE(jsonb_agg(
        jsonb_build_object(
            'id', j.id,
            'audit_id', j.audit_id,
            'status', j.status,
            'attempts', j.attempts,
            'last_error', j.last_error,
            'created_at', j.created_at
        )
    ), '[]'::JSONB)
    INTO l_items
    FROM audit_jobs j
    WHERE j.is_deleted = FALSE
      AND (
        (j.status = 'PENDING')
        OR (j.status = 'PROCESSING' AND j.locked_at < l_lock_threshold)
      )
    ORDER BY j.created_at
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
        'get_pending_jobs',
        p_user_id,
        jsonb_build_object('limit', p_limit),
        jsonb_build_object('success', TRUE, 'count', jsonb_array_length(l_items)),
        EXTRACT(MILLISECONDS FROM (clock_timestamp() - l_now))::INTEGER
    );

    RETURN l_result;
END;
$$;

-- ============================================
-- LOCK JOB (claim for processing)
-- ============================================
CREATE OR REPLACE FUNCTION lock_job(
    p_user_id TEXT,
    p_job_id TEXT
)
RETURNS JSONB
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
    l_result JSONB;
    l_updated BOOLEAN;
    l_now TIMESTAMPTZ := NOW();
BEGIN
    -- Try to lock the job atomically
    UPDATE audit_jobs
    SET
        status = 'PROCESSING',
        locked_at = l_now,
        attempts = attempts + 1,
        updated_at = l_now
    WHERE id = p_job_id
      AND is_deleted = FALSE
      AND (
        status = 'PENDING'
        OR (status = 'PROCESSING' AND locked_at < NOW() - INTERVAL '5 minutes')
      );

    GET DIAGNOSTICS l_updated = ROW_COUNT > 0;

    IF NOT l_updated THEN
        RETURN jsonb_build_object(
            'success', FALSE,
            'error', 'Job not available or already locked'
        );
    END IF;

    l_result := jsonb_build_object(
        'success', TRUE,
        'data', jsonb_build_object(
            'id', p_job_id,
            'locked', TRUE,
            'locked_at', l_now
        )
    );

    INSERT INTO function_log (
        function_name,
        user_id,
        input_params,
        output_result,
        execution_time_ms
    ) VALUES (
        'lock_job',
        p_user_id,
        jsonb_build_object('job_id', p_job_id),
        l_result,
        EXTRACT(MILLISECONDS FROM (clock_timestamp() - l_now))::INTEGER
    );

    RETURN l_result;
END;
$$;

-- ============================================
-- COMPLETE JOB
-- ============================================
CREATE OR REPLACE FUNCTION complete_job(
    p_user_id TEXT,
    p_job_id TEXT
)
RETURNS JSONB
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
    l_result JSONB;
    l_now TIMESTAMPTZ := NOW();
BEGIN
    UPDATE audit_jobs
    SET
        status = 'COMPLETED',
        locked_at = NULL,
        updated_at = l_now
    WHERE id = p_job_id
      AND is_deleted = FALSE;

    l_result := jsonb_build_object(
        'success', TRUE,
        'data', jsonb_build_object(
            'id', p_job_id,
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
        'complete_job',
        p_user_id,
        jsonb_build_object('job_id', p_job_id),
        l_result,
        EXTRACT(MILLISECONDS FROM (clock_timestamp() - l_now))::INTEGER
    );

    RETURN l_result;
END;
$$;

-- ============================================
-- FAIL JOB
-- ============================================
CREATE OR REPLACE FUNCTION fail_job(
    p_user_id TEXT,
    p_job_id TEXT,
    p_error TEXT
)
RETURNS JSONB
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
    l_result JSONB;
    l_now TIMESTAMPTZ := NOW();
BEGIN
    UPDATE audit_jobs
    SET
        status = 'FAILED',
        last_error = p_error,
        locked_at = NULL,
        updated_at = l_now
    WHERE id = p_job_id
      AND is_deleted = FALSE;

    l_result := jsonb_build_object(
        'success', TRUE,
        'data', jsonb_build_object(
            'id', p_job_id,
            'status', 'FAILED',
            'error', p_error
        )
    );

    INSERT INTO function_log (
        function_name,
        user_id,
        input_params,
        output_result,
        execution_time_ms
    ) VALUES (
        'fail_job',
        p_user_id,
        jsonb_build_object('job_id', p_job_id, 'error', LEFT(p_error, 100)),
        l_result,
        EXTRACT(MILLISECONDS FROM (clock_timestamp() - l_now))::INTEGER
    );

    RETURN l_result;
END;
$$;

-- ============================================
-- RETRY JOB (reset to pending)
-- ============================================
CREATE OR REPLACE FUNCTION retry_job(
    p_user_id TEXT,
    p_job_id TEXT
)
RETURNS JSONB
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
    l_result JSONB;
    l_now TIMESTAMPTZ := NOW();
BEGIN
    UPDATE audit_jobs
    SET
        status = 'PENDING',
        last_error = NULL,
        locked_at = NULL,
        updated_at = l_now
    WHERE id = p_job_id
      AND is_deleted = FALSE;

    l_result := jsonb_build_object(
        'success', TRUE,
        'data', jsonb_build_object(
            'id', p_job_id,
            'status', 'PENDING'
        )
    );

    INSERT INTO function_log (
        function_name,
        user_id,
        input_params,
        output_result,
        execution_time_ms
    ) VALUES (
        'retry_job',
        p_user_id,
        jsonb_build_object('job_id', p_job_id),
        l_result,
        EXTRACT(MILLISECONDS FROM (clock_timestamp() - l_now))::INTEGER
    );

    RETURN l_result;
END;
$$;

-- ============================================
-- GET JOB BY AUDIT ID
-- ============================================
CREATE OR REPLACE FUNCTION get_job_by_audit_id(
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
    l_record RECORD;
BEGIN
    SELECT *
    INTO l_record
    FROM audit_jobs
    WHERE audit_id = p_audit_id
      AND is_deleted = FALSE
    ORDER BY created_at DESC
    LIMIT 1;

    IF NOT FOUND THEN
        RETURN jsonb_build_object(
            'success', FALSE,
            'error', 'Job not found'
        );
    END IF;

    l_result := jsonb_build_object(
        'success', TRUE,
        'data', jsonb_build_object(
            'id', l_record.id,
            'audit_id', l_record.audit_id,
            'status', l_record.status,
            'attempts', l_record.attempts,
            'last_error', l_record.last_error,
            'locked_at', l_record.locked_at,
            'created_at', l_record.created_at,
            'updated_at', l_record.updated_at
        )
    );

    RETURN l_result;
END;
$$;
