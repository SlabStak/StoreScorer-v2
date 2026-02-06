import { z } from 'zod';

// Domain validation
export const DomainSchema = z
  .string()
  .min(1, 'Domain is required')
  .max(255, 'Domain is too long')
  .transform((val) => {
    // Remove protocol if present
    let domain = val.replace(/^https?:\/\//, '');
    // Remove trailing slash and path
    domain = domain.split('/')[0];
    // Remove www prefix
    domain = domain.replace(/^www\./, '');
    // Lowercase
    return domain.toLowerCase().trim();
  })
  .refine(
    (val) => {
      // Basic domain pattern check
      const domainPattern = /^[a-z0-9]([a-z0-9-]*[a-z0-9])?(\.[a-z0-9]([a-z0-9-]*[a-z0-9])?)+$/;
      return domainPattern.test(val);
    },
    { message: 'Please enter a valid domain' }
  );

export class DomainValidationError extends Error {
  constructor(message: string) {
    super(message);
    this.name = 'DomainValidationError';
  }
}

export function validateAndNormalizeDomain(domain: string): string {
  const result = DomainSchema.safeParse(domain);
  if (!result.success) {
    throw new DomainValidationError(result.error.errors[0]?.message || 'Invalid domain');
  }
  return result.data;
}

// Email validation
export function isValidEmail(email: string): boolean {
  return /^[^\s@]+@[^\s@]+\.[^\s@]+$/.test(email);
}

// Checkout request schema
export const CheckoutRequestSchema = z.object({
  domain: z.string().min(1, 'Domain is required'),
  email: z.string().email('Invalid email address'),
  marketingConsent: z.boolean().optional().default(false),
  utmSource: z.string().optional(),
  utmMedium: z.string().optional(),
  utmCampaign: z.string().optional(),
});

// Review request schema
export const ReviewRequestSchema = z.object({
  auditId: z.string().min(1, 'Audit ID is required'),
  helpful: z.boolean(),
  rating: z.number().min(1).max(5).optional(),
  comment: z.string().max(2000).optional(),
  name: z.string().max(100).optional(),
  storeName: z.string().max(100).optional(),
  canPublish: z.boolean().optional().default(false),
});
