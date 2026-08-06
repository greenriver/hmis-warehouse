# Development worktrees

Run multiple isolated copies of hmis-warehouse at once — each on its own branch,
with its own databases and web domain — using [worktrunk](https://worktrunk.dev)
(`wt`) and this repo's worktree hooks.

Each worktree shares the **one** postgres/redis/minio container stack from the main
tree but talks to **separate databases** (a `_wt_<name>` suffix), so work in a
worktree never touches your main development or test databases. Multiple worktree
web servers can run concurrently, each at `hmis-warehouse-<name>.dev.test`.

## Requirements

- worktrunk installed, with shell integration: `wt config shell install`
- [direnv](https://direnv.net/) installed and hooked into your shell
- The main tree's backing services running (worktrees share them):
  ```sh
  docker compose -p hmis-warehouse up -d db redis minio
  ```

## Files involved

| File | Purpose |
|------|---------|
| `.config/wt.toml` | worktrunk project hooks (`pre-start`, `pre-remove`) — committed |
| `lib/development/scripts/worktree_pre_start.sh` | copies gitignored env/compose files into the new worktree, then rewrites them |
| `lib/development/scripts/update_worktree_env.rb` | isolates DB names, sets the domain/compose-project/traefik-router, disables CAS |
| `lib/development/scripts/worktree_pre_remove.sh` | drops the worktree's databases and removes its containers |
| `docker/docker-compose.yml` | `web` traefik router name is parameterized (`${TRAEFIK_ROUTER_NAME:-op}`) so concurrent webs don't collide — committed |
| `docker-compose.override.yml` | per-worktree copy: adds `.env.test.local` to `spec`, gives `web`/`yarn` unique container names, points cache volumes at the shared `hmis-warehouse_*` volumes (gitignored) |

The `/worktree-setup` and `/worktree-cleanup` Claude Code skills automate the flow
below; they are personal (user-level) and not shipped in this repo.

## What isolation you get

- **Databases:** dev + test databases are suffixed `_wt_<name>` in the shared
  `hmis-warehouse-db` container. `bin/db_prep` and `db:setup_test` create them.
- **Web domain:** `hmis-warehouse-<name>.dev.test` via traefik (per-worktree router).
- **Compose project:** `hmis-warehouse-<name>` so app containers coexist.
- **Shared (not isolated):** the `db`/`redis`/`minio` containers, the bundle /
  node_modules / rails_cache volumes, and the CAS database (disabled in worktrees).

## Manual workflow

```sh
# 1. Create the worktree (runs the pre-start hook: copies + rewrites env/compose files)
wt switch --create ea-1234-my-feature --yes

# 2. Allow the worktree's direnv (loads FQDN / COMPOSE_PROJECT_NAME / TRAEFIK_ROUTER_NAME)
direnv allow

# 3. Create the isolated databases (mirrors bin/setup). --no-deps uses the shared db.
docker compose run --rm --no-deps shell bundle exec bin/db_prep
docker compose run --rm --no-deps spec  bundle exec rails db:setup_test

# 4. Run tests against the worktree's test databases
docker compose run --rm --no-deps spec bundle exec rspec path/to/spec.rb

# 5. (Optional) Start the web app — coexists with other worktrees' webs
docker compose up -d --no-deps web yarn
#    → https://hmis-warehouse-ea-1234-my-feature.dev.test

# 6. Tear down when done (runs pre-remove: drops databases, removes containers)
wt remove ea-1234-my-feature
```

## Naming

`ea-1234-my-feature` becomes:
- database suffix `_wt_ea_1234_my_feature`
- domain `hmis-warehouse-ea-1234-my-feature.dev.test`
- compose project `hmis-warehouse-ea-1234-my-feature`
- traefik router `op-ea-1234-my-feature`

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
