# Developer Setup for Superset
Superset is an external dependency for Open Path, not part of this application's docker compose.
It lives in its own repository, [greenriver/superset-sync](https://github.com/greenriver/superset-sync),
which owns the Superset image, the `docker-compose.yaml`, and the auth config
(`docker/superset/superset_config.py`). Run Superset from a checkout of that repo, not from
`hmis-warehouse`.

## Running Superset locally

Follow the "Development Quick Start" in the superset-sync `README.md`; the short version is:

1. In your superset-sync checkout, seed the local env and compose override:
   ```sh
   cp .env.local.sample .env.local
   cp docker-compose.override.sample.yaml docker-compose.override.yaml
   ```
2. Point `.env.local` at your warehouse: make sure the shared docker network in the override
   matches your warehouse's (`nginx-proxy` or `traefik`), and that `WAREHOUSE_DB_URI` has the
   right warehouse db host/name/creds.
3. Choose an auth method in `.env.local` (see "Logging in to superset" below): either
   `SUPERSET_USE_OAUTH2_PROXY=true` (jwt) or `SUPERSET_USE_OAUTH=true` (Doorkeeper/devise).
4. Load data from the warehouse into dbt/superset, then start it:
   ```sh
   bin/local_development.sh init
   bin/local_development.sh start
   ```

If you are on Apple silicon, the DBT/Superset images are amd64. Installing binfmt lets them run
under emulation:
```bash
docker run --privileged --rm tonistiigi/binfmt --install amd64
```

## Logging in to superset

How Superset resolves a warehouse user depends on the warehouse's `AUTH_METHOD`:

- **`devise`** — Superset uses OAuth2 with the warehouse as the provider (Doorkeeper). Set up a
  Doorkeeper application as described below. `Superset.available?` reports true once a
  `Doorkeeper::Application` is registered for the Superset host.
- **`jwt`** — the warehouse sits behind oauth2-proxy/dex, so there is no Doorkeeper application.
  Superset instead calls `GET /api/superset/user_roles`, authenticating with the user's access
  token that oauth2-proxy forwards as `X-Forwarded-Access-Token` (sent on as
  `Authorization: Bearer <token>`); the warehouse validates the token and returns the user's
  roles. That route is exposed only under `AUTH_METHOD=jwt` and is listed in
  `skip_auth_routes` in `docker/auth/dev.oauth2-proxy-warehouse.cfg` because the backend does its
  own validation. `Superset.available?` reports true once `SUPERSET_ADMIN_PASS` is configured
  (any non-blank value in development; anything other than the insecure `admin` default elsewhere),
  which is the credential `Superset::Api` uses for the warehouse→Superset REST calls.

### Devise / Doorkeeper setup

We use oauth2 with the warehouse as the provider. Which auth path Superset takes is driven by env
flags in `docker/superset/superset_config.py` (in the superset-sync repo): `SUPERSET_USE_OAUTH=true`
selects the Doorkeeper provider, and `SUPERSET_USE_OAUTH2_PROXY=true` takes precedence for jwt.
`AUTH_TYPE` is assigned inside those conditional blocks, so switch methods by setting the flags
rather than editing `AUTH_TYPE` directly.

The proper way to get things set up is to set up a doorkeeper application and update your environment variables in superset

1. log in to the warehouse and visit `admin/users` which should have an Oauth menu option.
2. Click Oauth (takes you to `oauth/applications`)
3. Click "New Application"
4. Set the values
   - Name: Superset
   - Redirect uri: Needs to match what you type in your browser. It's probably one of these:
       * https://hmis-warehouse.dev.test/oauth-authorized/WarehouseSSO
       * https://superset.open-path-warehouse.127.0.0.1.nip.io/oauth-authorized/WarehouseSSO
     If you don't have a proxy with tls set up, now is the time to get that fixed. I'm not sure if it will work without that.
   - Confidential: true
   - Scopes: `user_data`
5. Save the application
6. Set SUPERSET_OAUTH_CLIENT_ID with the UID (either in a docker-compose override or .envrc file)
7. Set SUPERSET_OAUTH_CLIENT_SECRET with the Secret (either in a docker-compose override or .envrc file)
8. Sign up https://ngrok.com/
9. Set NGROK_AUTHTOKEN and NGROK_API_KEY (override or .envrc) with values you
   can get after you have an account. Look on the left navbar for "Your
   Authtoken" and "API". They are two different things.
   **WARNING** Once this is set up, the next time you start superset, the
   **warehouse** will be available on the public internet
10. If all went well, the next time you start superset, you should get a blue
    button to log in with SSO. It will take you to the warehouse to click a
    green "authorize" button and then back to superset logged in.

## References
BinFMT
https://hub.docker.com/r/tonistiigi/binfmt
https://www.reddit.com/r/docker/comments/td0w9t/running_amd64_containers_on_arm64_machine/

Superset on docker
https://github.com/apache/superset/tree/master/docker#readme
https://github.com/apache/superset/blob/master/docker/README.md

https://superset.apache.org/docs/installation/configuring-superset/
