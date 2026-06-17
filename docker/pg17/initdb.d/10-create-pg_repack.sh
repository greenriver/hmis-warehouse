#!/bin/bash

###
# Copyright Green River Data Group, Inc.
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

set -euo pipefail

# Runs only at first-time cluster initialization

databases=$(psql -v ON_ERROR_STOP=1 --username "$POSTGRES_USER" -d postgres -Atc "SELECT datname FROM pg_database WHERE datistemplate = false;")
for db in $databases; do
  psql -v ON_ERROR_STOP=1 --username "$POSTGRES_USER" -d "$db" -c "CREATE EXTENSION IF NOT EXISTS pg_repack WITH SCHEMA public VERSION '1.5.3';"
done
