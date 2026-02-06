import 'server-only';

import { callFunction, DbResult } from '../db';
import { AuditJob, AuditJobCreateInput } from '@/types/db';

function mapJob(row: Record<string, unknown>): AuditJob {
  return {
    id: row.id as string,
    auditId: row.audit_id as string,
    status: row.status as AuditJob['status'],
    attempts: row.attempts as number,
    lastError: row.last_error as string | null,
    lockedAt: row.locked_at ? new Date(row.locked_at as string) : null,
    createdAt: new Date(row.created_at as string),
    updatedAt: new Date(row.updated_at as string),
  };
}

export async function createAuditJob(
  userId: string,
  input: AuditJobCreateInput
): Promise<DbResult<AuditJob>> {
  const result = await callFunction<Record<string, unknown>>(
    'create_audit_job',
    [userId, input.auditId]
  );

  if (result.success && result.data) {
    return { success: true, data: mapJob(result.data) };
  }

  return result as unknown as DbResult<AuditJob>;
}

export async function getPendingJobs(
  userId: string,
  limit = 10,
  lockTimeoutMinutes = 5
): Promise<DbResult<{ items: AuditJob[]; total: number }>> {
  const result = await callFunction<{
    items: Record<string, unknown>[];
    total: number;
  }>('get_pending_jobs', [userId, limit, lockTimeoutMinutes]);

  if (result.success && result.data) {
    return {
      success: true,
      data: {
        items: result.data.items.map(mapJob),
        total: result.data.total,
      },
    };
  }

  return result as unknown as DbResult<{ items: AuditJob[]; total: number }>;
}

export async function lockJob(
  userId: string,
  jobId: string
): Promise<DbResult<{ id: string; locked: boolean; lockedAt: Date }>> {
  const result = await callFunction<{
    id: string;
    locked: boolean;
    locked_at: string;
  }>('lock_job', [userId, jobId]);

  if (result.success && result.data) {
    return {
      success: true,
      data: {
        id: result.data.id,
        locked: result.data.locked,
        lockedAt: new Date(result.data.locked_at),
      },
    };
  }

  return result as unknown as DbResult<{ id: string; locked: boolean; lockedAt: Date }>;
}

export async function completeJob(
  userId: string,
  jobId: string
): Promise<DbResult<{ id: string; status: string }>> {
  return callFunction('complete_job', [userId, jobId]);
}

export async function failJob(
  userId: string,
  jobId: string,
  error: string
): Promise<DbResult<{ id: string; status: string; error: string }>> {
  return callFunction('fail_job', [userId, jobId, error]);
}

export async function retryJob(
  userId: string,
  jobId: string
): Promise<DbResult<{ id: string; status: string }>> {
  return callFunction('retry_job', [userId, jobId]);
}

export async function getJobByAuditId(
  userId: string,
  auditId: string
): Promise<DbResult<AuditJob>> {
  const result = await callFunction<Record<string, unknown>>(
    'get_job_by_audit_id',
    [userId, auditId]
  );

  if (result.success && result.data) {
    return { success: true, data: mapJob(result.data) };
  }

  return result as unknown as DbResult<AuditJob>;
}
