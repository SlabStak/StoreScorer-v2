/**
 * StoreScorer Database Types
 * Build Standard Compliant
 */

// =============================================================================
// RESULT WRAPPERS
// =============================================================================

/**
 * Standard result wrapper for all database operations
 */
export interface DbResult<T> {
  success: boolean;
  data?: T;
  error?: string;
}

/**
 * Pagination result wrapper
 */
export interface PaginatedResult<T> {
  items: T[];
  total: number;
  limit: number;
  offset: number;
}

// =============================================================================
// ENUMS
// =============================================================================

export type SubscriptionStatus = 'NONE' | 'ACTIVE' | 'CANCELED' | 'PAST_DUE';

export type AuditStatus =
  | 'PENDING'
  | 'PAYMENT_PENDING'
  | 'PAYMENT_COMPLETE'
  | 'CRAWLING'
  | 'ANALYZING'
  | 'COMPLETED'
  | 'FAILED';

export type PaymentStatus = 'PENDING' | 'PROCESSING' | 'COMPLETED' | 'FAILED' | 'REFUNDED';

export type PageType =
  | 'HOMEPAGE'
  | 'PRODUCT'
  | 'COLLECTION'
  | 'POLICY'
  | 'CART'
  | 'CHECKOUT'
  | 'FAQ'
  | 'BLOG'
  | 'ABOUT'
  | 'CONTACT'
  | 'OTHER';

export type ImpactLevel = 'HIGH' | 'MEDIUM' | 'LOW';

export type JobStatus = 'PENDING' | 'PROCESSING' | 'COMPLETED' | 'FAILED';

export type ChatRole = 'USER' | 'ASSISTANT';

export type ReviewStatus = 'PENDING' | 'APPROVED' | 'REJECTED';

export type ConversionEventType =
  | 'LANDING_VIEW'
  | 'CHECKOUT_INITIATED'
  | 'PAYMENT_COMPLETE'
  | 'AUDIT_DELIVERED';

// =============================================================================
// USER (ID prefix: usr_)
// =============================================================================

export interface User {
  id: string;
  clerkId: string;
  email: string;
  firstName: string | null;
  lastName: string | null;
  emailNotifications: boolean;
  isAdmin: boolean;
  stripeCustomerId: string | null;
  stripeSubscriptionId: string | null;
  subscriptionStatus: SubscriptionStatus;
  subscriptionExpiresAt: Date | null;
  createdAt: Date;
  updatedAt: Date;
}

export interface UserCreateInput {
  clerkId: string;
  email: string;
  firstName?: string;
  lastName?: string;
}

export interface UserUpdateInput {
  firstName?: string;
  lastName?: string;
  emailNotifications?: boolean;
  stripeCustomerId?: string;
  stripeSubscriptionId?: string;
  subscriptionStatus?: SubscriptionStatus;
  subscriptionExpiresAt?: Date;
}

export type UserListResult = PaginatedResult<User>;

// =============================================================================
// AUDIT (ID prefix: aud_)
// =============================================================================

export interface Audit {
  id: string;
  domain: string;
  status: AuditStatus;
  userId: string | null;
  shareToken: string;
  shareActive: boolean;
  shareViewCount: number;
  mekellScore: number | null;
  overallScore: number | null;
  synthesis: Record<string, unknown> | null;
  errorMessage: string | null;
  warningMessage: string | null;
  tokenUsage: number;
  email: string | null;
  marketingConsent: boolean;
  createdIp: string | null;
  userAgent: string | null;
  utmSource: string | null;
  utmMedium: string | null;
  utmCampaign: string | null;
  paymentEmailSentAt: Date | null;
  reportEmailSentAt: Date | null;
  createdAt: Date;
  updatedAt: Date;
  completedAt: Date | null;
  fixes?: AuditFix[];
}

export interface AuditWithRelations extends Audit {
  fixes: AuditFix[];
  pages: AuditPage[];
  payment: Payment | null;
}

export interface AuditCreateInput {
  domain: string;
  email?: string;
  status?: AuditStatus;
  marketingConsent?: boolean;
  createdIp?: string;
  userAgent?: string;
  utmSource?: string;
  utmMedium?: string;
  utmCampaign?: string;
}

export interface AuditUpdateInput {
  status?: AuditStatus;
  userId?: string;
  shareActive?: boolean;
  mekellScore?: number;
  synthesis?: Record<string, unknown>;
  errorMessage?: string;
  warningMessage?: string;
  tokenUsage?: number;
  paymentEmailSentAt?: Date;
  reportEmailSentAt?: Date;
  completedAt?: Date;
}

export type AuditListResult = PaginatedResult<Audit>;

// =============================================================================
// PAYMENT (ID prefix: pay_)
// =============================================================================

export interface Payment {
  id: string;
  auditId: string;
  stripeSessionId: string;
  stripePaymentId: string | null;
  amount: number;
  currency: string;
  status: PaymentStatus;
  createdAt: Date;
  paidAt: Date | null;
}

export interface PaymentCreateInput {
  auditId: string;
  stripeSessionId: string;
  stripePaymentId?: string;
  amount: number;
  currency?: string;
  status?: PaymentStatus;
}

export interface PaymentUpdateInput {
  stripePaymentId?: string;
  status?: PaymentStatus;
  paidAt?: Date;
}

// =============================================================================
// AUDIT PAGE (ID prefix: apg_)
// =============================================================================

export interface AuditPage {
  id: string;
  auditId: string;
  url: string;
  pageType: PageType;
  title: string | null;
  html: string;
  cleanText: string;
  analysis: Record<string, unknown> | null;
  crawledAt: Date;
}

export interface AuditPageSummary {
  id: string;
  auditId: string;
  url: string;
  pageType: PageType;
  title: string | null;
  analysis: Record<string, unknown> | null;
  crawledAt: Date;
}

export interface AuditPageCreateInput {
  auditId: string;
  url: string;
  pageType: PageType;
  title?: string;
  html: string;
  cleanText: string;
  analysis?: Record<string, unknown>;
}

// =============================================================================
// AUDIT FIX (ID prefix: afx_)
// =============================================================================

export interface AuditFix {
  id: string;
  auditId: string;
  rank: number;
  title: string;
  category: string;
  impact: ImpactLevel;
  description: string;
  evidence: string;
  recommendation: string;
  confidence: number;
  createdAt: Date;
}

export interface AuditFixCreateInput {
  auditId: string;
  rank: number;
  title: string;
  category: string;
  impact: ImpactLevel;
  description: string;
  evidence: string;
  recommendation: string;
  confidence: number;
}

// =============================================================================
// AUDIT JOB (ID prefix: ajob_)
// =============================================================================

export interface AuditJob {
  id: string;
  auditId: string;
  status: JobStatus;
  attempts: number;
  lastError: string | null;
  lockedAt: Date | null;
  createdAt: Date;
  updatedAt: Date;
}

export interface AuditJobCreateInput {
  auditId: string;
}

// =============================================================================
// CHAT MESSAGE (ID prefix: cmsg_)
// =============================================================================

export interface ChatMessage {
  id: string;
  auditId: string;
  userId: string;
  role: ChatRole;
  content: string;
  createdAt: Date;
}

export interface ChatMessageCreateInput {
  auditId: string;
  role: ChatRole;
  content: string;
}

// =============================================================================
// REVIEW (ID prefix: rev_)
// =============================================================================

export interface Review {
  id: string;
  auditId: string;
  domain: string;
  email: string | null;
  rating: number | null;
  helpful: boolean;
  comment: string | null;
  name: string | null;
  storeName: string | null;
  canPublish: boolean;
  status: ReviewStatus;
  createdAt: Date;
  updatedAt: Date;
}

export interface ReviewCreateInput {
  auditId: string;
  domain: string;
  helpful: boolean;
  email?: string;
  rating?: number;
  comment?: string;
  name?: string;
  storeName?: string;
  canPublish?: boolean;
}

export interface Testimonial {
  id: string;
  domain: string;
  rating: number | null;
  comment: string;
  name: string | null;
  storeName: string | null;
  createdAt: Date;
}

export type ReviewListResult = PaginatedResult<Review>;

// =============================================================================
// PAGE VIEW (ID prefix: pv_)
// =============================================================================

export interface PageView {
  id: string;
  path: string;
  referrer: string | null;
  utmSource: string | null;
  utmMedium: string | null;
  utmCampaign: string | null;
  userAgent: string | null;
  ipHash: string | null;
  sessionId: string | null;
  userId: string | null;
  createdAt: Date;
}

export interface PageViewCreateInput {
  path: string;
  referrer?: string;
  utmSource?: string;
  utmMedium?: string;
  utmCampaign?: string;
  userAgent?: string;
  ipHash?: string;
  sessionId?: string;
}

// =============================================================================
// CONVERSION EVENT (ID prefix: cev_)
// =============================================================================

export interface ConversionEvent {
  id: string;
  eventType: ConversionEventType;
  sessionId: string | null;
  userId: string | null;
  auditId: string | null;
  metadata: Record<string, unknown> | null;
  createdAt: Date;
}

export interface ConversionEventCreateInput {
  eventType: ConversionEventType;
  sessionId?: string;
  auditId?: string;
  metadata?: Record<string, unknown>;
}

// =============================================================================
// RATE LIMIT (ID prefix: rle_)
// =============================================================================

export interface RateLimitEvent {
  id: string;
  key: string;
  type: string;
  createdAt: Date;
}

export interface RateLimitCheck {
  key: string;
  type: string;
  count: number;
  limit: number;
  remaining: number;
  isLimited: boolean;
  windowMinutes: number;
}

// =============================================================================
// ANALYTICS
// =============================================================================

export interface AnalyticsPeriod {
  period: Date;
  views?: number;
  uniqueSessions?: number;
  count?: number;
  totalAmount?: number;
}

export interface ConversionFunnelStage {
  stage: ConversionEventType;
  count: number;
}

export interface TopPage {
  path: string;
  views: number;
  uniqueSessions: number;
}
