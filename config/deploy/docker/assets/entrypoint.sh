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

echo Constructing an ERB-free database.yml file
ruby ./bin/materialize.database.yaml.rb

echo Setting Timezone
cp /usr/share/zoneinfo/$TIMEZONE /app/etc-localtime
echo $TIMEZONE > /etc/timezone

echo Syncing the assets from s3
./bin/sync_app_assets.rb

echo Pulling down assets from S3
bundle exec rake assets:clobber && mkdir -p ./public/assets
ASSET_CHECKSUM=`ASSETS_PREFIX=${ASSETS_PREFIX} ./bin/asset_checksum`
cd ./public/assets
# Pull down the compiled assets. Using ASSETS_PREFIX from .env and GITHASH from Docker args.
echo "!!! using ASSET_CHECKSUM ${ASSET_CHECKSUM}"
ASSETS_PREFIX="${ASSETS_PREFIX}/${ASSET_CHECKSUM}" ASSETS_BUCKET_NAME=openpath-precompiled-assets UPDATE_ONLY=true ../../bin/sync_app_assets.rb
cd ../..

#cat /app/.env

# Then exec the container's main process (what's set as CMD in the Dockerfile).
echo "calling: $@"
exec "$@"
