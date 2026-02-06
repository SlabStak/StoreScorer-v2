# Seed Data

This directory contains seed data files for development and testing.

## Files

| File | Description |
|------|-------------|
| `00-truncate.sql` | Clears all tables (run first) |
| `01-seed-users.sql` | Test users (admin, pro, free) |
| `02-seed-audits.sql` | Sample audits in various states |
| `03-seed-audit-fixes.sql` | Sample recommendations |
| `04-seed-reviews.sql` | Sample reviews/testimonials |

## Usage

### Reset and seed (recommended)

```bash
./scripts/reset-and-seed.sh
```

### Manual seeding

```bash
# Set your database URL
export DATABASE_URL="postgresql://postgres:postgres@localhost:5432/storescorer_dev"

# Run truncate first
psql -d $DATABASE_URL -f postgresql/seed/00-truncate.sql

# Run seed files in order
psql -d $DATABASE_URL -f postgresql/seed/01-seed-users.sql
psql -d $DATABASE_URL -f postgresql/seed/02-seed-audits.sql
psql -d $DATABASE_URL -f postgresql/seed/03-seed-audit-fixes.sql
psql -d $DATABASE_URL -f postgresql/seed/04-seed-reviews.sql
```

## Test Accounts

| Email | Tier | Credits | Clerk ID |
|-------|------|---------|----------|
| admin@test.storescorer.com | enterprise | 1000 | user_test_admin_001 |
| pro@test.storescorer.com | pro | 100 | user_test_pro_001 |
| free@test.storescorer.com | free | 3 | user_test_free_001 |

## Adding New Seeds

1. Create a new numbered file (e.g., `05-seed-payments.sql`)
2. Follow the naming convention: `NN-seed-description.sql`
3. Update this README
