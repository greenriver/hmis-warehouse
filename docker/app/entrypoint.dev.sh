#!/bin/bash
set -e

if [[ -d /node_modules ]]
then
  if [[ -L /app/node_modules ]]
  then
    # no news is good news
    # echo /app/node_modules is a symlink as desired
    echo ""
  else
    echo Saving /app/node_modules with alternate name
    mv /app/node_modules "/app/node_modules.`date +'%s'`" || echo "no node modules to save"

    echo Symlinking /app/node_modules to /node_modules
    ln -s /node_modules /app/node_modules
  fi
fi


# Remove a potentially pre-existing server.pid for Rails.
rm -f /app/tmp/pids/server.pid

cd /app
bundle config --global set build.sassc --disable-march-tune-native
bundle install --quiet || echo "bundle install failed"
yarn install --silent --frozen-lockfile || echo "yarn install failed"

# Then exec the container's main process (what's set as CMD in the Dockerfile).
exec "$@"
