FROM chrislusf/seaweedfs:4.47@sha256:ce9e796f1fe6f06968f4c04bdaf8f678dad9c8acdfef3d244133d71bfa6bf882

LABEL org.opencontainers.image.source="https://github.com/greenriver/hmis-warehouse"

COPY s3.json /etc/seaweedfs/s3.json
COPY entrypoint.sh /entrypoint-s3.sh
COPY healthcheck.sh /healthcheck-s3.sh

# GitHub service containers and compose's service_healthy both wait on this
HEALTHCHECK --interval=2s --timeout=3s --start-period=5s --retries=15 CMD ["/bin/sh", "/healthcheck-s3.sh"]

ENTRYPOINT ["/bin/sh", "/entrypoint-s3.sh"]
