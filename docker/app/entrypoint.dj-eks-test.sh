#!/bin/bash

echo "Starting metrics server"
# not cluster mode with 5 threads
bundle exec puma  --no-config -w 0 -t 1:5 /app/dj-metrics/config.ru &

export EAGER_LOAD=true
echo "Calling: $@"
exec bundle exec delayed_job run "$@"
