import 'server-only';

import { auth, currentUser } from '@clerk/nextjs/server';
import { getUserByClerkId, createUser } from './db/users';

export interface AuthContext {
  userId: string;
  clerkId: string;
  email: string;
  isAdmin: boolean;
}

export async function getAuthContext(): Promise<AuthContext | null> {
  const { userId: clerkId } = await auth();

  if (!clerkId) {
    return null;
  }

  const user = await currentUser();
  if (!user) {
    return null;
  }

  // Try to get existing user
  const existingUser = await getUserByClerkId('system', clerkId);

  let dbUserId: string;

  if (existingUser.success && existingUser.data) {
    dbUserId = existingUser.data.id;
  } else {
    // Create new user in database
    const email = user.emailAddresses[0]?.emailAddress || '';
    const newUser = await createUser('system', {
      clerkId,
      email,
      firstName: user.firstName || undefined,
      lastName: user.lastName || undefined,
    });

    if (!newUser.success || !newUser.data) {
      console.error('Failed to create user:', newUser.error);
      return null;
    }

    dbUserId = newUser.data.id;
  }

  // Check admin status (using Clerk public metadata)
  const isAdmin = user.publicMetadata?.role === 'admin';

  return {
    userId: dbUserId,
    clerkId,
    email: user.emailAddresses[0]?.emailAddress || '',
    isAdmin,
  };
}

export async function requireAuth(): Promise<AuthContext> {
  const context = await getAuthContext();

  if (!context) {
    throw new Error('Unauthorized');
  }

  return context;
}

export async function requireAdmin(): Promise<AuthContext> {
  const context = await requireAuth();

  if (!context.isAdmin) {
    throw new Error('Forbidden');
  }

  return context;
}

// Legacy admin key check for backwards compatibility
export function verifyAdminKey(
  authHeader: string | null,
  queryKey: string | null
): boolean {
  const expectedKey = process.env.ADMIN_KEY || '';
  if (!expectedKey) {
    return false;
  }

  const keyFromHeader = authHeader?.startsWith('Bearer ')
    ? authHeader.slice('Bearer '.length)
    : null;

  const key = (keyFromHeader || queryKey || '').replace(/ /g, '+');
  return key === expectedKey;
}
