FROM postgres:17.5-bookworm

RUN apt-get update -qq \
  && DEBIAN_FRONTEND=noninteractive apt-get install -yq --no-install-recommends \
  postgresql-17-postgis-3
