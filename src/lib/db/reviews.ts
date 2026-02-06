import 'server-only';

import { callFunction, DbResult } from '../db';
import { Review, ReviewCreateInput, ReviewListResult, Testimonial } from '@/types/db';

function mapReview(row: Record<string, unknown>): Review {
  return {
    id: row.id as string,
    auditId: row.audit_id as string,
    domain: row.domain as string,
    email: row.email as string | null,
    rating: row.rating as number | null,
    helpful: row.helpful as boolean,
    comment: row.comment as string | null,
    name: row.name as string | null,
    storeName: row.store_name as string | null,
    canPublish: row.can_publish as boolean,
    status: row.status as Review['status'],
    createdAt: new Date(row.created_at as string),
    updatedAt: new Date(row.updated_at as string),
  };
}

function mapTestimonial(row: Record<string, unknown>): Testimonial {
  return {
    id: row.id as string,
    domain: row.domain as string,
    rating: row.rating as number | null,
    comment: row.comment as string,
    name: row.name as string | null,
    storeName: row.store_name as string | null,
    createdAt: new Date(row.created_at as string),
  };
}

export async function createReview(
  userId: string,
  input: ReviewCreateInput
): Promise<DbResult<Review>> {
  const result = await callFunction<Record<string, unknown>>(
    'create_review',
    [
      userId,
      input.auditId,
      input.domain,
      input.helpful,
      input.email,
      input.rating,
      input.comment,
      input.name,
      input.storeName,
      input.canPublish ?? false,
    ]
  );

  if (result.success && result.data) {
    return { success: true, data: mapReview(result.data) };
  }

  return result as DbResult<Review>;
}

export async function getReview(
  userId: string,
  id: string
): Promise<DbResult<Review>> {
  const result = await callFunction<Record<string, unknown>>(
    'get_review',
    [userId, id]
  );

  if (result.success && result.data) {
    return { success: true, data: mapReview(result.data) };
  }

  return result as DbResult<Review>;
}

export async function listReviews(
  userId: string,
  filters: Record<string, unknown> = {},
  limit = 50,
  offset = 0
): Promise<DbResult<ReviewListResult>> {
  const result = await callFunction<{
    items: Record<string, unknown>[];
    total: number;
    limit: number;
    offset: number;
  }>('list_reviews', [userId, filters, limit, offset]);

  if (result.success && result.data) {
    return {
      success: true,
      data: {
        items: result.data.items.map(mapReview),
        total: result.data.total,
        limit: result.data.limit,
        offset: result.data.offset,
      },
    };
  }

  return result as DbResult<ReviewListResult>;
}

export async function listTestimonials(
  userId: string,
  limit = 10
): Promise<DbResult<{ items: Testimonial[]; total: number }>> {
  const result = await callFunction<{
    items: Record<string, unknown>[];
    total: number;
  }>('list_testimonials', [userId, limit]);

  if (result.success && result.data) {
    return {
      success: true,
      data: {
        items: result.data.items.map(mapTestimonial),
        total: result.data.total,
      },
    };
  }

  return result as DbResult<{ items: Testimonial[]; total: number }>;
}

export async function updateReviewStatus(
  userId: string,
  id: string,
  status: Review['status']
): Promise<DbResult<Review>> {
  const result = await callFunction<Record<string, unknown>>(
    'update_review_status',
    [userId, id, status]
  );

  if (result.success && result.data) {
    return { success: true, data: mapReview(result.data) };
  }

  return result as DbResult<Review>;
}
