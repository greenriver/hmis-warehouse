#!/bin/bash

superset db upgrade

superset fab create-admin \
  --username admin \
  --firstname Superset \
  --lastname Admin \
  --email admin@superset.com \
  --password admin

superset init

# superset load_examples
