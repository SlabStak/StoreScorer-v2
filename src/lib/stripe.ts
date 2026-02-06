import 'server-only';

import Stripe from 'stripe';

let stripeInstance: Stripe | null = null;

export function getStripe(): Stripe {
  if (!stripeInstance) {
    const secretKey = process.env.STRIPE_SECRET_KEY;
    if (!secretKey) {
      throw new Error('STRIPE_SECRET_KEY is not configured');
    }
    stripeInstance = new Stripe(secretKey, {
      apiVersion: '2025-02-24.acacia',
    });
  }
  return stripeInstance;
}

export interface CheckoutSessionParams {
  domain: string;
  auditId: string;
  successUrl: string;
  cancelUrl: string;
  customerEmail: string;
}

export async function createCheckoutSession(params: CheckoutSessionParams) {
  const stripe = getStripe();
  const priceId = process.env.STRIPE_AUDIT_PRICE_ID;

  if (!priceId) {
    throw new Error('STRIPE_AUDIT_PRICE_ID is not configured');
  }

  const session = await stripe.checkout.sessions.create({
    mode: 'payment',
    line_items: [
      {
        price: priceId,
        quantity: 1,
      },
    ],
    success_url: params.successUrl,
    cancel_url: params.cancelUrl,
    metadata: {
      auditId: params.auditId,
      domain: params.domain,
    },
    client_reference_id: params.auditId,
    customer_email: params.customerEmail,
  });

  return session;
}
