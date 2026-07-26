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

## Realm prerequisites for account email self-service

Under the JWT arm a user changes their own email **inside Keycloak**, not in the Warehouse. The
Email tab is read-only: it shows the current address and deep-links into Keycloak's `UPDATE_EMAIL`
application-initiated action (`Idp::KeycloakService#account_action_url`), and the Warehouse adopts
the new address only when the browser returns with `kc_action_status=success`
(`Idp::AccountEmailsController#edit` → `Idp::Support#idp_reconcile_email!`), and only when the Admin
API reports the mailbox as verified — `#idp_reconcile_email!` checks `emailVerified` on the
representation it already fetched, so no self-service path can put an unproven address in
`users.email`. (The **admin** path is separate and unchanged: `Admin::Idp::UsersController` still
writes an admin-supplied address locally and pushes it with `emailVerified: false`, so an admin can
still put an unverified address in `users.email`.)

`Idp::KeycloakService#supports_email_self_service?` **asserts** the realm is set up for this rather
than probing it, so the four items below are operator setup for every realm running the JWT arm.
Miss one and the tab still renders and still offers the link, but the flow misbehaves in the ways
noted.

| Requirement | Where | If missing |
| --- | --- | --- |
| **Keycloak ≥ 26.4** | server version (`docker/keycloak/Dockerfile` pins 26.5.4 for dev) | Update Email is a preview feature needing `--features=update-email`; on older servers the action does not exist and Keycloak returns the user with an error status |
| **Update Email** required action **enabled** | Authentication → Required actions | Keycloak rejects the `kc_action=UPDATE_EMAIL` link; the user gets no way to change their address |
| Realm **Verify Email** on | Realm settings → Login → Verify email | Keycloak applies the new address **immediately, unverified**. The Warehouse then refuses to adopt it and warns the user, so Keycloak and `users.email` diverge until the realm is fixed — the change appears to fail rather than silently landing unverified |
| Working **SMTP** on the realm | Realm settings → Email | The verification mail never sends, so a change can never complete |

Two consequences worth knowing:

- **Email is the login name.** The realm runs **Email as username**
  (`registrationEmailAsUsername: true`), so Keycloak keeps `username` tracking `email` — matching the
  legacy Devise model where email *is* the login. A completed Update Email therefore changes the
  user's username too, which is why reconciliation reads the address back from the Admin API
  (`#get_user`) rather than from the JWT: oauth2-proxy still holds the pre-change token when the
  browser returns, so its `email` claim is the old address. `realm-import.json` sets the flag for
  fresh dev realms — enable it on any existing/production realm before relying on email edits.
  Without it, `username` is read-only and the **admin** path
  (`Idp::KeycloakService#update_user`, still used by `Idp::AccountsController`-adjacent admin edits)
  is rejected with `error-user-attribute-read-only`.
- **Out-of-band edits do not reach the Warehouse.** An email changed directly in the Keycloak admin
  console never produces a return trip, so `users.email` stays stale until the next user-initiated
  change. Reconciliation is deliberately scoped to the return trip.

> The dev `realm-import.json` does **not** yet enable the Update Email required action, realm
> `verifyEmail`, or an `smtpServer`, and the auth compose stack has no mail sink — so the flow is
> not exercisable end-to-end in the local dev stack yet. Configure those by hand in the admin
> console, or see bead `app-0kk` for wiring them into the dev stack. Note that supplying a
> top-level `requiredActions` array in a realm import **replaces** Keycloak's seeded defaults rather
> than merging with them, so that array must re-list `UPDATE_PASSWORD`, `CONFIGURE_TOTP` and
> `VERIFY_EMAIL` or the existing password/2FA deep-links regress.

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
