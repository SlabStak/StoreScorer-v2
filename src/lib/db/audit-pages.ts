import 'server-only';

import { callFunction, DbResult } from '../db';
import { AuditPage, AuditPageSummary, AuditPageCreateInput } from '@/types/db';

function mapPage(row: Record<string, unknown>): AuditPage {
  return {
    id: row.id as string,
    auditId: row.audit_id as string,
    url: row.url as string,
    pageType: row.page_type as AuditPage['pageType'],
    title: row.title as string | null,
    html: row.html as string,
    cleanText: row.clean_text as string,
    analysis: row.analysis as Record<string, unknown> | null,
    crawledAt: new Date(row.crawled_at as string),
  };
}

function mapPageSummary(row: Record<string, unknown>): AuditPageSummary {
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

export async function createAuditPage(
  userId: string,
  input: AuditPageCreateInput
): Promise<DbResult<AuditPageSummary>> {
  const result = await callFunction<Record<string, unknown>>(
    'create_audit_page',
    [
      userId,
      input.auditId,
      input.url,
      input.pageType,
      input.title,
      input.html,
      input.cleanText,
      input.analysis,
    ]
  );

  if (result.success && result.data) {
    return { success: true, data: mapPageSummary(result.data) };
  }

  return result as DbResult<AuditPageSummary>;
}

export async function getAuditPage(
  userId: string,
  id: string
): Promise<DbResult<AuditPage>> {
  const result = await callFunction<Record<string, unknown>>(
    'get_audit_page',
    [userId, id]
  );

  if (result.success && result.data) {
    return { success: true, data: mapPage(result.data) };
  }

  return result as DbResult<AuditPage>;
}

export async function listAuditPages(
  userId: string,
  auditId: string,
  includeHtml = false
): Promise<DbResult<{ items: AuditPageSummary[]; total: number }>> {
  const result = await callFunction<{
    items: Record<string, unknown>[];
    total: number;
  }>('list_audit_pages', [userId, auditId, includeHtml]);

  if (result.success && result.data) {
    return {
      success: true,
      data: {
        items: result.data.items.map(includeHtml ? mapPage : mapPageSummary) as AuditPageSummary[],
        total: result.data.total,
      },
    };
  }

  return result as DbResult<{ items: AuditPageSummary[]; total: number }>;
}

export async function updateAuditPageAnalysis(
  userId: string,
  id: string,
  analysis: Record<string, unknown>
): Promise<DbResult<AuditPage>> {
  const result = await callFunction<Record<string, unknown>>(
    'update_audit_page_analysis',
    [userId, id, analysis]
  );

  if (result.success && result.data) {
    return { success: true, data: mapPage(result.data) };
  }

  return result as DbResult<AuditPage>;
}

export async function bulkCreateAuditPages(
  userId: string,
  auditId: string,
  pages: Omit<AuditPageCreateInput, 'auditId'>[]
): Promise<DbResult<{ ids: string[]; count: number }>> {
  const pagesWithTypes = pages.map((p) => ({
    url: p.url,
    page_type: p.pageType,
    title: p.title,
    html: p.html,
    clean_text: p.cleanText,
    analysis: p.analysis,
  }));

  return callFunction('bulk_create_audit_pages', [userId, auditId, pagesWithTypes]);
}
