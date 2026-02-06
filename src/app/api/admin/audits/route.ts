import { NextRequest, NextResponse } from 'next/server';
import { listAudits } from '@/lib/db/audits';
import { verifyAdminKey, getAuthContext } from '@/lib/auth';

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
    const result = await listAudits(userId, {}, 50, 0);

    if (!result.success || !result.data) {
      return NextResponse.json(
        { error: result.error || 'Failed to fetch audits' },
        { status: 500 }
      );
    }

    return NextResponse.json({ audits: result.data.items });
  } catch (error) {
    console.error('Admin fetch error:', error);
    return NextResponse.json({ error: 'Failed to fetch audits' }, { status: 500 });
  }
}
