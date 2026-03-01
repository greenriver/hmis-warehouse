# Stage 1: Download and verify provider JARs.
# curlimages/curl is Alpine-based and includes sha256sum via busybox.
FROM curlimages/curl:latest AS downloader

RUN curl -fsSL -o /tmp/keycloak-bcrypt-1.7.0.jar \
      https://github.com/leroyguillaume/keycloak-bcrypt/releases/download/v1.7.0/keycloak-bcrypt-1.7.0.jar \
    && echo "b32a7557c1bdcf67da9bfde075b20aabd00d26e04aa4db2ba85765b8e94c9f28  /tmp/keycloak-bcrypt-1.7.0.jar" \
         | sha256sum -c -

# Stage 2: Final Keycloak image with providers baked in.
# Version is pinned here — update this line to upgrade Keycloak.
FROM quay.io/keycloak/keycloak:26.5.4

COPY --from=downloader /tmp/keycloak-bcrypt-1.7.0.jar /opt/keycloak/providers/keycloak-bcrypt-1.7.0.jar
