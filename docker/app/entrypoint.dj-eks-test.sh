#!/bin/bash

export EAGER_LOAD=true
echo "Calling: $@"
exec bundle exec delayed_job run "$@"
