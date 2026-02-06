# Local Database Skill

## Mission

Manage local PostgreSQL database for StoreScorer development.

## When to Use

- Starting development environment
- Resetting database state
- Running seeds
- Checking database status

## Commands

### Start Database

```bash
docker compose up -d postgres redis
```

### Stop Database

```bash
docker compose down
```

### Reset Database

```bash
./scripts/reset-and-seed.sh
```

### Setup Fresh Database

```bash
./scripts/setup-db.sh
```

### Connect to Database

```bash
docker compose exec postgres psql -U postgres -d storescorer_dev
```

### View Logs

```bash
docker compose logs -f postgres
```

### Check Function Logs

```sql
SELECT * FROM function_log ORDER BY created_at DESC LIMIT 20;
```

## Environment

Set in `.env.local`:

```
DATABASE_URL="postgresql://postgres:postgres@localhost:5432/storescorer_dev"
REDIS_URL="redis://localhost:6379"
```

## Troubleshooting

### Port 5432 in use

```bash
# Find process
lsof -i :5432

# Or use different port in docker-compose.yml
ports:
  - '5433:5432'
```

### Reset Docker volumes

```bash
docker compose down -v
docker compose up -d
./scripts/setup-db.sh
```
