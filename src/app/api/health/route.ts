import { NextResponse } from 'next/server';
import { pool } from '@/lib/db';

export const runtime = 'nodejs';
export const dynamic = 'force-dynamic';

export async function GET() {
  const checks: Record<string, { status: 'ok' | 'error'; message?: string }> = {};

  // 1. Environment variables
  try {
    const requiredEnvVars = [
      'DATABASE_URL',
      'CLERK_SECRET_KEY',
      'STRIPE_SECRET_KEY',
    ];
    const missing = requiredEnvVars.filter((key) => !process.env[key]);
    if (missing.length > 0) {
      checks.env = { status: 'error', message: `Missing: ${missing.join(', ')}` };
    } else {
      checks.env = { status: 'ok' };
    }
  } catch (error: unknown) {
    checks.env = { status: 'error', message: error instanceof Error ? error.message : 'Unknown error' };
  }

  // 2. Database connectivity
  try {
    const client = await pool.connect();
    await client.query('SELECT 1');
    client.release();
    checks.database = { status: 'ok' };
  } catch (error: unknown) {
    checks.database = { status: 'error', message: 'Cannot connect to database' };
  }

  // 3. OpenAI API key
  try {
    const hasKey = !!process.env.OPENAI_API_KEY;
    checks.llm = hasKey
      ? { status: 'ok' }
      : { status: 'error', message: 'OPENAI_API_KEY missing' };
  } catch {
    checks.llm = { status: 'error', message: 'LLM configuration invalid' };
  }

  // 4. Stripe
  try {
    const hasStripe = !!process.env.STRIPE_SECRET_KEY && !!process.env.STRIPE_AUDIT_PRICE_ID;
    checks.stripe = hasStripe
      ? { status: 'ok' }
      : { status: 'error', message: 'Stripe not fully configured' };
  } catch {
    checks.stripe = { status: 'error', message: 'Stripe configuration invalid' };
  }

  const allOk = Object.values(checks).every((c) => c.status === 'ok');

  return NextResponse.json(
    {
      status: allOk ? 'healthy' : 'degraded',
      checks,
      timestamp: new Date().toISOString(),
    },
    { status: allOk ? 200 : 503 }
  );
}
