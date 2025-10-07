FROM postgres:17.5-bookworm

RUN apt-get update -qq \
  && DEBIAN_FRONTEND=noninteractive apt-get install -yq --no-install-recommends \
  postgresql-17-postgis-3 \
  postgresql-17-repack \
  && rm -rf /var/lib/apt/lists/*

# Ensure extensions on first cluster init (runs only when the data dir is new)
COPY initdb.d/ /docker-entrypoint-initdb.d/

# Runtime helper to ensure pg_repack extension exists across DBs
COPY ensure_pg_repack.sh /usr/local/bin/ensure_pg_repack
RUN chmod +x /usr/local/bin/ensure_pg_repack