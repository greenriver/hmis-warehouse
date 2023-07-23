FROM postgres:13.11-bullseye

RUN apt-get update -qq \
  && DEBIAN_FRONTEND=noninteractive apt-get install -yq --no-install-recommends \
    postgresql-13-postgis-3
