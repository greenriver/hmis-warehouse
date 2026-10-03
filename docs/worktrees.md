# Development worktrees

Run multiple isolated copies of hmis-warehouse at once — each on its own branch,
with its own databases and compose project — using [worktrunk](https://worktrunk.dev)
(`wt`) and this repo's worktree hooks.

Each worktree shares the **one** postgres/redis/s3 container stack from the main
tree but talks to **separate databases** (a `_wt_<name>` suffix), so work in a
worktree never touches your main development or test databases. Worktrees are
for code and tests; running the web app in one isn't supported. A worktree
starts with empty `_wt_` databases and no login, it has no traefik route, and
Rails keeps the primary's `FQDN`, so cable and absolute URLs point at the primary.

## Requirements

- worktrunk installed, with shell integration: `wt config shell install`
- [direnv](https://direnv.net/) installed and hooked into your shell
- The main tree's backing services running (worktrees share them):
  ```sh
  docker compose -p hmis-warehouse up -d db redis s3
  ```

## Files involved

| File | Purpose |
|------|---------|
| `.config/wt.toml` | worktrunk project hooks (`pre-start`, `pre-remove`) — committed |
| `lib/development/scripts/worktree_pre_start.sh` | copies gitignored env/compose files (plus `.env.test.local` and `CLAUDE.local.md` when the primary has them) into the new worktree, then rewrites them |
| `lib/development/scripts/update_worktree_env.rb` | isolates DB names, sets the compose project, turns traefik off, disables CAS |
| `lib/development/scripts/worktree_pre_remove.sh` | drops the worktree's databases and removes its containers |
| `docker-compose.yml` | `NAME_PREFIX` prefixes container names and image tags (see [A second full install](#a-second-full-install)) — committed |
| `docker-compose.override.yml` | per-worktree copy: adds `.env.test.local` to `spec`, gives `web`/`yarn` unique container names, points cache volumes at the primary's shared `<prefix>hmis-warehouse_*` volumes (gitignored) |

The `/worktree-setup` and `/worktree-cleanup` Claude Code skills automate the flow
below; they are personal (user-level) and not shipped in this repo.

## What isolation you get

- **Databases:** dev + test databases are suffixed `_wt_<name>` in the shared
  `hmis-warehouse-db` container. `bin/db_prep` and `db:setup_test` create them.
- **Web:** not supported; no traefik route (`TRAEFIK_ENABLED=false` in the worktree `.envrc`).
- **Compose project:** `hmis-warehouse-<name>` so app containers coexist.
- **Shared (not isolated):** the `db`/`redis`/`s3` containers, the bundle /
  node_modules / rails_cache volumes, and the CAS database (disabled in worktrees).

## Manual workflow

```sh
# 1. Create the worktree (runs the pre-start hook: copies + rewrites env/compose files)
wt switch --create ea-1234-my-feature --yes

# 2. Allow the worktree's direnv (loads COMPOSE_PROJECT_NAME / TRAEFIK_ENABLED=false)
direnv allow

# 3. Create the isolated databases (mirrors bin/setup). --no-deps uses the shared db.
docker compose run --rm --no-deps shell bundle exec bin/db_prep
docker compose run --rm --no-deps spec  bundle exec rails db:setup_test

# 4. Run tests against the worktree's test databases
docker compose run --rm --no-deps spec bundle exec rspec path/to/spec.rb

# 5. Tear down when done (runs pre-remove: drops databases, removes containers)
wt remove ea-1234-my-feature
```

## Naming

`ea-1234-my-feature` becomes:
- database suffix `_wt_ea_1234_my_feature`
- compose project `hmis-warehouse-ea-1234-my-feature`
- containers `hmis-warehouse-web-ea-1234-my-feature` / `hmis-warehouse-yarn-ea-1234-my-feature`

With `NAME_PREFIX=ai-` in the primary `.envrc`, each of those names gains the
`ai-` prefix.

Keep names reasonably short — the suffix is appended to each database name (postgres
identifiers are capped at 63 characters).

## Notes & caveats

- **Backing services are shared singletons** started from the main tree. Always use
  `--no-deps` for worktree `run`/`up` commands so they attach to those instead of
  spawning duplicates (which would collide on the fixed container names).
- **Don't run `bundle install` in two worktrees simultaneously** — the gem cache
  volume is shared.  It is safe to run them sequentially in the main tree and the worktree.
- **CAS is disabled in worktrees** (`DATABASE_CAS_DB` / `CAS_DATABASE_DB_TEST` are
  blanked). Do cross-application work involving boston-cas in the **main** tree.
- **Redis is shared** (cache only); worktrees reuse the same Redis.
- **Don't run the full RSpec suite in a worktree at the same time as another suite**
  (e.g. in the main tree). Databases are isolated, but the postgres *server's* lock
  table is shared (`max_locks_per_transaction` × `max_connections` ≈ 6400 slots by
  default). The suite's `before(:suite)` truncates every warehouse table, grabbing
  thousands of locks; two suites at once can exhaust the table and fail with
  `PG::OutOfMemory`. Setup (`db_prep`/`db:setup_test`), running the web app, and
  background jobs are lock-light and fine to run concurrently. To run two full
  suites at once, raise the lock table in your **local** `docker-compose.override.yml`
  `db` block (it's gitignored, so this is a per-developer setting):
  ```yaml
    db:
      command: "-c max_locks_per_transaction=256"
  ```
  Then recreate the container when no one is mid-test (drops connections; data
  persists in the volume): `docker compose -p hmis-warehouse up -d db`, and verify
  with `docker exec -i hmis-warehouse-db psql -U postgres -c "SHOW max_locks_per_transaction;"`.
  Use a larger value (e.g. 512) if you want 3+ concurrent suites.

## A second full install

To run another complete copy of the app beside this one (its own db, redis, s3,
and web), clone it to a separate directory and set these in its `.envrc`:

```sh
export NAME_PREFIX=ai-                  # container names and image tags
export COMPOSE_PROJECT_NAME=ai-hmis-warehouse
export TRAEFIK_ROUTER_NAME=ai-hmis-warehouse
export FQDN=ai-hmis-warehouse.dev.test
export DBPORT=25432                     # plus MSSQL_PORT / DJ_METRICS_PORT if you use them
export S3_PORT=19000 S3_FILER_PORT=18888
export LOCAL_S3_DOMAIN=ai-s3.dev.test
```

Its env files must point at its own containers by name (`DATABASE_HOST=ai-hmis-warehouse-db`,
`CACHE_HOST=ai-hmis-warehouse-redis`, `LOCAL_S3_ENDPOINT=https://ai-s3.dev.test:19000`), and its
`docker-compose.override.yml` should move it off the shared `development` network. Otherwise
the `db` / `redis` service aliases resolve to both installs. Worktrees of that copy pick up the
prefix from its `.envrc` and share its backing services, not main's.

To make its databases easy to tell apart from main's, give them a prefix too. Set the dev
names (`DATABASE_APP_DB=ai_development_openpath_app`, and so on) in its `.env.development.local`.
For the test names, put the `*_DB_TEST` keys in a `.env.test.local` and have `spec` load it:

```yaml
services:
  spec:
    env_file:
      - .env.test.local
```

Its worktrees copy that `.env.test.local` and add their `_wt_` suffix to those names.
