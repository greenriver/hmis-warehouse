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
mkdir -p dev/minio/certs
cp "$TRAEFIK_PATH/traefik/tools/certs/dev.test.crt" dev/minio/certs/public.crt
cp "$TRAEFIK_PATH/traefik/tools/certs/dev.test.key" dev/minio/certs/private.key
docker compose up -d --force-recreate s3
```
