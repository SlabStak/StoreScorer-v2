import 'server-only';

import { callFunction, DbResult } from '../db';
import {
  User,
  UserCreateInput,
  UserUpdateInput,
  UserListResult,
} from '@/types/db';

/**
 * Map database row (snake_case) to TypeScript object (camelCase)
 */
function mapUser(row: Record<string, unknown>): User {
  return {
    id: row.id as string,
    clerkId: row.clerk_id as string,
    email: row.email as string,
    firstName: row.first_name as string | null,
    lastName: row.last_name as string | null,
    emailNotifications: row.email_notifications as boolean,
    isAdmin: row.is_admin as boolean,
    stripeCustomerId: row.stripe_customer_id as string | null,
    stripeSubscriptionId: row.stripe_subscription_id as string | null,
    subscriptionStatus: row.subscription_status as User['subscriptionStatus'],
    subscriptionExpiresAt: row.subscription_expires_at
      ? new Date(row.subscription_expires_at as string)
      : null,
    createdAt: new Date(row.created_at as string),
    updatedAt: new Date(row.updated_at as string),
  };
}

/**
 * Create a new user
 */
export async function createUser(
  userId: string,
  input: UserCreateInput
): Promise<DbResult<User>> {
  const result = await callFunction<Record<string, unknown>>(
    'create_user',
    [userId, input.clerkId, input.email, input.firstName, input.lastName]
  );

  if (result.success && result.data) {
    return { success: true, data: mapUser(result.data) };
  }

  return result as unknown as DbResult<User>;
}

/**
 * Get user by ID
 */
export async function getUser(
  userId: string,
  id: string
): Promise<DbResult<User>> {
  const result = await callFunction<Record<string, unknown>>(
    'get_user',
    [userId, id]
  );

  if (result.success && result.data) {
    return { success: true, data: mapUser(result.data) };
  }

  return result as unknown as DbResult<User>;
}

/**
 * Get user by Clerk ID
 */
export async function getUserByClerkId(
  userId: string,
  clerkId: string
): Promise<DbResult<User>> {
  const result = await callFunction<Record<string, unknown>>(
    'get_user_by_clerk_id',
    [userId, clerkId]
  );

  if (result.success && result.data) {
    return { success: true, data: mapUser(result.data) };
  }

  return result as unknown as DbResult<User>;
}

/**
 * Get user by email
 */
export async function getUserByEmail(
  userId: string,
  email: string
): Promise<DbResult<User>> {
  const result = await callFunction<Record<string, unknown>>(
    'get_user_by_email',
    [userId, email]
  );

  if (result.success && result.data) {
    return { success: true, data: mapUser(result.data) };
  }

  return result as unknown as DbResult<User>;
}

/**
 * Update user
 */
export async function updateUser(
  userId: string,
  id: string,
  updates: UserUpdateInput
): Promise<DbResult<User>> {
  // Convert camelCase to snake_case for DB
  const dbUpdates: Record<string, unknown> = {};
  if (updates.firstName !== undefined) dbUpdates.first_name = updates.firstName;
  if (updates.lastName !== undefined) dbUpdates.last_name = updates.lastName;
  if (updates.emailNotifications !== undefined) dbUpdates.email_notifications = updates.emailNotifications;
  if (updates.stripeCustomerId !== undefined) dbUpdates.stripe_customer_id = updates.stripeCustomerId;
  if (updates.stripeSubscriptionId !== undefined) dbUpdates.stripe_subscription_id = updates.stripeSubscriptionId;
  if (updates.subscriptionStatus !== undefined) dbUpdates.subscription_status = updates.subscriptionStatus;
  if (updates.subscriptionExpiresAt !== undefined) dbUpdates.subscription_expires_at = updates.subscriptionExpiresAt?.toISOString();

  const result = await callFunction<Record<string, unknown>>(
    'update_user',
    [userId, id, dbUpdates]
  );

  if (result.success && result.data) {
    return { success: true, data: mapUser(result.data) };
  }

  return result as unknown as DbResult<User>;
}

/**
 * Delete user (soft delete)
 */
export async function deleteUser(
  userId: string,
  id: string
): Promise<DbResult<{ id: string; deleted: boolean }>> {
  return callFunction('delete_user', [userId, id]);
}

/**
 * List users (admin only)
 */
export async function listUsers(
  userId: string,
  filters: Record<string, unknown> = {},
  limit = 50,
  offset = 0
): Promise<DbResult<UserListResult>> {
  const result = await callFunction<{
    items: Record<string, unknown>[];
    total: number;
    limit: number;
    offset: number;
  }>('list_users', [userId, filters, limit, offset]);

  if (result.success && result.data) {
    return {
      success: true,
      data: {
        items: result.data.items.map(mapUser),
        total: result.data.total,
        limit: result.data.limit,
        offset: result.data.offset,
      },
    };
  }

  return result as unknown as DbResult<UserListResult>;
}
