# Keycloak IDP Integration (dev stack)

The opt-in local Docker Compose stack that reproduces the production auth chain.

```text
User → OAuth2-Proxy → Dex (OIDC broker) → Keycloak → Rails (JWT headers)
```

On first boot Keycloak imports the `openpath` realm from `docker/keycloak/realm-import.json`. The
realm has the `warehouse-users` and `hmis-users` groups and three clients:

| Client | Grant | Used by |
| --- | --- | --- |
| `dex-connector` | OIDC authorization code | Dex, to sign users in |
| `rails-service-account` | Client credentials | Rails, to call the Keycloak Admin API |
| `warehouse-account` | OIDC authorization code | The browser, for account self-service links (e.g. change email) |

## Setup

The auth stack lives in `docker/docker-compose.auth.yml` and is **opt-in**. A plain
`docker compose up` does not start it and uses normal Devise login. Run every command below from the
repo root on your host machine unless it says otherwise.

**1. Hosts entries.** Add these to `/etc/hosts` on your host machine if they aren't already there:

```text
127.0.0.1 hmis-warehouse.dev.test hmis.dev.test hmis-backend.dev.test op-keycloak.dev.test dex.dev.test
```

**2. Environment and proxy config.**

1. Generate a cookie secret:

   ```bash
   openssl rand -hex 16
   ```

2. Add these two lines to `.env.development.local`, using the output from the previous command:

   ```bash
   AUTH_METHOD=jwt
   OAUTH2_PROXY_COOKIE_SECRET=<output of openssl>
   ```

   `AUTH_METHOD` defaults to `devise`, which ignores the auth stack.

3. Generate the oauth2-proxy config files into `dev/auth/` (gitignored):

   ```bash
   bash docker/auth/generate-dev-auth.sh
   ```

   The script is safe to re-run. Re-run it whenever you edit a file under `docker/auth/templates/`.

**3. Databases.** Keycloak and Dex each need a Postgres database. If you have never run the app on
this machine, the `db` volume is new and both databases are created automatically; skip this step.
Otherwise, create them once:

```bash
docker compose exec db psql -U postgres -c 'CREATE DATABASE keycloak'
docker compose exec db psql -U postgres -c 'CREATE DATABASE dex'
```

If a database already exists the command prints an error and changes nothing.

**4. MailHog.** Start MailHog before continuing; follow [developer mail](../sample_files/mailhog/developer-mail.md).
The realm sends mail to `mailhog:1025`. Without MailHog, email verification and email changes never
complete.

**5. Bring up the stack** with both compose files:

```bash
export COMPOSE_FILE=docker-compose.yml:docker/docker-compose.auth.yml:docker-compose.override.yml
docker compose build keycloak
docker compose up
```

`export` only applies to the current shell. Run it in every terminal where you use `docker compose`
for this stack, including the commands later in this doc.

Log into the Keycloak admin console at `https://op-keycloak.dev.test` with `admin` /
`AdminPassword1!`. The realm dropdown at the top left should list `openpath`.

**6. Service config.** Create the `Idp::ServiceConfig` row that lets Rails manage users in the local
realm:

```bash
docker compose exec web rails runner 'Idp::ServiceConfig.bootstrap_from_env'
```

Run it in `web` exactly as shown. Only the `web`, `shell` and `console` containers load the Keycloak
credentials from `docker/auth/keycloak-credentials.env`. In any other container the command exits
without creating the row and without printing an error.

Go to `/admin/idp_service_configs` and click the row's **Test** button. A green result means Rails
can reach the Admin API with the service account's secret and roles. If it fails, see
[Troubleshooting](#troubleshooting).

## Applying `realm-import.json` changes

Keycloak imports `docker/keycloak/realm-import.json` only when the `openpath` realm doesn't exist
yet. Once the realm exists, edits to the file have no effect until you apply them to the running
realm yourself.

Apply changes in place; don't delete and recreate the realm. Keycloak holds the only copy of each
user's password, MFA enrollment and email verification.

First, log `kcadm.sh` in to the master realm:

```bash
docker compose exec keycloak /opt/keycloak/bin/kcadm.sh config credentials \
  --server http://localhost:8080 --realm master --user admin --password 'AdminPassword1!'
```

The login is stored inside the Keycloak container. Run it again if the container is recreated, or if a
`kcadm.sh` command returns 401.

Then apply each kind of change as follows:

| What you changed in the file | How to apply it |
| --- | --- |
| Realm settings: SMTP, password policy, brute-force protection, session timeouts, themes, OTP and WebAuthn policy | [Update with `kcadm.sh`](#realm-settings) |
| Clients and groups | [Partial import](#clients-and-groups) |
| Authentication flows and required actions | [Edit in the admin console](#authentication-flows-and-required-actions) |

### Realm settings

```bash
jq 'del(.browserFlow, .resetCredentialsFlow)' docker/keycloak/realm-import.json |
  docker compose exec -T keycloak /opt/keycloak/bin/kcadm.sh update realms/openpath -f -
```

`jq` removes the `browserFlow` and `resetCredentialsFlow` bindings because the update fails completely,
applying nothing, if either names a flow the realm doesn't have yet. The update does not create
flows, clients, users or groups; use the sections below for those. Check the result in the admin
console.

### Clients and groups

In the admin console, go to Realm settings → **Action** (top right) → **Partial import** and choose
`realm-import.json`. Select *clients* and *groups*, and uncheck *users* so existing accounts are left
alone. For resources that already exist, choose *Overwrite* to replace them with the file's version or
*Skip* to keep the live version.

### Authentication flows and required actions

In the admin console, go to Authentication. For each flow you changed, find it by its `alias` under
`authenticationFlows` in `realm-import.json` and recreate its steps in the same order. Required actions
are under `requiredActions` in the file and on the **Required actions** tab in the console.

Then bind each top-level flow: Authentication → the flow's ⋮ menu → **Bind flow**. Bind the flow named
by `browserFlow` as *Browser flow* and the one named by `resetCredentialsFlow` as *Reset credentials
flow*.

### Recreating the realm (last resort)

Deleting `openpath` and restarting Keycloak re-imports the file exactly and leaves the master realm and
admin login in place. It also **permanently deletes every user in the realm**, with their passwords and
MFA. Use it only on a realm with no accounts worth keeping.

```bash
docker compose exec keycloak /opt/keycloak/bin/kcadm.sh delete realms/openpath
docker compose restart keycloak
```

Afterwards, the Warehouse's `user_authentication_sources` rows point at Keycloak user IDs that no
longer exist. Delete them so each user is re-created in Keycloak and re-linked on their next sign-in:

```bash
docker compose exec web rails runner "Idp::UserAuthenticationSource.where(connector_id: 'keycloak').destroy_all"
```

## Troubleshooting

**The service config's Test button fails with 401 or 403.** A 401 means Keycloak rejected the
`rails-service-account` client secret. A 403 means the service account is missing one of its
`realm-management` roles (`manage-users`, `view-users`, `query-users`, `manage-realm`). Either way,
the running realm doesn't match `realm-import.json`: usually the client or its roles were changed
after the first import, or never imported. Export the running realm and compare its clients with the
file:

```bash
docker compose exec -T keycloak /opt/keycloak/bin/kcadm.sh create realms/openpath/partial-export \
  -s exportGroupsAndRoles=true -s exportClients=true -o > tmp/realm-live.json
diff <(jq -S .clients docker/keycloak/realm-import.json) <(jq -S .clients tmp/realm-live.json)
```

The export masks client secrets and has generated IDs, so expect those lines to differ. Look for
missing clients, roles or service-account settings. Fix any differences with
[Partial import](#clients-and-groups). The export needs the `kcadm.sh` login from
[Applying changes](#applying-realm-importjson-changes).

## Reference

### `Idp::ServiceConfig`

`Idp::KeycloakService` calls the Keycloak Admin REST API with the OAuth2 `client_credentials` grant on
the `rails-service-account` client. Rails reads the client ID, secret and URLs from an
`Idp::ServiceConfig` row, one per realm, managed at `/admin/idp_service_configs`. At request time
Rails reads only the row, never ENV. If a connector has no active row, users can still sign in through
it but Rails can't manage their Keycloak accounts.

The dev row, as created by `bootstrap_from_env`:

| Column | Dev value |
| --- | --- |
| `provider` | `keycloak` |
| `connector_id` | `keycloak`. Must match the JWT's `federated_claims.connector_id` claim, which is the ID of the Dex connector that signed the user in |
| `name` | `Keycloak (seeded from ENV)`. Display only |
| `api_url` | `http://op-keycloak.dev.test:8080`. Where Rails calls the Admin API |
| `keycloak_realm` | `openpath` |
| `client_id` | `rails-service-account` |
| `service_token` | `rails-service-account-secret-dev`. Stored encrypted; needs `ENCRYPTION_KEY` |
| `browser_url` | `https://op-keycloak.dev.test`. Used for links opened in the browser. If blank, `api_url` is used |
| `account_client_id` | `warehouse-account`. The client account self-service links run under; its Base URL is where Keycloak sends a user after they confirm a new email. If blank, Keycloak's built-in `account` client is used |
| `manage_users` | `true`. See below |

**Why `api_url` and `browser_url` differ in dev.** Rails reaches Keycloak on the compose network at
`http://op-keycloak.dev.test:8080`. The browser has to go through Traefik at
`https://op-keycloak.dev.test`, because Keycloak's session cookies are `Secure` and belong to that
origin. Rails can't use the Traefik URL: Traefik serves a self-signed `*.dev.test` certificate that
only your host machine trusts (see `bin/developer/certificates.sh`).

**`manage_users`.** `true` means the service account can manage users in the realm; use it for an IdP
we operate. `false` means authenticate-only, e.g. a customer-operated Keycloak. With `false`, sign-in,
logout and the Keycloak account console still work, but the Warehouse hides or skips user-management
actions instead of calling an Admin API it isn't allowed to use.

**Seeding from ENV.** `bootstrap_from_env` builds the row from `KEYCLOAK_API_URL`,
`KEYCLOAK_PUBLIC_URL`, `KEYCLOAK_REALM`, `KEYCLOAK_SERVICE_CLIENT_ID`,
`KEYCLOAK_SERVICE_CLIENT_SECRET`, `KEYCLOAK_ACCOUNT_CLIENT_ID` and `KEYCLOAK_CONNECTOR_ID` (default
`keycloak`). `db:seed` calls it on every deploy. It only creates. If a row for the connector already
exists, including a disabled or soft-deleted one, it does nothing, so edits made in the UI are never
overwritten. It also does nothing unless `AUTH_METHOD=jwt` and the four required `KEYCLOAK_*` values
(URL, realm, client ID, secret) are set. After the row exists, change credentials in the UI; ENV is
not read again.

### Account email self-service

When `AUTH_METHOD=jwt`, users change their own email in Keycloak, not in the Warehouse. The
Warehouse's Email tab is read-only and sends the browser to Keycloak's `UPDATE_EMAIL` action. Keycloak
collects the new address, emails a confirmation link to it, and applies the change only after the
link is clicked.

The Warehouse copies the new address into `users.email` the next time it reads the account from the
Admin API, and only if Keycloak reports it verified. It reads the account on every render of the Email
tab and in a background sync job on authenticated requests, so the change is picked up even if the
user never returns to the tab. An admin changing a user's email is a separate path: the address is
written to `users.email` directly and sent to Keycloak with `emailVerified: false`.

The code does not check the realm for the settings below; it assumes they're set. In dev,
`realm-import.json` sets all three. Any other realm that uses JWT auth needs them configured:

| Requirement | Where | If missing |
| --- | --- | --- |
| **Update Email** required action **enabled** | Authentication → Required actions | Keycloak rejects the link, and the user has no way to change their address |
| Email verification **in effect for this action**: either one of the two settings | Realm settings → Login → **Verify email** (whole realm), or Authentication → Required actions → Update Email → **Force Email Verification** (this action only; off by default) | Keycloak applies the new address immediately without verifying it. The Warehouse refuses to copy it, so Keycloak and `users.email` disagree until the realm is fixed |
| Working **SMTP** on the realm | Realm settings → Email | The confirmation email never sends, so the change can't complete |

**Force Email Verification** is the narrower choice: it leaves password resets and admin-created
accounts on the realm default.

#### Behaviour to know about

- **Email is the login name.** The realm has **Email as username** turned on
  (`registrationEmailAsUsername: true`), so Keycloak keeps `username` equal to `email`. This matches the
  legacy Devise setup, where the email is the login.
- **Starting a change can ask for a password.** The Update Email required action has a **Maximum Age of
  Authentication** (`max_auth_age`, default 300 seconds). If the user signed in to Keycloak longer ago
  than that, Keycloak asks them to sign in again before showing the form.

### Profile sync for IdPs with no Admin API

Customer-operated IdPs connect as additional Dex connectors
([§5.2.3](../architecture/05-building-blocks/05-2-3-authentication.md)) and have no Admin API we can
call. For users from those IdPs, the Warehouse updates the profile from the JWT's claims instead. A
missing `email_verified` claim counts as verified, because external IdPs often leave it out; only an
explicit `email_verified: false` blocks the email update.

## Notes

- **Warehouse-only work.** `hmis.dev.test` works only if the HMIS frontend's Vite dev server is
  running on your host at port 5173. The `oauth2-proxy-hmis` container still starts, because `web`
  depends on it. If you're only working on the Warehouse, ignore it and use
  `https://hmis-warehouse.dev.test`.
- **Linux.** The proxies use `extra_hosts: …:host-gateway`, which needs Docker Engine 20.10 or later.
  Docker Desktop supports it out of the box.
- **Credentials.** `docker/auth/keycloak-credentials.env` is committed because its values are fixed in
  `realm-import.json`, not generated. They are for dev only and never used in production.

## Related

- [User migration (`rails keycloak:*`)](./keycloak-user-migration.md): seeding Keycloak from legacy
  Devise/warehouse accounts before a Deployment switches to JWT auth.
