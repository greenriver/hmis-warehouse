Local S3-compatible storage (RustFS) for development and GitHub workflows.
GitHub workflow services can't specify a command, so we build our own image with
the dev credentials and startup command baked in. docker-compose builds the same
image so dev and CI match.

RustFS runs as uid 10001; the `./dev/minio/data` bind mount must be writable by it.
