FROM postgres:12.15-bullseye

RUN apt-get update -qq \
  && DEBIAN_FRONTEND=noninteractive apt-get install -yq --no-install-recommends \
    postgresql-12-postgis-3
