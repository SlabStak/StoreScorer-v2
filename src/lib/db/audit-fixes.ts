import 'server-only';

import { callFunction, DbResult } from '../db';
import { AuditFix, AuditFixCreateInput } from '@/types/db';

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

export async function createAuditFix(
  userId: string,
  input: AuditFixCreateInput
): Promise<DbResult<AuditFix>> {
  const result = await callFunction<Record<string, unknown>>(
    'create_audit_fix',
    [
      userId,
      input.auditId,
      input.rank,
      input.title,
      input.category,
      input.impact,
      input.description,
      input.evidence,
      input.recommendation,
      input.confidence,
    ]
  );

  if (result.success && result.data) {
    return { success: true, data: mapFix(result.data) };
  }

  return result as unknown as DbResult<AuditFix>;
}

export async function getAuditFix(
  userId: string,
  id: string
): Promise<DbResult<AuditFix>> {
  const result = await callFunction<Record<string, unknown>>(
    'get_audit_fix',
    [userId, id]
  );

  if (result.success && result.data) {
    return { success: true, data: mapFix(result.data) };
  }

  return result as unknown as DbResult<AuditFix>;
}

export async function listAuditFixes(
  userId: string,
  auditId: string
): Promise<DbResult<{ items: AuditFix[]; total: number }>> {
  const result = await callFunction<{
    items: Record<string, unknown>[];
    total: number;
  }>('list_audit_fixes', [userId, auditId]);

  if (result.success && result.data) {
    return {
      success: true,
      data: {
        items: result.data.items.map(mapFix),
        total: result.data.total,
      },
    };
  }

  return result as unknown as DbResult<{ items: AuditFix[]; total: number }>;
}

export async function bulkCreateAuditFixes(
  userId: string,
  auditId: string,
  fixes: Omit<AuditFixCreateInput, 'auditId'>[]
): Promise<DbResult<{ ids: string[]; count: number }>> {
  const fixesWithTypes = fixes.map((f) => ({
    rank: f.rank,
    title: f.title,
    category: f.category,
    impact: f.impact,
    description: f.description,
    evidence: f.evidence,
    recommendation: f.recommendation,
    confidence: f.confidence,
  }));

  return callFunction('bulk_create_audit_fixes', [userId, auditId, fixesWithTypes]);
}

export async function deleteAuditFixesForAudit(
  userId: string,
  auditId: string
): Promise<DbResult<{ deletedCount: number }>> {
  const result = await callFunction<{ deleted_count: number }>(
    'delete_audit_fixes_for_audit',
    [userId, auditId]
  );

  if (result.success && result.data) {
    return {
      success: true,
      data: { deletedCount: result.data.deleted_count },
    };
  }

  return result as unknown as DbResult<{ deletedCount: number }>;
}
