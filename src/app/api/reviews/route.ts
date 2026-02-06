import { NextRequest, NextResponse } from 'next/server';
import { getAudit } from '@/lib/db/audits';
import { createReview } from '@/lib/db/reviews';
import { ReviewRequestSchema } from '@/lib/validation';

const SYSTEM_USER_ID = 'system';

export async function POST(req: NextRequest) {
  try {
    const body = await req.json();

    // Validate request
    const parseResult = ReviewRequestSchema.safeParse(body);
    if (!parseResult.success) {
      return NextResponse.json(
        { error: parseResult.error.errors[0]?.message || 'Invalid request' },
        { status: 400 }
      );
    }

    const { auditId, helpful, rating, comment, name, storeName, canPublish } = parseResult.data;

    // Get audit to extract domain and email
    const auditResult = await getAudit(SYSTEM_USER_ID, auditId);

    if (!auditResult.success || !auditResult.data) {
      return NextResponse.json({ error: 'Audit not found' }, { status: 404 });
    }

    const audit = auditResult.data;

    // Create review
    const reviewResult = await createReview(SYSTEM_USER_ID, {
      auditId,
      domain: audit.domain,
      email: audit.email || undefined,
      helpful,
      rating,
      comment,
      name,
      storeName,
      canPublish: canPublish || false,
    });

    if (!reviewResult.success || !reviewResult.data) {
      return NextResponse.json(
        { error: reviewResult.error || 'Failed to submit review' },
        { status: 500 }
      );
    }

    return NextResponse.json({ success: true, reviewId: reviewResult.data.id });
  } catch (error) {
    console.error('Review submission error:', error);
    return NextResponse.json({ error: 'Failed to submit review' }, { status: 500 });
  }
}
