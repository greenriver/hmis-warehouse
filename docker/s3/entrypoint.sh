#!/bin/sh
# Serve TLS when /certs/public.crt and /certs/private.key are mounted (dev); plain HTTP otherwise (CI).
# RustFS expects rustfs_cert.pem/rustfs_key.pem in RUSTFS_TLS_PATH, so link the minio-named certs there.
set -e
if [ -f /certs/public.crt ] && [ -f /certs/private.key ]; then
  mkdir -p /tmp/tls
  ln -sf /certs/public.crt /tmp/tls/rustfs_cert.pem
  ln -sf /certs/private.key /tmp/tls/rustfs_key.pem
  export RUSTFS_TLS_PATH=/tmp/tls
fi
# /entrypoint.sh is the upstream rustfs/rustfs image's entrypoint; re-check it exists when bumping the base tag
exec /entrypoint.sh rustfs
