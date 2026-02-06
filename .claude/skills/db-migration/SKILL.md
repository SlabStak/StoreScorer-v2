# Database Migration Skill

## Mission

Create and run PostgreSQL migrations for StoreScorer following the build standard.

## When to Use

- Adding new tables or columns
- Modifying existing schema
- Creating new PostgreSQL functions
- Updating indexes or constraints

## Workflow

### Phase 1: Create Migration

1. Determine next migration number (check sql/migrations/)
2. Create migration file: `sql/migrations/NNNN_description.sql`
3. Write idempotent SQL (use IF NOT EXISTS, CREATE OR REPLACE)
4. Include rollback comments if complex

### Phase 2: Create/Update Functions

1. Create or update function file in `postgresql/functions/`
2. Follow template from build-standard
3. Include SECURITY DEFINER and function_log

### Phase 3: Update TypeScript

1. Update `src/types/db.ts` if new types needed
2. Update relevant wrapper in `src/lib/db/`
3. Update barrel export if new module

### Phase 4: Test

1. Run migration: `./scripts/run-migration.sh --dry sql/migrations/NNNN_description.sql`
2. Apply migration: `./scripts/run-migration.sh sql/migrations/NNNN_description.sql`
3. Test via TypeScript wrapper

## Output Format

```
Migration created: sql/migrations/NNNN_description.sql
Function updated: postgresql/functions/entity.sql
Wrapper updated: src/lib/db/entity.ts
```

## Examples

### Adding a new column

```sql
-- sql/migrations/0002_add_user_avatar.sql
ALTER TABLE users ADD COLUMN IF NOT EXISTS avatar_url TEXT;
```
