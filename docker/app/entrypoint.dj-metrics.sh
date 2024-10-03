#!/bin/sh

if [[ "$RAILS_ENV" != 'development' ]] ; then
  echo 'Commenting out pg_fixtures which bundler tries to load in production and staging for some reason'
  sed -i.bak '/pg_fixtures/d' Gemfile
fi

echo 'Setting Timezone'
cp /usr/share/zoneinfo/$TIMEZONE /app/etc-localtime
echo $TIMEZONE > /etc/timezone

cd /app/dj-metrics

export BUNDLE_GEMFILE=../Gemfile

exec bundle exec rackup --host 0.0.0.0
