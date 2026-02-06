import { NextRequest, NextResponse } from 'next/server';
import { getAuditByShareToken } from '@/lib/db/audits';

const SYSTEM_USER_ID = 'system';

export async function GET(
  req: NextRequest,
  { params }: { params: Promise<{ token: string }> }
) {
  try {
    const { token } = await params;

    const result = await getAuditByShareToken(SYSTEM_USER_ID, token);

    if (!result.success || !result.data) {
      return NextResponse.json(
        { error: 'Report not found' },
        { status: 404 }
      );
    }

    const audit = result.data;

    if (!audit.shareActive) {
      return NextResponse.json(
        { error: 'This report has been revoked' },
        { status: 403 }
      );
    }

    if (audit.status !== 'completed' || !audit.synthesis) {
      return NextResponse.json(
        { error: 'Report not ready' },
        { status: 404 }
      );
    }

    return NextResponse.json({
      domain: audit.domain,
      overallScore: audit.overallScore,
      synthesis: audit.synthesis,
      fixes: audit.fixes,
      createdAt: audit.createdAt,
    });
  } catch (error) {
    console.error('Get shared report error:', error);
    return NextResponse.json(
      { error: 'Failed to fetch report' },
      { status: 500 }
    );
  }
}
