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
cat > ~/.pgpass << EOF
${DATABASE_HOST:-db}:${DATABASE_PORT:-5432}:*:${DATABASE_USER:-postgres}:${DATABASE_PASS:-postgres}
${WAREHOUSE_DATABASE_HOST:-db}:${WAREHOUSE_DATABASE_PORT:-5432}:*:${WAREHOUSE_DATABASE_USER:-postgres}:${WAREHOUSE_DATABASE_PASS:-postgres}
${HEALTH_DATABASE_HOST:-db}:${HEALTH_DATABASE_PORT:-5432}:*:${HEALTH_DATABASE_USER:-postgres}:${HEALTH_DATABASE_PASS:-postgres}
${REPORTING_DATABASE_HOST:-db}:${REPORTING_DATABASE_PORT:-5432}:*:${REPORTING_DATABASE_USER:-postgres}:${REPORTING_DATABASE_PASS:-postgres}
EOF

if [ -n "$CAS_DATABASE_HOST" ]; then
  echo "${CAS_DATABASE_HOST}:${CAS_DATABASE_PORT:-5432}:*:${CAS_DATABASE_USER:-postgres}:${CAS_DATABASE_PASS:-postgres}" >> ~/.pgpass
fi

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
