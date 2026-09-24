#!/bin/sh
# Serve TLS when /certs/public.crt and /certs/private.key are mounted (dev); plain HTTP otherwise (CI)
set -e
tls=""
if [ -f /certs/public.crt ] && [ -f /certs/private.key ]; then
  tls="-s3.cert.file=/certs/public.crt -s3.key.file=/certs/private.key"
fi
exec weed server -dir=/data -s3 -s3.port=9000 -s3.config=/etc/seaweedfs/s3.json $tls
