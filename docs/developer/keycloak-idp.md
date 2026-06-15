# Keycloak IDP Integration (dev stack)

The opt-in local Docker Compose stack that reproduces the production auth chain. Application wiring
(JWT validation, identity resolution, `Idp::Service`, user-migration tasks) lands in later branches.

```
User → OAuth2-Proxy → Dex (OIDC broker) → Keycloak → Rails (JWT headers)
```

The `openpath` realm is auto-imported on first boot with two clients — `dex-connector` (OIDC auth
code flow for Dex) and `rails-service-account` (client credentials for the Rails admin API) — plus the
`warehouse-users` and `hmis-users` groups.

## Setup

The auth stack lives in `docker/docker-compose.auth.yml` and is **opt-in**: a plain `docker compose up`
is unchanged (no auth services, normal Devise dev). You enable it by passing the override file.

**1. Hosts entries** (`hmis-warehouse.dev.test` / `hmis.dev.test` / `hmis-backend.dev.test` are
usually already present; add if not):

```
127.0.0.1 op-keycloak.dev.test dex.dev.test
```

**2. Cookie secret + config.** The stack needs one secret. Set `OAUTH2_PROXY_COOKIE_SECRET` in
`.env.development.local` (copy the line from `sample.env`), then generate the oauth2-proxy
alpha-config into the gitignored `dev/auth/`:

```bash
openssl rand -hex 16   # value for OAUTH2_PROXY_COOKIE_SECRET
bash docker/auth/generate-dev-auth.sh
```

`generate-dev-auth.sh` is idempotent — re-run it after editing a template under
`docker/auth/templates/`.

**3. Databases.** On a fresh Postgres volume `keycloak`/`dex` are created automatically. On an
existing volume, create them once:

```bash
docker compose exec db psql -U postgres -c 'CREATE DATABASE keycloak'
docker compose exec db psql -U postgres -c 'CREATE DATABASE dex'
```

**4. Bring up the stack** with both compose files. Use the repo-root symlink (`docker-compose.yml`)
so the project directory stays at the repo root and all relative paths resolve correctly:

```bash
export COMPOSE_FILE=docker-compose.yml:docker/docker-compose.auth.yml
docker compose build keycloak
docker compose up
```

Then log into the Keycloak admin console at `https://op-keycloak.dev.test` (`admin` /
`AdminPassword1!`); the `openpath` realm should be in the selector.

## Notes

- **Warehouse-only?** `oauth2-proxy-hmis` upstreams to Vite on the host (`host.docker.internal:5173`)
  and only matters on `hmis.dev.test`. Skip it — bring up just
  `keycloak dex oauth2-proxy-warehouse web` and use `hmis-warehouse.dev.test`.
- **Linux:** the proxies use `extra_hosts: …:host-gateway`; needs a recent Docker Engine (it resolves
  out of the box on Docker Desktop).
- **Credentials:** `docker/auth/keycloak-credentials.env` is committed because its values are
  pre-defined in `realm-import.json` (chosen, not generated). Dev-only — never used in production. It
  provides `KEYCLOAK_API_URL`, `KEYCLOAK_REALM`, and the `dex-connector` / `rails-service-account`
  client IDs and secrets.

## User migration (`rails keycloak:*`)

`lib/tasks/keycloak.rake` seeds Keycloak from the legacy Devise/warehouse `User` records before a
Deployment flips to JWT auth. It is **temporary, human-run, console-only** ops tooling — run by hand,
per Deployment, in the migrate → flip window; never on boot or in a request. It drives
`Idp::Keycloak::UserImporter` over `Idp::KeycloakService#partial_import`. Run `rails -T keycloak` for
the full task list and the rake header for usage.

- **Scope.** `Idp::Keycloak::UserImporter.migration_scope` migrates confirmed + active users. The
  `confirmed_at` filter also excludes invited-but-not-accepted users (they have no credential to carry
  and are provisioned on first JWT login after the flip).
- **Delta re-run.** Both `migrate_users` and `export_users` accept a `since` timestamp so the last
  pre-flip run only re-imports users changed during migration, keeping the migrate → flip gap to minutes.
- **2FA backup codes are NOT migrated.** The importer carries the TOTP secret but drops
  `otp_backup_codes` — Keycloak's recovery-code format differs and there is no clean `partialImport`
  mapping. A user who relied on backup codes at first post-cutover login must use their authenticator
  app, or have an admin reset 2FA in Keycloak.
