Local S3-compatible storage (SeaweedFS) for development and GitHub workflows.
GitHub workflow services can't specify a command, so we build our own image with
the dev credentials (`s3.json`) and startup command baked in. docker-compose builds
the same image so dev and CI match.

## HTTPS in dev

Rails and the browser both use `https://s3.dev.test:9000` (presigned URLs), and inside
the docker network `s3.dev.test` resolves to this container, not traefik, so the container
serves TLS itself. `entrypoint.sh` turns TLS on when `/certs/public.crt` and
`/certs/private.key` exist; otherwise it serves plain HTTP (as in CI). Reuse the
`*.dev.test` cert from `bin/developer/certificates.sh`:

```sh
mkdir -p dev/s3/certs
cp "$TRAEFIK_PATH/traefik/tools/certs/dev.test.crt" dev/s3/certs/public.crt
cp "$TRAEFIK_PATH/traefik/tools/certs/dev.test.key" dev/s3/certs/private.key
docker compose up -d --force-recreate s3
```

## Migrating from MinIO

Rename these in `.env.local` / `.env.development.local` if you set them:

| Old | New |
| --- | --- |
| `MINIO_ENDPOINT` | `LOCAL_S3_ENDPOINT` |
| `USE_MINIO_ENDPOINT` | `USE_LOCAL_S3_ENDPOINT` |
| `MINIO_DOMAIN` | `LOCAL_S3_DOMAIN` |
| `ACTIVE_STORAGE_SERVICE=minio` | `ACTIVE_STORAGE_SERVICE=local_s3` |

Move existing certs with `mv dev/minio/certs dev/s3/certs` (from `docker/`). MinIO data
doesn't carry over, so `dev/minio` can be deleted.

There's no MinIO-style admin console. To browse bucket contents, use the filer web UI at
<http://localhost:8888/buckets/>.
