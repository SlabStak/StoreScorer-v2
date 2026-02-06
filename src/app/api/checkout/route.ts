import { NextRequest, NextResponse } from 'next/server';
import { createAudit, deleteAudit } from '@/lib/db/audits';
import { createPayment } from '@/lib/db/payments';
import { createCheckoutSession } from '@/lib/stripe';
import { CheckoutRequestSchema, validateAndNormalizeDomain, DomainValidationError, isValidEmail } from '@/lib/validation';
import { checkIPRateLimit, checkDomainRateLimit, RateLimitExceededError } from '@/lib/rate-limiter';

const SYSTEM_USER_ID = 'system';

export async function POST(req: NextRequest) {
  let auditId: string | null = null;

  try {
    // Validate required environment variables
    if (!process.env.STRIPE_SECRET_KEY) {
      console.error('STRIPE_SECRET_KEY is not configured');
      return NextResponse.json(
        { error: 'Payment system not configured. Please contact support.' },
        { status: 503 }
      );
    }

    if (!process.env.STRIPE_AUDIT_PRICE_ID) {
      console.error('STRIPE_AUDIT_PRICE_ID is not configured');
      return NextResponse.json(
        { error: 'Payment pricing not configured. Please contact support.' },
        { status: 503 }
      );
    }

    const body = await req.json();

    // Validate request body
    const parseResult = CheckoutRequestSchema.safeParse(body);
    if (!parseResult.success) {
      return NextResponse.json(
        { error: parseResult.error.errors[0]?.message || 'Invalid request' },
        { status: 400 }
      );
    }

    const { domain, email, marketingConsent, utmSource, utmMedium, utmCampaign } = parseResult.data;

    const normalizedEmail = email.trim().toLowerCase();
    if (!isValidEmail(normalizedEmail)) {
      return NextResponse.json(
        { error: 'Please enter a valid email address' },
        { status: 400 }
      );
    }

    // Get request metadata
    const ip = req.headers.get('x-forwarded-for') || req.headers.get('x-real-ip') || 'unknown';
    const userAgent = req.headers.get('user-agent') || undefined;

    // Rate limiting
    try {
      await checkIPRateLimit(ip);
    } catch (error) {
      if (error instanceof RateLimitExceededError) {
        return NextResponse.json({ error: error.message }, { status: 429 });
      }
      throw error;
    }

    // Domain validation
    let normalizedDomain: string;
    try {
      normalizedDomain = validateAndNormalizeDomain(domain);
    } catch (error) {
      if (error instanceof DomainValidationError) {
        return NextResponse.json({ error: error.message }, { status: 400 });
      }
      throw error;
    }

    // Domain rate limiting
    try {
      await checkDomainRateLimit(normalizedDomain);
    } catch (error) {
      if (error instanceof RateLimitExceededError) {
        return NextResponse.json(
          { error: `This domain has reached its audit limit. ${error.message}` },
          { status: 429 }
        );
      }
      throw error;
    }

    // Create audit record
    const auditResult = await createAudit(SYSTEM_USER_ID, {
      domain: normalizedDomain,
      email: normalizedEmail,
      status: 'PAYMENT_PENDING',
      marketingConsent: marketingConsent || false,
      createdIp: ip,
      userAgent,
      utmSource,
      utmMedium,
      utmCampaign,
    });

    if (!auditResult.success || !auditResult.data) {
      console.error('Database error creating audit:', auditResult.error);
      return NextResponse.json(
        { error: 'Unable to initialize audit. Please try again.' },
        { status: 503 }
      );
    }

    auditId = auditResult.data.id;

    const appUrl = process.env.NEXT_PUBLIC_APP_URL || 'http://localhost:3000';

    // Create Stripe checkout session
    let session;
    try {
      session = await createCheckoutSession({
        domain: normalizedDomain,
        auditId,
        successUrl: `${appUrl}/audit/${auditId}`,
        cancelUrl: `${appUrl}?canceled=true`,
        customerEmail: normalizedEmail,
      });
    } catch (stripeError: unknown) {
      console.error('Stripe error creating checkout session:', stripeError);

      // Clean up the audit record since Stripe failed
      await deleteAudit(SYSTEM_USER_ID, auditId);

      const errorMessage = stripeError instanceof Error ? stripeError.message : 'Unknown error';
      if (errorMessage.includes('No such price')) {
        return NextResponse.json(
          { error: 'Product pricing configuration error. Please contact support.' },
          { status: 503 }
        );
      }
      if (errorMessage.includes('Invalid API Key')) {
        return NextResponse.json(
          { error: 'Payment authentication error. Please contact support.' },
          { status: 503 }
        );
      }
      return NextResponse.json(
        { error: 'Unable to create payment session. Please try again.' },
        { status: 503 }
      );
    }

    // Create payment record
    const paymentResult = await createPayment(SYSTEM_USER_ID, {
      auditId,
      stripeSessionId: session.id,
      amount: 2999, // $29.99
      currency: 'usd',
      status: 'PENDING',
    });

    if (!paymentResult.success) {
      console.error('Database error creating payment record:', paymentResult.error);
      // Don't fail - the webhook will handle creating the payment record if needed
    }

    return NextResponse.json({
      auditId,
      url: session.url,
    });
  } catch (error) {
    console.error('Unexpected checkout error:', error);

    // Clean up audit if it was created
    if (auditId) {
      await deleteAudit(SYSTEM_USER_ID, auditId);
    }

    return NextResponse.json(
      { error: 'An unexpected error occurred. Please try again or contact support.' },
      { status: 500 }
    );
  }
}
