#!/bin/sh

# Exit on any error
# set -e

# auto-export variables
set -a

echo Getting Role Info
curl --silent 169.254.170.2$AWS_CONTAINER_CREDENTIALS_RELATIVE_URI > role.info.log

cd /app

echo Getting secrets for the environment
./bin/download_secrets.rb > .env

echo Sourcing environment
. .env

echo Setting Timezone
cp /usr/share/zoneinfo/$TIMEZONE /etc/localtime
echo $TIMEZONE > /etc/timezone

echo Syncing the assets from s3
./bin/sync_app_assets.rb

echo Setting PGPass
echo "$DATABASE_HOST:*:*:$DATABASE_USER:$DATABASE_PASS" > /root/.pgpass
chmod 600 /root/.pgpass

if [ "$NEEDS_PRECOMPILE" = "true" ]
then
  echo Precompiling
  bundle exec rake assets:precompile
  echo Done precompiling
else
  echo No Precompiling
fi

#cat /app/.env

# Then exec the container's main process (what's set as CMD in the Dockerfile).
exec "$@"
