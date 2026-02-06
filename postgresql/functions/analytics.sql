-- ============================================
-- Analytics PostgreSQL Functions
-- (Page Views, Conversion Events, Rate Limits)
-- StoreScorer Build Standard
-- ============================================

-- ============================================
-- CREATE PAGE VIEW
-- ============================================
CREATE OR REPLACE FUNCTION create_page_view(
    p_user_id TEXT,
    p_path TEXT,
    p_referrer TEXT DEFAULT NULL,
    p_utm_source TEXT DEFAULT NULL,
    p_utm_medium TEXT DEFAULT NULL,
    p_utm_campaign TEXT DEFAULT NULL,
    p_user_agent TEXT DEFAULT NULL,
    p_ip_hash TEXT DEFAULT NULL,
    p_session_id TEXT DEFAULT NULL
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
    l_id := 'pv_' || gen_random_uuid()::TEXT;

    INSERT INTO page_views (
        id,
        path,
        referrer,
        utm_source,
        utm_medium,
        utm_campaign,
        user_agent,
        ip_hash,
        session_id,
        user_id,
        created_at
    ) VALUES (
        l_id,
        p_path,
        p_referrer,
        p_utm_source,
        p_utm_medium,
        p_utm_campaign,
        p_user_agent,
        p_ip_hash,
        p_session_id,
        NULLIF(p_user_id, 'system'),
        l_now
    );

    l_result := jsonb_build_object(
        'success', TRUE,
        'data', jsonb_build_object(
            'id', l_id,
            'path', p_path,
            'created_at', l_now
        )
    );

    -- Skip function_log for high-volume analytics
    RETURN l_result;

EXCEPTION WHEN OTHERS THEN
    RETURN jsonb_build_object(
        'success', FALSE,
        'error', SQLERRM
    );
END;
$$;

-- ============================================
-- GET PAGE VIEW ANALYTICS
-- ============================================
CREATE OR REPLACE FUNCTION get_page_view_analytics(
    p_user_id TEXT,
    p_start_date DATE,
    p_end_date DATE,
    p_granularity TEXT DEFAULT 'DAY'
)
RETURNS JSONB
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
    l_result JSONB;
    l_data JSONB;
    l_now TIMESTAMPTZ := NOW();
BEGIN
    WITH date_series AS (
        SELECT generate_series(
            p_start_date::TIMESTAMP,
            p_end_date::TIMESTAMP,
            CASE p_granularity
                WHEN 'DAY' THEN '1 day'::INTERVAL
                WHEN 'WEEK' THEN '1 week'::INTERVAL
                WHEN 'MONTH' THEN '1 month'::INTERVAL
            END
        ) AS period_start
    ),
    aggregated AS (
        SELECT
            ds.period_start,
            COUNT(pv.id) AS views,
            COUNT(DISTINCT pv.session_id) AS unique_sessions
        FROM date_series ds
        LEFT JOIN page_views pv ON
            DATE_TRUNC(LOWER(p_granularity), pv.created_at) = ds.period_start
        GROUP BY ds.period_start
        ORDER BY ds.period_start
    )
    SELECT jsonb_agg(
        jsonb_build_object(
            'period', period_start,
            'views', views,
            'unique_sessions', unique_sessions
        )
    )
    INTO l_data
    FROM aggregated;

    l_result := jsonb_build_object(
        'success', TRUE,
        'data', jsonb_build_object(
            'granularity', p_granularity,
            'start_date', p_start_date,
            'end_date', p_end_date,
            'periods', COALESCE(l_data, '[]'::JSONB)
        )
    );

    INSERT INTO function_log (
        function_name,
        user_id,
        input_params,
        output_result,
        execution_time_ms
    ) VALUES (
        'get_page_view_analytics',
        p_user_id,
        jsonb_build_object('start_date', p_start_date, 'end_date', p_end_date),
        jsonb_build_object('success', TRUE),
        EXTRACT(MILLISECONDS FROM (clock_timestamp() - l_now))::INTEGER
    );

    RETURN l_result;
END;
$$;

-- ============================================
-- GET TOP PAGES
-- ============================================
CREATE OR REPLACE FUNCTION get_top_pages(
    p_user_id TEXT,
    p_days INTEGER DEFAULT 30,
    p_limit INTEGER DEFAULT 20
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
            'path', path,
            'views', views,
            'unique_sessions', unique_sessions
        )
    ), '[]'::JSONB)
    INTO l_items
    FROM (
        SELECT
            path,
            COUNT(*) AS views,
            COUNT(DISTINCT session_id) AS unique_sessions
        FROM page_views
        WHERE created_at >= NOW() - (p_days || ' days')::INTERVAL
        GROUP BY path
        ORDER BY views DESC
        LIMIT p_limit
    ) t;

    l_result := jsonb_build_object(
        'success', TRUE,
        'data', jsonb_build_object(
            'items', l_items,
            'days', p_days
        )
    );

    RETURN l_result;
END;
$$;

-- ============================================
-- CREATE CONVERSION EVENT
-- ============================================
CREATE OR REPLACE FUNCTION create_conversion_event(
    p_user_id TEXT,
    p_event_type TEXT,
    p_session_id TEXT DEFAULT NULL,
    p_audit_id TEXT DEFAULT NULL,
    p_metadata JSONB DEFAULT NULL
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
    l_id := 'cev_' || gen_random_uuid()::TEXT;

    INSERT INTO conversion_events (
        id,
        event_type,
        session_id,
        user_id,
        audit_id,
        metadata,
        created_at
    ) VALUES (
        l_id,
        p_event_type::conversion_event_type,
        p_session_id,
        NULLIF(p_user_id, 'system'),
        p_audit_id,
        p_metadata,
        l_now
    );

    l_result := jsonb_build_object(
        'success', TRUE,
        'data', jsonb_build_object(
            'id', l_id,
            'event_type', p_event_type,
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
        'create_conversion_event',
        p_user_id,
        jsonb_build_object('event_type', p_event_type, 'audit_id', p_audit_id),
        jsonb_build_object('success', TRUE, 'id', l_id),
        EXTRACT(MILLISECONDS FROM (clock_timestamp() - l_now))::INTEGER
    );

    RETURN l_result;

EXCEPTION WHEN OTHERS THEN
    RETURN jsonb_build_object(
        'success', FALSE,
        'error', SQLERRM
    );
END;
$$;

-- ============================================
-- GET CONVERSION FUNNEL
-- ============================================
CREATE OR REPLACE FUNCTION get_conversion_funnel(
    p_user_id TEXT,
    p_start_date DATE,
    p_end_date DATE
)
RETURNS JSONB
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
    l_result JSONB;
    l_now TIMESTAMPTZ := NOW();
    l_landing INTEGER;
    l_checkout INTEGER;
    l_payment INTEGER;
    l_delivered INTEGER;
BEGIN
    SELECT COUNT(*) INTO l_landing
    FROM conversion_events
    WHERE event_type = 'LANDING_VIEW'
      AND created_at >= p_start_date
      AND created_at < p_end_date + INTERVAL '1 day';

    SELECT COUNT(*) INTO l_checkout
    FROM conversion_events
    WHERE event_type = 'CHECKOUT_INITIATED'
      AND created_at >= p_start_date
      AND created_at < p_end_date + INTERVAL '1 day';

    SELECT COUNT(*) INTO l_payment
    FROM conversion_events
    WHERE event_type = 'PAYMENT_COMPLETE'
      AND created_at >= p_start_date
      AND created_at < p_end_date + INTERVAL '1 day';

    SELECT COUNT(*) INTO l_delivered
    FROM conversion_events
    WHERE event_type = 'AUDIT_DELIVERED'
      AND created_at >= p_start_date
      AND created_at < p_end_date + INTERVAL '1 day';

    l_result := jsonb_build_object(
        'success', TRUE,
        'data', jsonb_build_object(
            'start_date', p_start_date,
            'end_date', p_end_date,
            'funnel', jsonb_build_array(
                jsonb_build_object('stage', 'LANDING_VIEW', 'count', l_landing),
                jsonb_build_object('stage', 'CHECKOUT_INITIATED', 'count', l_checkout),
                jsonb_build_object('stage', 'PAYMENT_COMPLETE', 'count', l_payment),
                jsonb_build_object('stage', 'AUDIT_DELIVERED', 'count', l_delivered)
            )
        )
    );

    INSERT INTO function_log (
        function_name,
        user_id,
        input_params,
        output_result,
        execution_time_ms
    ) VALUES (
        'get_conversion_funnel',
        p_user_id,
        jsonb_build_object('start_date', p_start_date, 'end_date', p_end_date),
        l_result,
        EXTRACT(MILLISECONDS FROM (clock_timestamp() - l_now))::INTEGER
    );

    RETURN l_result;
END;
$$;

-- ============================================
-- CREATE RATE LIMIT EVENT
-- ============================================
CREATE OR REPLACE FUNCTION create_rate_limit_event(
    p_user_id TEXT,
    p_key TEXT,
    p_type TEXT
)
RETURNS JSONB
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
    l_id TEXT;
    l_now TIMESTAMPTZ := NOW();
BEGIN
    l_id := 'rle_' || gen_random_uuid()::TEXT;

    INSERT INTO rate_limit_events (
        id,
        key,
        type,
        created_at
    ) VALUES (
        l_id,
        p_key,
        p_type,
        l_now
    );

    RETURN jsonb_build_object(
        'success', TRUE,
        'data', jsonb_build_object(
            'id', l_id,
            'key', p_key,
            'type', p_type,
            'created_at', l_now
        )
    );

EXCEPTION WHEN OTHERS THEN
    RETURN jsonb_build_object(
        'success', FALSE,
        'error', SQLERRM
    );
END;
$$;

-- ============================================
-- CHECK RATE LIMIT
-- ============================================
CREATE OR REPLACE FUNCTION check_rate_limit(
    p_user_id TEXT,
    p_key TEXT,
    p_type TEXT,
    p_max_requests INTEGER,
    p_window_minutes INTEGER
)
RETURNS JSONB
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
    l_count INTEGER;
    l_window_start TIMESTAMPTZ := NOW() - (p_window_minutes || ' minutes')::INTERVAL;
BEGIN
    SELECT COUNT(*)
    INTO l_count
    FROM rate_limit_events
    WHERE key = p_key
      AND type = p_type
      AND created_at >= l_window_start;

    RETURN jsonb_build_object(
        'success', TRUE,
        'data', jsonb_build_object(
            'key', p_key,
            'type', p_type,
            'count', l_count,
            'limit', p_max_requests,
            'remaining', GREATEST(0, p_max_requests - l_count),
            'is_limited', l_count >= p_max_requests,
            'window_minutes', p_window_minutes
        )
    );
END;
$$;

-- ============================================
-- CLEANUP OLD RATE LIMIT EVENTS
-- ============================================
CREATE OR REPLACE FUNCTION cleanup_rate_limit_events(
    p_user_id TEXT,
    p_older_than_hours INTEGER DEFAULT 24
)
RETURNS JSONB
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
    l_count INTEGER;
    l_now TIMESTAMPTZ := NOW();
BEGIN
    DELETE FROM rate_limit_events
    WHERE created_at < NOW() - (p_older_than_hours || ' hours')::INTERVAL;

    GET DIAGNOSTICS l_count = ROW_COUNT;

    INSERT INTO function_log (
        function_name,
        user_id,
        input_params,
        output_result,
        execution_time_ms
    ) VALUES (
        'cleanup_rate_limit_events',
        p_user_id,
        jsonb_build_object('older_than_hours', p_older_than_hours),
        jsonb_build_object('success', TRUE, 'deleted_count', l_count),
        EXTRACT(MILLISECONDS FROM (clock_timestamp() - l_now))::INTEGER
    );

    RETURN jsonb_build_object(
        'success', TRUE,
        'data', jsonb_build_object(
            'deleted_count', l_count
        )
    );
END;
$$;
