#!/bin/bash

# given a directory containing a repo checkout, build and run the HMIS frontend locally

if [ $# -lt 1 ]; then
  echo "Usage: $0 <directory>"
  exit 1
fi
directory="$1"

set -e
set -x

cd "$directory"

if [ -z "$SKIP_BUILD" ]; then
  yarn config set ignore-engines true
  yarn install
  yarn build
fi

set +e
set +x

# hostname for chrome container to connect to this container
HOSTNAME=`hostname`

if [ -z "$HMIS_SERVER_URL" ]; then
  HMIS_SERVER_URL="http://localhost:4444"
fi

set -x
SERVER_HTTPS=false HMIS_SERVER_URL=$HMIS_SERVER_URL HMIS_HOST=$HOSTNAME yarn preview
