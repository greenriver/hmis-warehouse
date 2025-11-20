#!/bin/bash
###
# Copyright 2016 - 2025 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###
set -euo pipefail

DB_HOST=${DB_HOST:-db}
DB_PORT=${DB_PORT:-5432}
DB_USER=${POSTGRES_USER:-postgres}
DB_PASSWORD=${POSTGRES_PASSWORD:-postgres}
TARGET_VERSION="1.5.2"

export PGPASSWORD="${PGPASSWORD:-$DB_PASSWORD}"

echo "Waiting for Postgres at ${DB_HOST}:${DB_PORT}..."
until pg_isready -h "$DB_HOST" -p "$DB_PORT" -U "$DB_USER" >/dev/null 2>&1; do
  sleep 1
done

echo "Ensuring pg_repack version ${TARGET_VERSION} in all non-template databases..."
databases=$(psql -h "$DB_HOST" -p "$DB_PORT" -U "$DB_USER" -d postgres -Atc "SELECT datname FROM pg_database WHERE datistemplate=false;")

for db in $databases; do
  echo "Ensuring pg_repack in database: $db"

  # Check if pg_repack extension exists
  current_version=$(psql -h "$DB_HOST" -p "$DB_PORT" -U "$DB_USER" -d "$db" -Atc "SELECT extversion FROM pg_extension WHERE extname = 'pg_repack';" 2>/dev/null || echo "")

  if [ -z "$current_version" ]; then
    echo "  Installing pg_repack ${TARGET_VERSION}..."
    psql -h "$DB_HOST" -p "$DB_PORT" -U "$DB_USER" -d "$db" -v ON_ERROR_STOP=1 -c "CREATE EXTENSION pg_repack WITH SCHEMA public VERSION '${TARGET_VERSION}';" >/dev/null
    echo "  ✓ Installed pg_repack ${TARGET_VERSION}"
  elif [ "$current_version" != "$TARGET_VERSION" ]; then
    echo "  Current version: ${current_version}, updating to ${TARGET_VERSION}..."
    # Drop and recreate since there's no migration path from 1.5.2 to 1.5.3
    psql -h "$DB_HOST" -p "$DB_PORT" -U "$DB_USER" -d "$db" -v ON_ERROR_STOP=1 -c "DROP EXTENSION IF EXISTS pg_repack CASCADE;" >/dev/null
    psql -h "$DB_HOST" -p "$DB_PORT" -U "$DB_USER" -d "$db" -v ON_ERROR_STOP=1 -c "CREATE EXTENSION pg_repack WITH SCHEMA public VERSION '${TARGET_VERSION}';" >/dev/null
    echo "  ✓ Updated to pg_repack ${TARGET_VERSION}"
  else
    echo "  ✓ Already at pg_repack ${TARGET_VERSION}"
  fi
done

echo ""
echo "pg_repack ${TARGET_VERSION} ensure complete."