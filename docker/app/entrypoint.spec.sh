#!/bin/bash
set -e

cp /app/.pgpass ~/.pgpass
chown $(whoami):$(whoami) ~/.pgpass
chmod 600 ~/.pgpass

# Then exec the container's main process (what's set as CMD in the Dockerfile).
exec "$@"
