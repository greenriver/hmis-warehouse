#!/bin/sh

# Exit on any error
# set -e

# auto-export variables
set -a

cd /app

echo 'Commenting out pg_fixtures which bundler tries to load in production and staging for some reason'
sed -i.bak '/pg_fixtures/d' Gemfile

if [ "${EKS}" != "true" ]; then
  echo Getting Role Info
  curl --connect-timeout 2 --silent 169.254.170.2$AWS_CONTAINER_CREDENTIALS_RELATIVE_URI >role.info.log

  echo 'Getting secrets for the environment...'
  T1=$(date +%s)

  # TODO: this should be handled by the caching GitHub Action, but that seems to miss
  # a gem occassionally.  Running bundle install will catch any gems not previously cached
  bundle install

  bundle exec ./bin/download_secrets.rb >.env

  echo Sourcing environment
  . /app/.env

  echo Getting parameter store params
  bundle exec ./bin/download_params.rb >>.env

  T2=$(date +%s)
  echo "...secrets and params took $(expr $T2 - $T1) seconds"

  echo Sourcing environment again to gain parameter store params
  . /app/.env
else
  echo Not sourcing environment variables from secretsmanager
fi

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
