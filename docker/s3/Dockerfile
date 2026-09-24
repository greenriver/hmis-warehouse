FROM rustfs/rustfs:1.0.0@sha256:8cc9801755448b71a786705ce76692c77e14936cccd87cf2fc31842e58f4d1ff

LABEL org.opencontainers.image.source="https://github.com/greenriver/hmis-warehouse"

ENV RUSTFS_ACCESS_KEY=local_access_key \
    RUSTFS_SECRET_KEY=local_secret_key \
    RUSTFS_ADDRESS=:9000 \
    RUSTFS_VOLUMES=/data

COPY entrypoint.sh /entrypoint-s3.sh
COPY healthcheck.sh /healthcheck-s3.sh

# GitHub service containers and compose's service_healthy both wait on this
HEALTHCHECK --interval=2s --timeout=3s --start-period=5s --retries=15 CMD ["/bin/sh", "/healthcheck-s3.sh"]

ENTRYPOINT ["/bin/sh", "/entrypoint-s3.sh"]
