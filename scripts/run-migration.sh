#!/bin/bash
# scripts/run-migration.sh
# Migration runner with --dry support

set -e

# Color output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Parse arguments
DRY_RUN=false
MIGRATION_FILE=""

while [[ $# -gt 0 ]]; do
  case $1 in
    --dry)
      DRY_RUN=true
      shift
      ;;
    *)
      MIGRATION_FILE="$1"
      shift
      ;;
  esac
done

if [ -z "$MIGRATION_FILE" ]; then
  echo -e "${RED}Error: Migration file required${NC}"
  echo "Usage: ./run-migration.sh [--dry] <migration-file.sql>"
  exit 1
fi

if [ ! -f "$MIGRATION_FILE" ]; then
  echo -e "${RED}Error: Migration file not found: $MIGRATION_FILE${NC}"
  exit 1
fi

# Determine database connection
if [ -n "$LOCAL_DATABASE_URL" ]; then
  echo -e "${YELLOW}Using LOCAL_DATABASE_URL${NC}"
  export PGPASSWORD=$(echo $LOCAL_DATABASE_URL | sed -n 's/.*:\/\/[^:]*:\([^@]*\)@.*/\1/p')
  DB_HOST=$(echo $LOCAL_DATABASE_URL | sed -n 's/.*@\([^:\/]*\).*/\1/p')
  DB_PORT=$(echo $LOCAL_DATABASE_URL | sed -n 's/.*:\([0-9]*\)\/.*/\1/p')
  DB_NAME=$(echo $LOCAL_DATABASE_URL | sed -n 's/.*\/\([^?]*\).*/\1/p')
  DB_USER=$(echo $LOCAL_DATABASE_URL | sed -n 's/.*:\/\/\([^:]*\):.*/\1/p')
elif [ -n "$DATABASE_URL" ]; then
  echo -e "${YELLOW}Using DATABASE_URL${NC}"
  export PGPASSWORD=$(echo $DATABASE_URL | sed -n 's/.*:\/\/[^:]*:\([^@]*\)@.*/\1/p')
  DB_HOST=$(echo $DATABASE_URL | sed -n 's/.*@\([^:\/]*\).*/\1/p')
  DB_PORT=$(echo $DATABASE_URL | sed -n 's/.*:\([0-9]*\)\/.*/\1/p')
  DB_NAME=$(echo $DATABASE_URL | sed -n 's/.*\/\([^?]*\).*/\1/p')
  DB_USER=$(echo $DATABASE_URL | sed -n 's/.*:\/\/\([^:]*\):.*/\1/p')
elif [ -n "$RDS_HOSTNAME" ]; then
  echo -e "${YELLOW}Using RDS credentials${NC}"
  export PGPASSWORD="$RDS_PASSWORD"
  DB_HOST="$RDS_HOSTNAME"
  DB_PORT="${RDS_PORT:-5432}"
  DB_NAME="$RDS_DB_NAME"
  DB_USER="$RDS_USERNAME"
else
  echo -e "${RED}Error: No database credentials found${NC}"
  echo "Set DATABASE_URL, LOCAL_DATABASE_URL, or RDS_* environment variables"
  exit 1
fi

# Set default port if not found
DB_PORT="${DB_PORT:-5432}"

echo -e "${YELLOW}Database: $DB_HOST:$DB_PORT/$DB_NAME${NC}"

# Run migration
if [ "$DRY_RUN" = true ]; then
  echo -e "${YELLOW}DRY RUN - showing migration without executing${NC}"
  echo "=============================================="
  cat "$MIGRATION_FILE"
  echo "=============================================="
else
  LOG_FILE="migration-$(date +%Y%m%d-%H%M%S).log"
  echo -e "${GREEN}Running migration: $MIGRATION_FILE${NC}"

  psql -h "$DB_HOST" -p "$DB_PORT" -U "$DB_USER" -d "$DB_NAME" \
    -v ON_ERROR_STOP=1 \
    -f "$MIGRATION_FILE" \
    2>&1 | tee "$LOG_FILE"

  echo -e "${GREEN}Migration completed successfully${NC}"
  echo -e "Log saved to: $LOG_FILE"
fi
