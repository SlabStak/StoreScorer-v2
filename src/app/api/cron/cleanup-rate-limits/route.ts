import { NextRequest, NextResponse } from 'next/server';
import { cleanupRateLimitEvents } from '@/lib/db/analytics';

export const runtime = 'nodejs';
export const dynamic = 'force-dynamic';

const SYSTEM_USER_ID = 'system';

// Verify cron secret to prevent unauthorized access
function verifyCronSecret(req: NextRequest): boolean {
  const cronSecret = process.env.CRON_SECRET;
  if (!cronSecret) {
    return process.env.NODE_ENV === 'development';
  }

  const authHeader = req.headers.get('authorization');
  return authHeader === `Bearer ${cronSecret}`;
}

export async function GET(req: NextRequest) {
  if (!verifyCronSecret(req)) {
    return NextResponse.json({ error: 'Unauthorized' }, { status: 401 });
  }

  try {
    // Clean up rate limit events older than 24 hours
    const result = await cleanupRateLimitEvents(SYSTEM_USER_ID, 24);

    if (!result.success) {
      return NextResponse.json({ error: result.error }, { status: 500 });
    }

    return NextResponse.json({
      success: true,
      deletedCount: result.data?.deletedCount || 0,
    });
  } catch (error) {
    console.error('Cleanup rate limits error:', error);
    return NextResponse.json(
      { error: 'Failed to cleanup rate limits' },
      { status: 500 }
    );
  }
}
