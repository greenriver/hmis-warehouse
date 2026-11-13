# Stage 1: Download and verify provider JARs.
# curlimages/curl is Alpine-based and includes sha256sum via busybox.
FROM curlimages/curl:latest AS downloader

RUN curl -fsSL -o /tmp/keycloak-bcrypt-1.7.0.jar \
      https://github.com/leroyguillaume/keycloak-bcrypt/releases/download/v1.7.0/keycloak-bcrypt-1.7.0.jar \
    && echo "b32a7557c1bdcf67da9bfde075b20aabd00d26e04aa4db2ba85765b8e94c9f28  /tmp/keycloak-bcrypt-1.7.0.jar" \
         | sha256sum -c -

RUN curl -fsSL -o /tmp/keycloak-breached-passwords-0.2.0.jar \
      https://github.com/ttoomey/keycloak-breached-passwords/releases/download/v0.2.0/keycloak-breached-passwords-0.2.0.jar \
    && echo "d2bfa89495cb1a2e92f8bed78bf2d8702eeaad4efe1e84f6875c2fe3baa7c997  /tmp/keycloak-breached-passwords-0.2.0.jar" \
         | sha256sum -c -

# Stage 2: Final Keycloak image with providers baked in.
# Version is pinned here — update this line to upgrade Keycloak.
FROM quay.io/keycloak/keycloak:26.7.4

COPY --from=downloader /tmp/keycloak-bcrypt-1.7.0.jar /opt/keycloak/providers/keycloak-bcrypt-1.7.0.jar
COPY --from=downloader /tmp/keycloak-breached-passwords-0.2.0.jar /opt/keycloak/providers/keycloak-breached-passwords-0.2.0.jar
