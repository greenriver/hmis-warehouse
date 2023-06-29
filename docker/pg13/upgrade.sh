#!/bin/env bash

set -oi pipefail

# If you need to start over for some reason:
# docker volume rm dbdata_pg13

if [[ "$ARMOK" != 'true' ]]
then
  echo If you are not on ARM just rerun with ARMOK=true
  echo Remove or comment out any existing database image overrides
  echo you might need to add this to your docker-compose.override.yml file first. Set ARMOK=true and rerun
  cat << EOF
  services:
    db_previous:
      image: gangstead/postgis:13-3.1-arm
EOF

  exit
fi

docker compose stop db_previous db

docker compose up -d db_previous db

sleep 3

docker compose logs db_previous db

export FILENAME=db_previous.dumpall.sql

# docker compose exec db_previous pg_dumpall --help

mkdir -p tmp/dumps

echo Dumping old database
docker compose exec \
  db_previous pg_dumpall \
  --exclude-database=template\* \
  --exclude-database=postgres \
  > tmp/dumps/$FILENAME

echo Importing to new database
docker compose exec \
  db psql -c "\i /tmp/dumps/$FILENAME"

docker compose stop db_previous
