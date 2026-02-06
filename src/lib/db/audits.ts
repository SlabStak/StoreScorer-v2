import 'server-only';

import { callFunction, DbResult } from '../db';
import {
  Audit,
  AuditWithRelations,
  AuditCreateInput,
  AuditUpdateInput,
  AuditListResult,
  AuditFix,
  AuditPage,
  AuditPageSummary,
  Payment,
} from '@/types/db';

/**
 * Map database row (snake_case) to TypeScript object (camelCase)
 */
function mapAudit(row: Record<string, unknown>): Audit {
  const mekellScore = row.mekell_score as number | null;
  return {
    id: row.id as string,
    domain: row.domain as string,
    status: row.status as Audit['status'],
    userId: row.user_id as string | null,
    shareToken: row.share_token as string,
    shareActive: row.share_active as boolean,
    shareViewCount: row.share_view_count as number,
    mekellScore,
    overallScore: (row.overall_score as number | null) ?? mekellScore,
    synthesis: row.synthesis as Record<string, unknown> | null,
    errorMessage: row.error_message as string | null,
    warningMessage: row.warning_message as string | null,
    tokenUsage: row.token_usage as number,
    email: row.email as string | null,
    marketingConsent: row.marketing_consent as boolean,
    createdIp: row.created_ip as string | null,
    userAgent: row.user_agent as string | null,
    utmSource: row.utm_source as string | null,
    utmMedium: row.utm_medium as string | null,
    utmCampaign: row.utm_campaign as string | null,
    paymentEmailSentAt: row.payment_email_sent_at
      ? new Date(row.payment_email_sent_at as string)
      : null,
    reportEmailSentAt: row.report_email_sent_at
      ? new Date(row.report_email_sent_at as string)
      : null,
    createdAt: new Date(row.created_at as string),
    updatedAt: new Date(row.updated_at as string),
    completedAt: row.completed_at
      ? new Date(row.completed_at as string)
      : null,
  };
}

function mapFix(row: Record<string, unknown>): AuditFix {
  return {
    id: row.id as string,
    auditId: row.audit_id as string,
    rank: row.rank as number,
    title: row.title as string,
    category: row.category as string,
    impact: row.impact as AuditFix['impact'],
    description: row.description as string,
    evidence: row.evidence as string,
    recommendation: row.recommendation as string,
    confidence: row.confidence as number,
    createdAt: new Date(row.created_at as string),
  };
}

function mapPage(row: Record<string, unknown>): AuditPageSummary {
  return {
    id: row.id as string,
    auditId: row.audit_id as string,
    url: row.url as string,
    pageType: row.page_type as AuditPage['pageType'],
    title: row.title as string | null,
    analysis: row.analysis as Record<string, unknown> | null,
    crawledAt: new Date(row.crawled_at as string),
  };
}

function mapPayment(row: Record<string, unknown> | null): Payment | null {
  if (!row) return null;
  return {
    id: row.id as string,
    auditId: row.audit_id as string,
    stripeSessionId: row.stripe_session_id as string,
    stripePaymentId: row.stripe_payment_id as string | null,
    amount: row.amount as number,
    currency: row.currency as string,
    status: row.status as Payment['status'],
    createdAt: new Date(row.created_at as string),
    paidAt: row.paid_at ? new Date(row.paid_at as string) : null,
  };
}

/**
 * Create a new audit
 */
export async function createAudit(
  userId: string,
  input: AuditCreateInput
): Promise<DbResult<Audit>> {
  const result = await callFunction<Record<string, unknown>>(
    'create_audit',
    [
      userId,
      input.domain,
      input.email,
      input.marketingConsent ?? false,
      input.createdIp,
      input.userAgent,
      input.utmSource,
      input.utmMedium,
      input.utmCampaign,
    ]
  );

  if (result.success && result.data) {
    return { success: true, data: mapAudit(result.data) };
  }

  return result as unknown as DbResult<Audit>;
}

/**
 * Get audit by ID
 */
export async function getAudit(
  userId: string,
  id: string
): Promise<DbResult<Audit>> {
  const result = await callFunction<Record<string, unknown>>(
    'get_audit',
    [userId, id]
  );

  if (result.success && result.data) {
    return { success: true, data: mapAudit(result.data) };
  }

  return result as unknown as DbResult<Audit>;
}

/**
 * Get audit by share token
 */
export async function getAuditByShareToken(
  userId: string,
  shareToken: string
): Promise<DbResult<Audit>> {
  const result = await callFunction<Record<string, unknown>>(
    'get_audit_by_share_token',
    [userId, shareToken]
  );

  if (result.success && result.data) {
    return { success: true, data: mapAudit(result.data) };
  }

  return result as unknown as DbResult<Audit>;
}

/**
 * Get audit with all related data (fixes, pages, payment)
 */
export async function getAuditWithRelations(
  userId: string,
  id: string
): Promise<DbResult<AuditWithRelations>> {
  const result = await callFunction<Record<string, unknown>>(
    'get_audit_with_fixes',
    [userId, id]
  );

  if (result.success && result.data) {
    const audit = mapAudit(result.data);
    const fixes = (result.data.fixes as Record<string, unknown>[]).map(mapFix);
    const pages = (result.data.pages as Record<string, unknown>[]).map(mapPage) as AuditPage[];
    const payment = mapPayment(result.data.payment as Record<string, unknown> | null);

    return {
      success: true,
      data: { ...audit, fixes, pages, payment },
    };
  }

  return result as unknown as DbResult<AuditWithRelations>;
}

/**
 * Update audit
 */
export async function updateAudit(
  userId: string,
  id: string,
  updates: AuditUpdateInput
): Promise<DbResult<Audit>> {
  // Convert camelCase to snake_case for DB
  const dbUpdates: Record<string, unknown> = {};
  if (updates.status !== undefined) dbUpdates.status = updates.status;
  if (updates.userId !== undefined) dbUpdates.user_id = updates.userId;
  if (updates.shareActive !== undefined) dbUpdates.share_active = updates.shareActive;
  if (updates.mekellScore !== undefined) dbUpdates.mekell_score = updates.mekellScore;
  if (updates.synthesis !== undefined) dbUpdates.synthesis = updates.synthesis;
  if (updates.errorMessage !== undefined) dbUpdates.error_message = updates.errorMessage;
  if (updates.warningMessage !== undefined) dbUpdates.warning_message = updates.warningMessage;
  if (updates.tokenUsage !== undefined) dbUpdates.token_usage = updates.tokenUsage;
  if (updates.paymentEmailSentAt !== undefined) dbUpdates.payment_email_sent_at = updates.paymentEmailSentAt?.toISOString();
  if (updates.reportEmailSentAt !== undefined) dbUpdates.report_email_sent_at = updates.reportEmailSentAt?.toISOString();
  if (updates.completedAt !== undefined) dbUpdates.completed_at = updates.completedAt?.toISOString();

  const result = await callFunction<Record<string, unknown>>(
    'update_audit',
    [userId, id, dbUpdates]
  );

  if (result.success && result.data) {
    return { success: true, data: mapAudit(result.data) };
  }

  return result as unknown as DbResult<Audit>;
}

/**
 * Delete audit (soft delete)
 */
export async function deleteAudit(
  userId: string,
  id: string
): Promise<DbResult<{ id: string; deleted: boolean }>> {
  return callFunction('delete_audit', [userId, id]);
}

/**
 * List audits for a user
 */
export async function listAuditsForUser(
  userId: string,
  filters: Record<string, unknown> = {},
  limit = 50,
  offset = 0
): Promise<DbResult<AuditListResult>> {
  const result = await callFunction<{
    items: Record<string, unknown>[];
    total: number;
    limit: number;
    offset: number;
  }>('list_audits_for_user', [userId, filters, limit, offset]);

  if (result.success && result.data) {
    return {
      success: true,
      data: {
        items: result.data.items.map(mapAudit),
        total: result.data.total,
        limit: result.data.limit,
        offset: result.data.offset,
      },
    };
  }

  return result as unknown as DbResult<AuditListResult>;
}

/**
 * List all audits (admin)
 */
export async function listAudits(
  userId: string,
  filters: Record<string, unknown> = {},
  limit = 50,
  offset = 0
): Promise<DbResult<AuditListResult>> {
  const result = await callFunction<{
    items: Record<string, unknown>[];
    total: number;
    limit: number;
    offset: number;
  }>('list_audits', [userId, filters, limit, offset]);

  if (result.success && result.data) {
    return {
      success: true,
      data: {
        items: result.data.items.map(mapAudit),
        total: result.data.total,
        limit: result.data.limit,
        offset: result.data.offset,
      },
    };
  }

  return result as unknown as DbResult<AuditListResult>;
}

/**
 * Claim audits by email (for new user signup)
 */
export async function claimAuditsByEmail(
  userId: string,
  email: string
): Promise<DbResult<{ claimedCount: number }>> {
  const result = await callFunction<{ claimed_count: number }>(
    'claim_audits_by_email',
    [userId, email]
  );

  if (result.success && result.data) {
    return {
      success: true,
      data: { claimedCount: result.data.claimed_count },
    };
  }

  return result as unknown as DbResult<{ claimedCount: number }>;
}
