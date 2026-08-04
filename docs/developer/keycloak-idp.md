# Keycloak IDP Integration (dev stack)

The opt-in local Docker Compose stack that reproduces the production auth chain.

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
`.env.development.local` (copy the line from `sample.env.development.local`), then generate the oauth2-proxy
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

`Idp::KeycloakService` talks to the Keycloak **Admin REST API** using the OAuth2
`client_credentials` grant on the **`rails-service-account`** client (a *service account*, not the
`dex-connector` browser client). That client needs the `realm-management` roles `manage-users`,
`view-users`, `query-users` and `manage-realm`; `realm-import.json` grants them on first import.

The `Idp::ServiceConfig` row is the **single source of truth** at request time. ENV is read **once**,
at deploy, to seed that row (see *Seeding from ENV* below); there is no request-time ENV fallback, so a
connector with no active row degrades to an unmanaged `NullService` rather than silently reading ENV.

### DB-managed `Idp::ServiceConfig`

Managed in the admin UI at **`/admin/idp_service_configs`** (New → provider `keycloak`), one row per
realm. Dev values:

| Column | Dev value |
| --- | --- |
| `provider` | `keycloak` |
| `connector_id` | `keycloak` — the auth-proxy routing key in the JWT; must match the connector that issued the token |
| `name` | e.g. `Keycloak (dev)` (display only) |
| `api_url` | `http://op-keycloak.dev.test:8080` |
| `keycloak_realm` | `openpath` |
| `client_id` | `rails-service-account` |
| `service_token` (encrypted, needs `ENCRYPTION_KEY`) | `rails-service-account-secret-dev` |
| `browser_url` | `https://op-keycloak.dev.test` — public origin for browser deep-links (blank ⇒ `api_url`) |
| `account_client_id` | `account` — OIDC client for account deep-links (blank ⇒ `account`) |
| `manage_users` | `true` — see *Manage-users capability* below |

Verify with the row's **Test** button — a green result means the secret is valid *and* the service
account has the Admin-API roles.

### Seeding from ENV

`SeedMaker#seed_idp_service_config` materializes the row from ENV on deploy, so an existing
ENV-configured install keeps working without a manual UI step:

```
KEYCLOAK_API_URL=http://op-keycloak.dev.test:8080
KEYCLOAK_REALM=openpath
KEYCLOAK_SERVICE_CLIENT_ID=rails-service-account
KEYCLOAK_SERVICE_CLIENT_SECRET=rails-service-account-secret-dev
KEYCLOAK_PUBLIC_URL=https://op-keycloak.dev.test
KEYCLOAK_ACCOUNT_CLIENT_ID=account
```

The dev stack provides these to the `web` container via `docker/auth/keycloak-credentials.env`. Seeding
is **create-only and idempotent**: it runs on every deploy but never clobbers a later UI edit, never
resurrects a soft-deleted row, and never reactivates a disabled one. It is gated on the JWT auth method
and on `KEYCLOAK_API_URL`/`KEYCLOAK_SERVICE_CLIENT_SECRET` being present, so a Devise install or an
external-IdP customer (no `KEYCLOAK_*`) is a silent no-op. `KEYCLOAK_CONNECTOR_ID` (default `keycloak`)
sets the row's `connector_id`. After the row exists, credential rotation is a UI/DB operation — ENV is
not read again.

### Browser URL vs Admin API URL

`api_url` is where Rails calls the Admin API. Anything handed to a *browser* instead uses `browser_url`
from the row, falling back to `api_url` when blank.

The two only differ in the dev stack: Rails uses the compose network alias
(`http://op-keycloak.dev.test:8080`), and the browser has to go through Traefik
(`https://op-keycloak.dev.test`) because the SSO session cookies are `Secure` and belong to that
origin. Pointing `api_url` at Traefik instead breaks the Admin API, since Traefik serves a
per-developer self-signed `*.dev.test` cert that only the host keychain trusts
(`bin/developer/certificates.sh`). Both are seeded from `docker/auth/keycloak-credentials.env`.

`browser_url` is a per-realm column (seeded from `KEYCLOAK_PUBLIC_URL`) rather than a request-time ENV
read, so multi-realm production can point each realm at its own origin.

`account_client_id` (the row's column, seeded from `KEYCLOAK_ACCOUNT_CLIENT_ID`, default `account`)
names the client account deep-links run under, which decides where Keycloak returns a user who
confirmed a new address — see [Where Keycloak sends the user back](#where-keycloak-sends-the-user-back).

### Manage-users capability

`manage_users` records whether this row's service account actually has admin/manage-API access to the
realm. `true` (the default) is an IdP we operate. `false` is **authenticate-only** — a
customer-operated Keycloak, or a service account that can sign users in but lacks the `manage-users`
role. An authenticate-only row still builds a normal `KeycloakService` (so OIDC logout and the
self-service account console keep working) but answers `false` to every `supports_*?` management
predicate, so the admin/self-service management surfaces degrade (actions hidden or no-op) instead of
failing at an Admin API we can't call. A connector with no active row at all resolves to `NullService`,
which behaves the same way.

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
  pre-defined in `realm-import.json` (chosen, not generated). Dev-only — never used in production.

## Related

- [User migration (`rails keycloak:*`)](./keycloak-user-migration.md) — seeding Keycloak from legacy
  Devise/warehouse accounts before a Deployment switches to JWT auth.
