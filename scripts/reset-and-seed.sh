#!/bin/bash
# scripts/reset-and-seed.sh
# Full database reset and seed

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

echo -e "${YELLOW}Resetting database and running seeds...${NC}"

# Run truncate first
if [ -f "postgresql/seed/00-truncate.sql" ]; then
  echo -e "${GREEN}Running: postgresql/seed/00-truncate.sql${NC}"
  psql -d "$DB_URL" -f "postgresql/seed/00-truncate.sql"
fi

# Run numbered base seeds in order
for seed_file in postgresql/seed/0[1-9]*.sql; do
  if [ -f "$seed_file" ]; then
    echo -e "${GREEN}Running: $seed_file${NC}"
    psql -d "$DB_URL" -f "$seed_file"
  fi
done

# Run any subdirectory seeds
for dir in postgresql/seed/*/; do
  if [ -d "$dir" ]; then
    for seed_file in "$dir"*.sql; do
      if [ -f "$seed_file" ]; then
        echo -e "${GREEN}Running: $seed_file${NC}"
        psql -d "$DB_URL" -f "$seed_file"
      fi
    done
  fi
done

echo -e "${GREEN}Seed complete!${NC}"
