import { NextRequest, NextResponse } from 'next/server';
import { getAuditWithRelations, updateAudit } from '@/lib/db/audits';
import { completePayment } from '@/lib/db/payments';
import { createAuditJob, getJobByAuditId } from '@/lib/db/audit-jobs';
import { getStripe } from '@/lib/stripe';

export const runtime = 'nodejs';
export const maxDuration = 60;
export const dynamic = 'force-dynamic';

const SYSTEM_USER_ID = 'system';

export async function GET(
  req: NextRequest,
  { params }: { params: Promise<{ id: string }> }
) {
  try {
    const { id } = await params;
    const shouldReconcile = req.nextUrl.searchParams.get('reconcile') === '1';
    const shouldKick = req.nextUrl.searchParams.get('kick') === '1';

    // Get audit with fixes
    let auditResult = await getAuditWithRelations(SYSTEM_USER_ID, id);

    if (!auditResult.success || !auditResult.data) {
      return NextResponse.json(
        { error: auditResult.error || 'Audit not found' },
        { status: 404 }
      );
    }

    let audit = auditResult.data;

    // Optional payment reconciliation
    if (shouldReconcile && (audit.status === 'PENDING' || audit.status === 'PAYMENT_PENDING')) {
      if (audit.payment?.stripeSessionId) {
        try {
          const stripe = getStripe();
          const session = await stripe.checkout.sessions.retrieve(audit.payment.stripeSessionId);

          if (session.payment_status === 'paid') {
            const customerEmail = session.customer_details?.email || session.customer_email;

            // Complete the payment
            const paymentIntentId = session.payment_intent;
            await completePayment(
              SYSTEM_USER_ID,
              audit.payment.id,
              typeof paymentIntentId === 'string' ? paymentIntentId : undefined
            );

            // Update audit status
            await updateAudit(SYSTEM_USER_ID, id, {
              status: 'PAYMENT_COMPLETE',
              ...(customerEmail ? { email: customerEmail } : {}),
            });

            // Refresh audit data
            auditResult = await getAuditWithRelations(SYSTEM_USER_ID, id);
            if (auditResult.success && auditResult.data) {
              audit = auditResult.data;
            }
          }
        } catch (error) {
          console.error(`[audit-${id}] Payment reconciliation failed:`, error);
        }
      }
    }

    // Optional processing kick
    if (
      shouldKick &&
      (audit.status === 'PAYMENT_COMPLETE' || audit.status === 'CRAWLING' || audit.status === 'ANALYZING')
    ) {
      const existingJob = await getJobByAuditId(SYSTEM_USER_ID, id);

      if (!existingJob.success || !existingJob.data) {
        await createAuditJob(SYSTEM_USER_ID, { auditId: id });
      }

      // Note: Background processing would be handled by a separate job processor
      // In Next.js 15, we'd use the `after` API or a separate worker
    }

    return NextResponse.json(audit, { headers: { 'Cache-Control': 'no-store' } });
  } catch (error) {
    console.error('Get audit error:', error);
    return NextResponse.json(
      { error: 'Failed to fetch audit' },
      { status: 500 }
    );
  }
}
