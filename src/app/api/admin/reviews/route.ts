import { NextRequest, NextResponse } from 'next/server';
import { listReviews, updateReviewStatus } from '@/lib/db/reviews';
import { verifyAdminKey, getAuthContext } from '@/lib/auth';
import { z } from 'zod';

const UpdateReviewSchema = z.object({
  reviewId: z.string().min(1),
  action: z.enum(['approve', 'reject']),
});

export async function GET(req: NextRequest) {
  // Check for Clerk admin or legacy admin key
  const authContext = await getAuthContext();
  const hasAdminKey = verifyAdminKey(
    req.headers.get('authorization'),
    req.nextUrl.searchParams.get('key')
  );

  if (!authContext?.isAdmin && !hasAdminKey) {
    return NextResponse.json({ error: 'Unauthorized' }, { status: 401 });
  }

  try {
    const userId = authContext?.userId || 'system';
    const result = await listReviews(userId, {}, 100, 0);

    if (!result.success || !result.data) {
      return NextResponse.json(
        { error: result.error || 'Failed to fetch reviews' },
        { status: 500 }
      );
    }

    return NextResponse.json(result.data.items);
  } catch (error) {
    console.error('Failed to fetch reviews:', error);
    return NextResponse.json({ error: 'Failed to fetch reviews' }, { status: 500 });
  }
}

export async function POST(req: NextRequest) {
  // Check for Clerk admin or legacy admin key
  const authContext = await getAuthContext();
  const hasAdminKey = verifyAdminKey(
    req.headers.get('authorization'),
    req.nextUrl.searchParams.get('key')
  );

  if (!authContext?.isAdmin && !hasAdminKey) {
    return NextResponse.json({ error: 'Unauthorized' }, { status: 401 });
  }

  try {
    const body = await req.json();
    const parseResult = UpdateReviewSchema.safeParse(body);

    if (!parseResult.success) {
      return NextResponse.json(
        { error: parseResult.error.errors[0]?.message || 'Invalid request' },
        { status: 400 }
      );
    }

    const { reviewId, action } = parseResult.data;
    const status = action === 'approve' ? 'approved' : 'rejected';

    const userId = authContext?.userId || 'system';
    const result = await updateReviewStatus(userId, reviewId, status);

    if (!result.success) {
      return NextResponse.json(
        { error: result.error || 'Failed to update review' },
        { status: 500 }
      );
    }

    return NextResponse.json({ success: true });
  } catch (error) {
    console.error('Failed to update review:', error);
    return NextResponse.json({ error: 'Failed to update review' }, { status: 500 });
  }
}
