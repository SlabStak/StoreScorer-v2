# PRD-001: StoreScorer v2 Migration

## Problem Statement

StoreScorer v1 uses Prisma ORM which introduces complexity, potential N+1 queries, and makes audit logging difficult. We need to migrate to direct PostgreSQL functions following the Licenzr build standard.

## User Stories

- As a developer, I want predictable database performance so that audit operations complete consistently
- As a developer, I want comprehensive audit logging so that I can debug issues and track operations
- As a user, I want faster page loads so that I can review my audit results quickly
- As an admin, I want to see all database operations logged so that I can monitor system health

## Acceptance Criteria

- [ ] All database operations go through PostgreSQL functions
- [ ] No Prisma or ORM code in the codebase
- [ ] Every function call logged to function_log table
- [ ] TypeScript wrappers provide type-safe access
- [ ] API routes use new db wrapper layer
- [ ] Auth migrated from magic links to Clerk
- [ ] All existing functionality preserved
- [ ] Performance equal or better than v1

## Technical Approach

1. Create PostgreSQL functions for all 11 entities
2. Create TypeScript DB wrapper layer with callFunction
3. Create domain-specific wrapper files
4. Migrate API routes one by one
5. Replace magic link auth with Clerk
6. Remove Prisma and update dependencies

## Out of Scope

- New features (handle in separate PRDs)
- UI/UX changes
- Mobile app development
