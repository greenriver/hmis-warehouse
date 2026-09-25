#!/bin/sh
# Serve TLS when /certs/public.crt and /certs/private.key are mounted (dev); plain HTTP otherwise (CI)
set -e
tls=""
if [ -f /certs/public.crt ] && [ -f /certs/private.key ]; then
  tls="-s3.cert.file=/certs/public.crt -s3.key.file=/certs/private.key"
fi
# Single-node all-in-one server for dev/CI only. Each bucket gets its own volumes, so the
# default 8-volume cap runs out when specs create many buckets; small volumes + auto cap avoid that.
exec weed server -dir=/data -master.volumeSizeLimitMB=1024 -volume.max=0 -s3 -s3.port=9000 -s3.config=/etc/seaweedfs/s3.json $tls
