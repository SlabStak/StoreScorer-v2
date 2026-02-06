# Tasks: StoreScorer v2 Migration (PRD-001)

## Phase 1: Database Schema & Functions
- [x] Task 1.1: Create initial schema migration (0001_initial_schema.sql)
- [x] Task 1.2: Create function_log table and setup-api-user.sql
- [x] Task 1.3: Create PostgreSQL functions for user entity
- [x] Task 1.4: Create PostgreSQL functions for audit entity
- [x] Task 1.5: Create PostgreSQL functions for payment entity
- [x] Task 1.6: Create PostgreSQL functions for audit_page entity
- [x] Task 1.7: Create PostgreSQL functions for audit_fix entity
- [x] Task 1.8: Create PostgreSQL functions for audit_job entity
- [x] Task 1.9: Create PostgreSQL functions for chat_message entity
- [x] Task 1.10: Create PostgreSQL functions for review entity
- [x] Task 1.11: Create PostgreSQL functions for analytics entities

## Phase 2: TypeScript Database Layer
- [x] Task 2.1: Create src/lib/db.ts with pool and callFunction
- [x] Task 2.2: Create src/types/db.ts with all entity types
- [x] Task 2.3: Create src/lib/db/users.ts wrapper
- [x] Task 2.4: Create src/lib/db/audits.ts wrapper
- [x] Task 2.5: Create src/lib/db/payments.ts wrapper
- [x] Task 2.6: Create src/lib/db/audit-pages.ts wrapper
- [x] Task 2.7: Create src/lib/db/audit-fixes.ts wrapper
- [x] Task 2.8: Create src/lib/db/audit-jobs.ts wrapper
- [x] Task 2.9: Create src/lib/db/chat-messages.ts wrapper
- [x] Task 2.10: Create src/lib/db/reviews.ts wrapper
- [x] Task 2.11: Create src/lib/db/analytics.ts wrapper
- [x] Task 2.12: Create src/lib/db/index.ts barrel export

## Phase 3: Infrastructure
- [x] Task 3.1: Create docker-compose.yml
- [x] Task 3.2: Create vercel.json with security headers
- [x] Task 3.3: Create GitHub Actions CI workflow
- [x] Task 3.4: Create Dockerfile for production
- [x] Task 3.5: Create migration scripts
- [x] Task 3.6: Create .env.example

## Phase 4: Seed Data
- [x] Task 4.1: Create 00-truncate.sql
- [x] Task 4.2: Create 01-seed-users.sql
- [x] Task 4.3: Create 02-seed-audits.sql
- [x] Task 4.4: Create 03-seed-audit-fixes.sql
- [x] Task 4.5: Create 04-seed-reviews.sql

## Phase 5: API Route Migration
- [x] Task 5.1: Migrate /api/audit routes
- [x] Task 5.2: Migrate /api/checkout route
- [x] Task 5.3: Migrate /api/reviews route
- [x] Task 5.4: Migrate /api/testimonials route
- [x] Task 5.5: Migrate /api/share/[token] route
- [x] Task 5.6: Migrate /api/webhook/stripe route
- [x] Task 5.7: Create /api/cron/process-jobs route
- [x] Task 5.8: Create /api/cron/cleanup-rate-limits route
- [x] Task 5.9: Migrate /api/admin/audits route
- [x] Task 5.10: Migrate /api/admin/reviews route
- [x] Task 5.11: Migrate /api/admin/revoke route
- [x] Task 5.12: Create /api/health route

## Phase 6: Authentication Migration
- [x] Task 6.1: Install and configure Clerk (package.json)
- [x] Task 6.2: Create auth middleware (src/middleware.ts)
- [x] Task 6.3: Create sign-in/sign-up pages
- [x] Task 6.4: Create auth helper functions (src/lib/auth.ts)
- [x] Task 6.5: Remove magic link code (not migrated)

## Phase 7: Cleanup
- [x] Task 7.1: Remove Prisma (not included in new package.json)
- [x] Task 7.2: Update package.json with Next.js 15.1.6
- [x] Task 7.3: Create supporting lib files (stripe, validation, rate-limiter)
- [x] Task 7.4: Create app layout and basic pages

## Commit History

- Phase 1: "feat(db): create PostgreSQL schema and functions"
- Phase 2: "feat(db): create TypeScript database layer"
- Phase 3: "feat(infra): add Docker, Vercel, and CI configuration"
- Phase 4: "feat(db): add seed data for development"
- Phase 5: "feat(api): migrate all API routes to new db wrappers"
- Phase 6: "feat(auth): add Clerk authentication"
- Phase 7: "chore: update to Next.js 15.1.6 and cleanup"
