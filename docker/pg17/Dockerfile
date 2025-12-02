FROM postgres:17.5-bookworm

RUN apt-get update -qq \
  && DEBIAN_FRONTEND=noninteractive apt-get install -yq --no-install-recommends \
  ca-certificates \
  postgresql-17-postgis-3 \
  postgresql-server-dev-17 \
  build-essential \
  curl \
  unzip \
  libzstd-dev \
  liblz4-dev \
  zlib1g-dev \
  libreadline-dev \
  && rm -rf /var/lib/apt/lists/*

# Build pg_repack 1.5.2 from source
RUN set -e; \
  mkdir -p /tmp/pg_repack_build && cd /tmp/pg_repack_build; \
  curl -L -o "pg_repack-1.5.2.zip" "https://api.pgxn.org/dist/pg_repack/1.5.2/pg_repack-1.5.2.zip"; \
  unzip -q "pg_repack-1.5.2.zip"; \
  cd "pg_repack-1.5.2"; \
  make PG_CONFIG=/usr/lib/postgresql/17/bin/pg_config; \
  make install PG_CONFIG=/usr/lib/postgresql/17/bin/pg_config; \
  cd / && rm -rf /tmp/pg_repack_build

# Ensure extensions on first cluster init (runs only when the data dir is new)
COPY initdb.d/ /docker-entrypoint-initdb.d/

# Runtime helper to ensure pg_repack extension exists across DBs
COPY ensure_pg_repack.sh /usr/local/bin/ensure_pg_repack
RUN chmod +x /usr/local/bin/ensure_pg_repack