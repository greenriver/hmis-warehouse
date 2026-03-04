#!/bin/bash
# Create the Keycloak database if it doesn't already exist.
# This runs once during postgres cluster initialization (new data volume).
# For existing installations without this database, run:
#   docker compose exec db psql -U postgres -c 'CREATE DATABASE keycloak'
set -e
psql -v ON_ERROR_STOP=1 --username "$POSTGRES_USER" --dbname postgres <<-EOSQL
  SELECT 'CREATE DATABASE keycloak' WHERE NOT EXISTS (
    SELECT FROM pg_database WHERE datname = 'keycloak'
  )\gexec
EOSQL
