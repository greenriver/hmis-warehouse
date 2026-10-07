#!/bin/sh
# Probe the S3 gateway on whichever scheme entrypoint.sh chose
scheme=http
if [ -f /certs/public.crt ] && [ -f /certs/private.key ]; then
  scheme=https
fi
exec curl -skf -o /dev/null "$scheme://localhost:${S3_PORT:-9000}/healthz"
