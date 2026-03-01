# Keycloak IDP Integration

Keycloak serves as the Identity Provider in the Open Path auth stack.

## Architecture

```
User → OAuth2-Proxy → Dex (OIDC broker) → Keycloak → Rails (JWT headers)
```

- **Keycloak** handles user authentication and stores credentials
- **Dex** brokers OIDC between OAuth2-Proxy and Keycloak
- **OAuth2-Proxy** injects JWT headers into requests to Rails
- **Rails** validates JWTs — unchanged from the Zitadel setup

### Keycloak Realm and Clients

A single realm (`openpath`) contains two clients:

| Client | Purpose |
|--------|---------|
| `dex-connector` | OIDC authorization code flow for Dex integration |
| `rails-service-account` | Client credentials flow for the Rails admin API |

Groups (`warehouse-users`, `hmis-users`) are used for per-app access control.

## Local Dev Setup

### Add Keycloak to Hosts
```
echo '127.0.0.1 op-keycloak.dev.test' | sudo tee -a /etc/hosts
```

### Create the Keycloak Database

For fresh installations warehouse, the Keycloak database is created automatically by
`docker/pg17/initdb.d/20-create-keycloak-db.sh` when the postgres data volume is first
initialized. If you are working with an **existing postgres volume**, create it manually:

```bash
docker compose exec db psql -U postgres -c 'CREATE DATABASE keycloak'
```

### Build and Start Keycloak

```bash
docker compose build keycloak
docker compose up -d keycloak
```

### Admin Console

Visit `https://op-keycloak.dev.test` and log in with:

- **Username:** `admin`
- **Password:** `AdminPassword1!`

The `openpath` realm should be visible in the realm selector.

### Full Stack

```bash
docker compose up
```

The `dex` service depends on `keycloak` being healthy before starting, which ensures
the OIDC issuer is available when Dex loads its connector configuration.

## Environment Variables

In development IdP configuration is loaded from `docker/auth/keycloak-credentials.env`. In production, or for more flexible configuration you can use `Idp::ServiceConfig`.

| Variable | Description |
|----------|-------------|
| `KEYCLOAK_API_URL` | Base URL for Keycloak (e.g., `http://op-keycloak.dev.test:8080`) |
| `KEYCLOAK_REALM` | Realm name (default: `openpath`) |
| `KEYCLOAK_IDP_CLIENT_ID` | Client ID for Dex connector (`dex-connector`) |
| `KEYCLOAK_IDP_CLIENT_SECRET` | Client secret for Dex connector |
| `KEYCLOAK_SERVICE_CLIENT_ID` | Service account client ID for Rails admin API |
| `KEYCLOAK_SERVICE_CLIENT_SECRET` | Service account client secret |

## User Migration

Users are migrated from Devise to Keycloak using the `keycloak:` rake tasks.
These use the Keycloak `partialImport` API, which preserves bcrypt password hashes
and TOTP secrets — users can log in immediately without resetting passwords.

Only confirmed, active users are migrated (`confirmed_at IS NOT NULL AND active = true`).

### Test Connection

```bash
dcr shell bundle exec rails keycloak:test_connection
```

### Migrate All Users

Exports and imports directly in one step:

```bash
# All users, in batches of 50:
dcr shell bundle exec rails keycloak:migrate_users

# Re-migrate all users, overwriting existing records:
dcr shell bundle exec rails keycloak:migrate_users[,,OVERWRITE]
```

The default policy is `SKIP` — existing users are left untouched. Use `OVERWRITE` to push
updated credentials (e.g., after a password change in Devise).

### Import Single User (testing)

```bash
dcr shell bundle exec rails keycloak:import_single_user[your@email.com]
```

Then verify the user appears in the Keycloak admin console under Users.

## Configuring Production

Create an `Idp::ServiceConfig` record with `connector_id: 'keycloak'` and the
appropriate config hash:

```ruby
Idp::ServiceConfig.create!(
  connector_id: 'keycloak',
  config: {
    api_url: 'https://your-keycloak.example.com',
    realm: 'openpath',
    client_id: 'rails-service-account',
    client_secret: 'KEYCLOAK_SERVICE_CLIENT_SECRET',
  }
)
```

## Group-Based Access Control

Users can be assigned to groups in Keycloak to control which application they
can access:

- `warehouse-users` — access to the Warehouse application
- `hmis-users` — access to the HMIS application

Group membership can be managed via the Keycloak admin console or API.

## Credentials File

`docker/auth/keycloak-credentials.env` is committed to the repository because the
credentials are pre-defined in `realm-import.json` — they are chosen values, not
auto-generated. These are dev-only credentials and are never used in production.
