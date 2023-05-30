#!/bin/bash

flag=/app/pythonpath/.did.db.init

if grep ok $flag
then
  echo Not initing db
else
  echo Upgrading superset database

  superset db upgrade

  superset fab create-admin \
    --username admin \
    --firstname Superset \
    --lastname Admin \
    --email admin@superset.com \
    --password admin

  superset init

  echo ok > $flag

  # superset load_examples
fi
