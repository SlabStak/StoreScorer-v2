import { NextRequest, NextResponse } from 'next/server';
import { getStripe } from '@/lib/stripe';
import { getAudit, updateAudit } from '@/lib/db/audits';
import { createPayment, completePayment, getPaymentByStripeSession } from '@/lib/db/payments';
import { createAuditJob, getJobByAuditId } from '@/lib/db/audit-jobs';

export const runtime = 'nodejs';
export const maxDuration = 60;

const SYSTEM_USER_ID = 'system';

export async function POST(req: NextRequest) {
  if (!process.env.STRIPE_WEBHOOK_SECRET) {
    console.error('STRIPE_WEBHOOK_SECRET is not configured');
    return NextResponse.json({ error: 'Webhook not configured' }, { status: 503 });
  }

  const body = await req.text();
  const signature = req.headers.get('stripe-signature');

  if (!signature) {
    return NextResponse.json({ error: 'No signature' }, { status: 400 });
  }

  let event;

  try {
    const stripe = getStripe();
    event = stripe.webhooks.constructEvent(
      body,
      signature,
      process.env.STRIPE_WEBHOOK_SECRET
    );
  } catch (err) {
    console.error('Webhook signature verification failed:', err);
    return NextResponse.json({ error: 'Invalid signature' }, { status: 400 });
  }

  if (event.type === 'checkout.session.completed') {
    const session = event.data.object;

    const auditId = session.metadata?.auditId || session.client_reference_id;

    if (!auditId) {
      console.error('No auditId in webhook');
      return NextResponse.json({ error: 'Missing auditId' }, { status: 400 });
    }

    // Extract email from Stripe
    const customerEmail = session.customer_details?.email || session.customer_email;

    // Check if payment already exists
    const existingPayment = await getPaymentByStripeSession(SYSTEM_USER_ID, session.id);

    if (existingPayment.success && existingPayment.data) {
      // Update existing payment
      const paymentIntentId = session.payment_intent;
      await completePayment(
        SYSTEM_USER_ID,
        existingPayment.data.id,
        typeof paymentIntentId === 'string' ? paymentIntentId : undefined
      );
    } else {
      // Create new payment record
      const paymentIntentId = session.payment_intent;
      await createPayment(SYSTEM_USER_ID, {
        auditId,
        stripeSessionId: session.id,
        stripePaymentId: typeof paymentIntentId === 'string' ? paymentIntentId : undefined,
        amount: session.amount_total ?? 2999,
        currency: session.currency ?? 'usd',
        status: 'COMPLETED',
      });
    }

    // Update audit status and email
    const auditResult = await getAudit(SYSTEM_USER_ID, auditId);
    if (auditResult.success && auditResult.data) {
      await updateAudit(SYSTEM_USER_ID, auditId, {
        status: 'PAYMENT_COMPLETE',
        ...(customerEmail ? { email: customerEmail } : {}),
      });
    }

    console.log(`Payment completed for audit ${auditId}, creating job`);

    // Create job for async processing if not exists
    const existingJob = await getJobByAuditId(SYSTEM_USER_ID, auditId);
    if (!existingJob.success || !existingJob.data) {
      await createAuditJob(SYSTEM_USER_ID, { auditId });
    }

    console.log(`Job created for audit ${auditId}`);

    // Note: In production, you'd trigger background processing here
    // using Next.js `after()` API or a queue system
  }

  return NextResponse.json({ received: true });
}
