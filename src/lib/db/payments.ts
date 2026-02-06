import 'server-only';

import { callFunction, DbResult } from '../db';
import { Payment, PaymentCreateInput, PaymentUpdateInput } from '@/types/db';

/**
 * Map database row (snake_case) to TypeScript object (camelCase)
 */
function mapPayment(row: Record<string, unknown>): Payment {
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
 * Create a new payment
 */
export async function createPayment(
  userId: string,
  input: PaymentCreateInput
): Promise<DbResult<Payment>> {
  const result = await callFunction<Record<string, unknown>>(
    'create_payment',
    [userId, input.auditId, input.stripeSessionId, input.amount, input.currency ?? 'usd']
  );

  if (result.success && result.data) {
    return { success: true, data: mapPayment(result.data) };
  }

  return result as DbResult<Payment>;
}

/**
 * Get payment by ID
 */
export async function getPayment(
  userId: string,
  id: string
): Promise<DbResult<Payment>> {
  const result = await callFunction<Record<string, unknown>>(
    'get_payment',
    [userId, id]
  );

  if (result.success && result.data) {
    return { success: true, data: mapPayment(result.data) };
  }

  return result as DbResult<Payment>;
}

/**
 * Get payment by Stripe session ID
 */
export async function getPaymentByStripeSession(
  userId: string,
  stripeSessionId: string
): Promise<DbResult<Payment>> {
  const result = await callFunction<Record<string, unknown>>(
    'get_payment_by_stripe_session',
    [userId, stripeSessionId]
  );

  if (result.success && result.data) {
    return { success: true, data: mapPayment(result.data) };
  }

  return result as DbResult<Payment>;
}

/**
 * Update payment
 */
export async function updatePayment(
  userId: string,
  id: string,
  updates: PaymentUpdateInput
): Promise<DbResult<Payment>> {
  const dbUpdates: Record<string, unknown> = {};
  if (updates.stripePaymentId !== undefined) dbUpdates.stripe_payment_id = updates.stripePaymentId;
  if (updates.status !== undefined) dbUpdates.status = updates.status;
  if (updates.paidAt !== undefined) dbUpdates.paid_at = updates.paidAt?.toISOString();

  const result = await callFunction<Record<string, unknown>>(
    'update_payment',
    [userId, id, dbUpdates]
  );

  if (result.success && result.data) {
    return { success: true, data: mapPayment(result.data) };
  }

  return result as DbResult<Payment>;
}

/**
 * Complete payment (webhook handler)
 */
export async function completePayment(
  userId: string,
  stripeSessionId: string,
  stripePaymentId: string
): Promise<DbResult<{ paymentId: string; auditId: string; status: string }>> {
  const result = await callFunction<{
    payment_id: string;
    audit_id: string;
    status: string;
  }>('complete_payment', [userId, stripeSessionId, stripePaymentId]);

  if (result.success && result.data) {
    return {
      success: true,
      data: {
        paymentId: result.data.payment_id,
        auditId: result.data.audit_id,
        status: result.data.status,
      },
    };
  }

  return result as DbResult<{ paymentId: string; auditId: string; status: string }>;
}
