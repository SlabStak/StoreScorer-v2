import 'server-only';

import { callFunction, DbResult } from '../db';
import {
  PageViewCreateInput,
  ConversionEventCreateInput,
  RateLimitCheck,
  AnalyticsPeriod,
  ConversionFunnelStage,
  TopPage,
} from '@/types/db';

// =============================================================================
// PAGE VIEWS
// =============================================================================

export async function createPageView(
  userId: string,
  input: PageViewCreateInput
): Promise<DbResult<{ id: string; path: string; createdAt: Date }>> {
  const result = await callFunction<{
    id: string;
    path: string;
    created_at: string;
  }>('create_page_view', [
    userId,
    input.path,
    input.referrer,
    input.utmSource,
    input.utmMedium,
    input.utmCampaign,
    input.userAgent,
    input.ipHash,
    input.sessionId,
  ]);

  if (result.success && result.data) {
    return {
      success: true,
      data: {
        id: result.data.id,
        path: result.data.path,
        createdAt: new Date(result.data.created_at),
      },
    };
  }

  return result as DbResult<{ id: string; path: string; createdAt: Date }>;
}

export async function getPageViewAnalytics(
  userId: string,
  startDate: Date,
  endDate: Date,
  granularity: 'DAY' | 'WEEK' | 'MONTH' = 'DAY'
): Promise<DbResult<{
  granularity: string;
  startDate: Date;
  endDate: Date;
  periods: AnalyticsPeriod[];
}>> {
  const result = await callFunction<{
    granularity: string;
    start_date: string;
    end_date: string;
    periods: Array<{
      period: string;
      views: number;
      unique_sessions: number;
    }>;
  }>('get_page_view_analytics', [
    userId,
    startDate.toISOString().split('T')[0],
    endDate.toISOString().split('T')[0],
    granularity,
  ]);

  if (result.success && result.data) {
    return {
      success: true,
      data: {
        granularity: result.data.granularity,
        startDate: new Date(result.data.start_date),
        endDate: new Date(result.data.end_date),
        periods: result.data.periods.map((p) => ({
          period: new Date(p.period),
          views: p.views,
          uniqueSessions: p.unique_sessions,
        })),
      },
    };
  }

  return result as DbResult<{
    granularity: string;
    startDate: Date;
    endDate: Date;
    periods: AnalyticsPeriod[];
  }>;
}

export async function getTopPages(
  userId: string,
  days = 30,
  limit = 20
): Promise<DbResult<{ items: TopPage[]; days: number }>> {
  const result = await callFunction<{
    items: Array<{
      path: string;
      views: number;
      unique_sessions: number;
    }>;
    days: number;
  }>('get_top_pages', [userId, days, limit]);

  if (result.success && result.data) {
    return {
      success: true,
      data: {
        items: result.data.items.map((p) => ({
          path: p.path,
          views: p.views,
          uniqueSessions: p.unique_sessions,
        })),
        days: result.data.days,
      },
    };
  }

  return result as DbResult<{ items: TopPage[]; days: number }>;
}

// =============================================================================
// CONVERSION EVENTS
// =============================================================================

export async function createConversionEvent(
  userId: string,
  input: ConversionEventCreateInput
): Promise<DbResult<{ id: string; eventType: string; createdAt: Date }>> {
  const result = await callFunction<{
    id: string;
    event_type: string;
    created_at: string;
  }>('create_conversion_event', [
    userId,
    input.eventType,
    input.sessionId,
    input.auditId,
    input.metadata,
  ]);

  if (result.success && result.data) {
    return {
      success: true,
      data: {
        id: result.data.id,
        eventType: result.data.event_type,
        createdAt: new Date(result.data.created_at),
      },
    };
  }

  return result as DbResult<{ id: string; eventType: string; createdAt: Date }>;
}

export async function getConversionFunnel(
  userId: string,
  startDate: Date,
  endDate: Date
): Promise<DbResult<{
  startDate: Date;
  endDate: Date;
  funnel: ConversionFunnelStage[];
}>> {
  const result = await callFunction<{
    start_date: string;
    end_date: string;
    funnel: Array<{ stage: string; count: number }>;
  }>('get_conversion_funnel', [
    userId,
    startDate.toISOString().split('T')[0],
    endDate.toISOString().split('T')[0],
  ]);

  if (result.success && result.data) {
    return {
      success: true,
      data: {
        startDate: new Date(result.data.start_date),
        endDate: new Date(result.data.end_date),
        funnel: result.data.funnel.map((s) => ({
          stage: s.stage as ConversionFunnelStage['stage'],
          count: s.count,
        })),
      },
    };
  }

  return result as DbResult<{
    startDate: Date;
    endDate: Date;
    funnel: ConversionFunnelStage[];
  }>;
}

// =============================================================================
// RATE LIMITING
// =============================================================================

export async function createRateLimitEvent(
  userId: string,
  key: string,
  type: string
): Promise<DbResult<{ id: string; key: string; type: string; createdAt: Date }>> {
  const result = await callFunction<{
    id: string;
    key: string;
    type: string;
    created_at: string;
  }>('create_rate_limit_event', [userId, key, type]);

  if (result.success && result.data) {
    return {
      success: true,
      data: {
        id: result.data.id,
        key: result.data.key,
        type: result.data.type,
        createdAt: new Date(result.data.created_at),
      },
    };
  }

  return result as DbResult<{ id: string; key: string; type: string; createdAt: Date }>;
}

export async function checkRateLimit(
  userId: string,
  key: string,
  type: string,
  maxRequests: number,
  windowMinutes: number
): Promise<DbResult<RateLimitCheck>> {
  const result = await callFunction<{
    key: string;
    type: string;
    count: number;
    limit: number;
    remaining: number;
    is_limited: boolean;
    window_minutes: number;
  }>('check_rate_limit', [userId, key, type, maxRequests, windowMinutes]);

  if (result.success && result.data) {
    return {
      success: true,
      data: {
        key: result.data.key,
        type: result.data.type,
        count: result.data.count,
        limit: result.data.limit,
        remaining: result.data.remaining,
        isLimited: result.data.is_limited,
        windowMinutes: result.data.window_minutes,
      },
    };
  }

  return result as DbResult<RateLimitCheck>;
}

export async function cleanupRateLimitEvents(
  userId: string,
  olderThanHours = 24
): Promise<DbResult<{ deletedCount: number }>> {
  const result = await callFunction<{ deleted_count: number }>(
    'cleanup_rate_limit_events',
    [userId, olderThanHours]
  );

  if (result.success && result.data) {
    return {
      success: true,
      data: { deletedCount: result.data.deleted_count },
    };
  }

  return result as DbResult<{ deletedCount: number }>;
}
