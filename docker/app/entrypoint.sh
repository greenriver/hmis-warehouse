#!/bin/sh

# Exit on any error
# set -e

# auto-export variables
set -a

cd /app

echo 'Commenting out pg_fixtures which bundler tries to load in production and staging for some reason'
sed -i.bak '/pg_fixtures/d' Gemfile

# Secrets and parameter-store values are injected by Kubernetes before this runs.

echo 'Constructing an ERB-free database.yml file...'
T1=$(date +%s)
bundle exec ./bin/materialize.database.yaml.rb
T2=$(date +%s)
echo "...database materialize took $(expr $T2 - $T1) seconds"

echo 'Generating .pgpass file from environment variables...'
bundle exec ./bin/generate_pgpass.rb > ~/.pgpass
chmod 600 ~/.pgpass

echo 'Setting Timezone'
cp /usr/share/zoneinfo/$TIMEZONE /app/etc-localtime
echo $TIMEZONE >/etc/timezone

# Target web containers for release tag resolution.
case "$CONTAINER_VARIANT" in
  '' | web)
    echo 'Resolving release tag from the deployed commit'
    bundle exec ruby ./lib/util/git/release_resolver.rb || echo 'release resolution failed; continuing'
    ;;
  *)
    echo "Skipping release tag resolution on $CONTAINER_VARIANT container"
    ;;
esac

if [ "$CONTAINER_VARIANT" = "dj" ]; then
  if [ "${ENABLE_DJ_METRICS}" = "true" ]; then
    echo "Starting metrics server"
    # Not in cluster mode but with 5 threads
    bundle exec puma --no-config -w 0 -t 1:5 /app/dj-metrics/config.ru &
  fi
fi

# Then exec the container's main process (what's set as CMD in the Dockerfile).
echo "calling: $@"
exec bundle exec "$@"
