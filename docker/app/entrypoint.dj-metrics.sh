#!/bin/sh

if [[ "$RAILS_ENV" != 'development' ]] ; then
  echo 'Commenting out pg_fixtures which bundler tries to load in production and staging for some reason'
  sed -i.bak '/pg_fixtures/d' Gemfile
fi

echo 'Constructing an ERB-free database.yml file...'
T1=`date +%s`
bundle exec ./bin/materialize.database.yaml.rb
T2=`date +%s`
echo "...database materialize took $(expr $T2 - $T1) seconds"

echo 'Setting Timezone'
cp /usr/share/zoneinfo/$TIMEZONE /app/etc-localtime
echo $TIMEZONE > /etc/timezone

cd /app/dj-metrics

export BUNDLE_GEMFILE=../Gemfile

exec bundle exec rackup --host 0.0.0.0
