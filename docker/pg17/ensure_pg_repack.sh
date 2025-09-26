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

export PGPASSWORD="${PGPASSWORD:-$DB_PASSWORD}"

echo "Waiting for Postgres at ${DB_HOST}:${DB_PORT}..."
until pg_isready -h "$DB_HOST" -p "$DB_PORT" -U "$DB_USER" >/dev/null 2>&1; do
  sleep 1
done

echo "Ensuring pg_repack extension exists in all non-template databases..."
databases=$(psql -h "$DB_HOST" -p "$DB_PORT" -U "$DB_USER" -d postgres -Atc "SELECT datname FROM pg_database WHERE datistemplate=false;")
for db in $databases; do
  echo "Ensuring pg_repack in database: $db"
  psql -h "$DB_HOST" -p "$DB_PORT" -U "$DB_USER" -d "$db" -v ON_ERROR_STOP=1 -c "CREATE EXTENSION IF NOT EXISTS pg_repack;"
done

echo "pg_repack ensure complete."


