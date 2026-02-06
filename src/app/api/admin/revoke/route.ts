import { NextRequest, NextResponse } from 'next/server';
import { getAuditByShareToken, updateAudit } from '@/lib/db/audits';
import { verifyAdminKey, getAuthContext } from '@/lib/auth';
import { z } from 'zod';

const RevokeSchema = z.object({
  shareToken: z.string().min(1),
});

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
    const parseResult = RevokeSchema.safeParse(body);

    if (!parseResult.success) {
      return NextResponse.json(
        { error: parseResult.error.errors[0]?.message || 'Invalid request' },
        { status: 400 }
      );
    }

    const { shareToken } = parseResult.data;
    const userId = authContext?.userId || 'system';

    // Find audit by share token
    const auditResult = await getAuditByShareToken(userId, shareToken);

    if (!auditResult.success || !auditResult.data) {
      return NextResponse.json({ error: 'Audit not found' }, { status: 404 });
    }

    // Update to revoke sharing
    const updateResult = await updateAudit(userId, auditResult.data.id, {
      shareActive: false,
    });

    if (!updateResult.success) {
      return NextResponse.json(
        { error: updateResult.error || 'Failed to revoke' },
        { status: 500 }
      );
    }

    return NextResponse.json({ success: true });
  } catch (error) {
    console.error('Revoke error:', error);
    return NextResponse.json({ error: 'Failed to revoke' }, { status: 500 });
  }
}
