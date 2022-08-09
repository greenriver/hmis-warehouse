#!/bin/bash
set -e

# Remove a potentially pre-existing server.pid for Rails.
rm -f /app/tmp/pids/server.pid

cd /app
bundle config --global set build.sassc --disable-march-tune-native
bundle install
yarn install

if [ ! -e /bundle/ruby/2.7.0/gems/seven_zip_ruby-1.3.0/lib/seven_zip_ruby/7z.so ]
then
  echo Reinstalling seven_zip_ruby because the dynamic link library is not in the correct place

  bundle exec gem uninstall seven_zip_ruby

  bundle install

  if [ -e /usr/local/lib/ruby/site_ruby/2.7.0/x86_64-linux-musl/seven_zip_ruby/7z.so ]
  then
    cp /usr/local/lib/ruby/site_ruby/2.7.0/x86_64-linux-musl/seven_zip_ruby/7z.so \
      /bundle/ruby/2.7.0/gems/seven_zip_ruby-1.3.0/lib/seven_zip_ruby/7z.so
  fi
fi

# Then exec the container's main process (what's set as CMD in the Dockerfile).
exec "$@"
