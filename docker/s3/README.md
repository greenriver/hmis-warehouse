Local S3-compatible storage (SeaweedFS) for development and GitHub workflows.
GitHub workflow services can't specify a command, so we build our own image with
the dev credentials (`s3.json`) and startup command baked in. docker-compose builds
the same image so dev and CI match.
