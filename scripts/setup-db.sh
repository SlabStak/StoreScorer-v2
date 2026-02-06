#!/bin/bash
# scripts/setup-db.sh
# Initialize database with schema and functions

set -e

# Color output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Determine database connection
if [ -n "$LOCAL_DATABASE_URL" ]; then
  DB_URL="$LOCAL_DATABASE_URL"
elif [ -n "$DATABASE_URL" ]; then
  DB_URL="$DATABASE_URL"
else
  echo -e "${RED}Error: No database URL found${NC}"
  exit 1
fi

echo -e "${YELLOW}Setting up database...${NC}"

# Run migrations in order
echo -e "${GREEN}Running migrations...${NC}"
for migration_file in sql/migrations/*.sql; do
  if [ -f "$migration_file" ]; then
    echo -e "${GREEN}Running: $migration_file${NC}"
    psql -d "$DB_URL" -v ON_ERROR_STOP=1 -f "$migration_file"
  fi
done

# Set up API user
echo -e "${GREEN}Setting up API user...${NC}"
psql -d "$DB_URL" -v ON_ERROR_STOP=1 -f "postgresql/setup-api-user.sql"

# Run all function definitions
echo -e "${GREEN}Creating functions...${NC}"
for function_file in postgresql/functions/*.sql; do
  if [ -f "$function_file" ]; then
    echo -e "${GREEN}Running: $function_file${NC}"
    psql -d "$DB_URL" -v ON_ERROR_STOP=1 -f "$function_file"
  fi
done

echo -e "${GREEN}Database setup complete!${NC}"
