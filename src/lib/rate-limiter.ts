import 'server-only';

import { checkRateLimit, createRateLimitEvent } from './db/analytics';

export class RateLimitExceededError extends Error {
  constructor(message: string) {
    super(message);
    this.name = 'RateLimitExceededError';
  }
}

const SYSTEM_USER_ID = 'system';

// Rate limits configuration
const RATE_LIMITS = {
  ip: {
    maxRequests: parseInt(process.env.RATE_LIMIT_IP_PER_HOUR || '20', 10),
    windowMinutes: 60,
  },
  domain: {
    maxRequests: parseInt(process.env.RATE_LIMIT_DOMAIN_PER_DAY || '3', 10),
    windowMinutes: 1440, // 24 hours
  },
};

export async function checkIPRateLimit(ip: string): Promise<void> {
  // Hash IP for privacy
  const ipHash = await hashString(ip);

  const result = await checkRateLimit(
    SYSTEM_USER_ID,
    ipHash,
    'ip',
    RATE_LIMITS.ip.maxRequests,
    RATE_LIMITS.ip.windowMinutes
  );

  if (!result.success) {
    throw new Error('Rate limit check failed');
  }

  if (result.data?.isLimited) {
    await createRateLimitEvent(SYSTEM_USER_ID, ipHash, 'ip');
    throw new RateLimitExceededError(
      `Too many requests. Please try again in ${RATE_LIMITS.ip.windowMinutes} minutes.`
    );
  }
}

export async function checkDomainRateLimit(domain: string): Promise<void> {
  const result = await checkRateLimit(
    SYSTEM_USER_ID,
    domain.toLowerCase(),
    'domain',
    RATE_LIMITS.domain.maxRequests,
    RATE_LIMITS.domain.windowMinutes
  );

  if (!result.success) {
    throw new Error('Rate limit check failed');
  }

  if (result.data?.isLimited) {
    await createRateLimitEvent(SYSTEM_USER_ID, domain.toLowerCase(), 'domain');
    throw new RateLimitExceededError(
      `This domain has been audited recently. Try again in 24 hours.`
    );
  }
}

async function hashString(input: string): Promise<string> {
  const encoder = new TextEncoder();
  const data = encoder.encode(input);
  const hashBuffer = await crypto.subtle.digest('SHA-256', data);
  const hashArray = Array.from(new Uint8Array(hashBuffer));
  return hashArray.map((b) => b.toString(16).padStart(2, '0')).join('');
}
