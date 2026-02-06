-- ============================================
-- Audit Page PostgreSQL Functions
-- StoreScorer Build Standard
-- ============================================

-- ============================================
-- CREATE AUDIT PAGE
-- ============================================
CREATE OR REPLACE FUNCTION create_audit_page(
    p_user_id TEXT,
    p_audit_id TEXT,
    p_url TEXT,
    p_page_type TEXT,
    p_title TEXT,
    p_html TEXT,
    p_clean_text TEXT,
    p_analysis JSONB DEFAULT NULL
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
    l_id := 'apg_' || gen_random_uuid()::TEXT;

    INSERT INTO audit_pages (
        id,
        audit_id,
        url,
        page_type,
        title,
        html,
        clean_text,
        analysis,
        crawled_at
    ) VALUES (
        l_id,
        p_audit_id,
        p_url,
        p_page_type::page_type,
        p_title,
        p_html,
        p_clean_text,
        p_analysis,
        l_now
    );

    l_result := jsonb_build_object(
        'success', TRUE,
        'data', jsonb_build_object(
            'id', l_id,
            'audit_id', p_audit_id,
            'url', p_url,
            'page_type', p_page_type,
            'title', p_title,
            'crawled_at', l_now
        )
    );

    INSERT INTO function_log (
        function_name,
        user_id,
        input_params,
        output_result,
        execution_time_ms
    ) VALUES (
        'create_audit_page',
        p_user_id,
        jsonb_build_object('audit_id', p_audit_id, 'url', p_url, 'page_type', p_page_type),
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
-- GET AUDIT PAGE
-- ============================================
CREATE OR REPLACE FUNCTION get_audit_page(
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
    FROM audit_pages
    WHERE id = p_id
      AND is_deleted = FALSE;

    IF NOT FOUND THEN
        RETURN jsonb_build_object(
            'success', FALSE,
            'error', 'Audit page not found'
        );
    END IF;

    l_result := jsonb_build_object(
        'success', TRUE,
        'data', jsonb_build_object(
            'id', l_record.id,
            'audit_id', l_record.audit_id,
            'url', l_record.url,
            'page_type', l_record.page_type,
            'title', l_record.title,
            'html', l_record.html,
            'clean_text', l_record.clean_text,
            'analysis', l_record.analysis,
            'crawled_at', l_record.crawled_at
        )
    );

    RETURN l_result;
END;
$$;

-- ============================================
-- LIST AUDIT PAGES
-- ============================================
CREATE OR REPLACE FUNCTION list_audit_pages(
    p_user_id TEXT,
    p_audit_id TEXT,
    p_include_html BOOLEAN DEFAULT FALSE
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
    IF p_include_html THEN
        SELECT COALESCE(jsonb_agg(
            jsonb_build_object(
                'id', p.id,
                'url', p.url,
                'page_type', p.page_type,
                'title', p.title,
                'html', p.html,
                'clean_text', p.clean_text,
                'analysis', p.analysis,
                'crawled_at', p.crawled_at
            )
        ), '[]'::JSONB)
        INTO l_items
        FROM audit_pages p
        WHERE p.audit_id = p_audit_id
          AND p.is_deleted = FALSE;
    ELSE
        SELECT COALESCE(jsonb_agg(
            jsonb_build_object(
                'id', p.id,
                'url', p.url,
                'page_type', p.page_type,
                'title', p.title,
                'analysis', p.analysis,
                'crawled_at', p.crawled_at
            )
        ), '[]'::JSONB)
        INTO l_items
        FROM audit_pages p
        WHERE p.audit_id = p_audit_id
          AND p.is_deleted = FALSE;
    END IF;

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
        'list_audit_pages',
        p_user_id,
        jsonb_build_object('audit_id', p_audit_id, 'include_html', p_include_html),
        jsonb_build_object('success', TRUE, 'count', jsonb_array_length(l_items)),
        EXTRACT(MILLISECONDS FROM (clock_timestamp() - l_now))::INTEGER
    );

    RETURN l_result;
END;
$$;

-- ============================================
-- UPDATE AUDIT PAGE ANALYSIS
-- ============================================
CREATE OR REPLACE FUNCTION update_audit_page_analysis(
    p_user_id TEXT,
    p_id TEXT,
    p_analysis JSONB
)
RETURNS JSONB
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
    l_result JSONB;
    l_exists BOOLEAN;
BEGIN
    SELECT EXISTS(
        SELECT 1 FROM audit_pages
        WHERE id = p_id AND is_deleted = FALSE
    ) INTO l_exists;

    IF NOT l_exists THEN
        RETURN jsonb_build_object(
            'success', FALSE,
            'error', 'Audit page not found'
        );
    END IF;

    UPDATE audit_pages
    SET analysis = p_analysis
    WHERE id = p_id;

    RETURN get_audit_page(p_user_id, p_id);
END;
$$;

-- ============================================
-- BULK CREATE AUDIT PAGES
-- ============================================
CREATE OR REPLACE FUNCTION bulk_create_audit_pages(
    p_user_id TEXT,
    p_audit_id TEXT,
    p_pages JSONB
)
RETURNS JSONB
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
    l_page JSONB;
    l_id TEXT;
    l_ids TEXT[] := '{}';
    l_result JSONB;
    l_now TIMESTAMPTZ := NOW();
BEGIN
    FOR l_page IN SELECT * FROM jsonb_array_elements(p_pages)
    LOOP
        l_id := 'apg_' || gen_random_uuid()::TEXT;
        l_ids := array_append(l_ids, l_id);

        INSERT INTO audit_pages (
            id,
            audit_id,
            url,
            page_type,
            title,
            html,
            clean_text,
            analysis,
            crawled_at
        ) VALUES (
            l_id,
            p_audit_id,
            l_page->>'url',
            (l_page->>'page_type')::page_type,
            l_page->>'title',
            l_page->>'html',
            l_page->>'clean_text',
            l_page->'analysis',
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
        'bulk_create_audit_pages',
        p_user_id,
        jsonb_build_object('audit_id', p_audit_id, 'count', jsonb_array_length(p_pages)),
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
