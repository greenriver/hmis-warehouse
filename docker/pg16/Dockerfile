FROM postgres:16.3-bullseye

RUN apt-get update -qq \
  && DEBIAN_FRONTEND=noninteractive apt-get install -yq --no-install-recommends \
  postgresql-16-postgis-3
