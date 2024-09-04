#!/bin/env bash

set -ex
set -oi pipefail

# If you need to start over for some reason, destroy the db container and run:
# docker volume rm hmis-warehouse_dbdata_pg16

docker-compose stop db_previous db

docker-compose up -d db_previous db

sleep 3

docker-compose logs db_previous db

export FILENAME=db_previous.dumpall.sql

# docker-compose exec db_previous pg_dumpall --help

mkdir -p tmp/dumps

echo Dumping old database
docker-compose exec db_previous pg_dumpall --exclude-database=template\* --exclude-database=postgres > tmp/dumps/$FILENAME

echo Importing to new database
docker-compose exec \
  db psql -c "\i /tmp/dumps/$FILENAME"

docker-compose exec \
  db psql -c "ALTER USER postgres WITH PASSWORD 'postgres'"

docker-compose stop db_previous
