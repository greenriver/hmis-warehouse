#!/bin/bash
set -e

# Remove a potentially pre-existing server.pid for Rails.
rm -f /app/tmp/pids/server.pid

cd /app
bundle config --global set build.sassc --disable-march-tune-native
bundle install
yarn install

# Then exec the container's main process (what's set as CMD in the Dockerfile).
exec "$@"
