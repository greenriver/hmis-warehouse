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

## Service config (Admin API credentials)

`Idp::KeycloakService` (`app/services/idp/keycloak_service.rb`) talks to the Keycloak **Admin
REST API** — creating/updating users, profile edits, the migration tooling. It authenticates with
the OAuth2 `client_credentials` grant using the **`rails-service-account`** client (a *service
account*, not the `dex-connector` browser client). That client needs the `realm-management` roles
(`manage-users`, `view-users`, `query-users`, `manage-realm`); `realm-import.json` grants them on
first import.

`Idp::KeycloakService` needs four values — `api_url`, `realm`, `client_id`, `client_secret`. There
are two ways to supply them; the DB-managed config wins when both are present (see
`Idp::ServiceFactory.for_connector`).

### Option A — DB-managed `Idp::ServiceConfig` (preferred)

Credentials live in the `idp_service_configs` table and are managed in the admin UI at
**`/admin/idp_service_configs`** (New → provider `keycloak`). One row per realm. The columns map to
the service's config keys in `KeycloakService.from_config`:

| `Idp::ServiceConfig` column | Maps to service key | Dev value |
| --- | --- | --- |
| `provider` | (selects the service class) | `keycloak` |
| `connector_id` | the auth-proxy routing key in the JWT — must match the connector that issued the token | `keycloak` |
| `name` | display label only | e.g. `Keycloak (dev)` |
| `api_url` | `api_url` | `http://op-keycloak.dev.test:8080` |
| `keycloak_realm` | `realm` | `openpath` |
| `client_id` | `client_id` | `rails-service-account` |
| `service_token` (encrypted) | `client_secret` | `rails-service-account-secret-dev` |

`service_token` is stored `attr_encrypted` (needs `ENCRYPTION_KEY` set). To create one from the
console instead of the UI:

```ruby
Idp::ServiceConfig.create!(
  provider:       'keycloak',
  connector_id:   'keycloak',
  name:           'Keycloak (dev)',
  api_url:        'http://op-keycloak.dev.test:8080',
  keycloak_realm: 'openpath',
  client_id:      'rails-service-account',
  service_token:  'rails-service-account-secret-dev',
  active:         true,
)
```

Verify it end-to-end with the row's `#test` action (the **Test** button in the UI) or
`config.to_service.test_connection` — a green result means the secret is valid *and* the service
account has the Admin-API roles.

### Option B — ENV fallback (single realm)

With no matching active `ServiceConfig`, the factory falls back to the registered service class,
which reads ENV (`KeycloakService#default_config`):

```
KEYCLOAK_API_URL=http://op-keycloak.dev.test:8080
KEYCLOAK_REALM=openpath
KEYCLOAK_SERVICE_CLIENT_ID=rails-service-account
KEYCLOAK_SERVICE_CLIENT_SECRET=rails-service-account-secret-dev
```

In the dev stack these are already provided to the `web` container via
`docker/auth/keycloak-credentials.env` (loaded through `env_file`), so the service account works
out of the box — no `.env.development.local` edits needed. This path only resolves when the JWT's
`connector_id` equals the provider key `keycloak`.

> Heads-up: `realm-import.json` is applied only on the **first** import into a fresh `keycloak`
> database. If your volume predates the `rails-service-account` client (or its roles), the token
> grant 401s or the Admin API 403s. Confirm the live client with
> `kcadm.sh get clients -r openpath -q clientId=rails-service-account --fields clientId,secret,serviceAccountsEnabled`
> (after `kcadm.sh config credentials --server http://localhost:8080 --realm master --user admin
> --password 'AdminPassword1!'`), and reset the secret in the admin console or recreate the realm
> from a clean DB if it drifted.

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

## Related

- [User migration (`rails keycloak:*`)](./keycloak-user-migration.md) — seeding Keycloak from legacy
  Devise/warehouse accounts before a Deployment switches to JWT auth.
