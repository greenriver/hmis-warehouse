# Developer Setup for Superset
Superset has become an external dependency for Open Path rather than integrated in the application's docker compose.  The following instructions may help get it running, but are no longer fully accurate, but left here temporarily until updated documentation can be developed.

If you are running on Apple M1 architecture, this may help get superset up and running. Run the following in your `hmis-warehouse` directory.  This will install an abstraction layer that will allow the amd64 version of superset to run on arm64.
```bash
docker run --privileged --rm tonistiigi/binfmt --install amd64
```
In one terminal start up the Superset container.  It is set to start in the background by default, so you may need to `docker compose down` first
```sh
docker compose up superset
```
If all goes well, it'll run through the config and you'll end up with a new
`superset` db on your postgres container.  If it looks like there were any
errors, open a second terminal and run the following:
```sh
docker compose run superset_init_2
```
There's an `init.sh` script in `superset/op/` that only runs if
`superset/op/.did.db.init` doesn't exist. Removing that file will let the
script run again.

At this point the usual `docker compose up -d` should bring up a functional superset installation at http://superset.hmis-warehouse.dev.test.

## Logging in to superset

How Superset resolves a warehouse user depends on the warehouse's `AUTH_METHOD`:

- **`devise`** — Superset uses OAuth2 with the warehouse as the provider (Doorkeeper). Set up a
  Doorkeeper application as described below. `Superset.available?` reports true once a
  `Doorkeeper::Application` is registered for the Superset host.
- **`jwt`** — the warehouse sits behind oauth2-proxy/dex, so there is no Doorkeeper application.
  Superset instead calls `GET /api/superset/user_roles` with the user's bearer JWT
  (`Authorization: Bearer <token>`); the warehouse validates the token and returns the user's
  roles. That route is exposed only under `AUTH_METHOD=jwt` and is listed in
  `skip_auth_routes` in `docker/auth/dev.oauth2-proxy-warehouse.cfg` because the backend does its
  own validation. `Superset.available?` reports true once `SUPERSET_ADMIN_PASS` is configured
  (any non-blank value in development; anything other than the insecure `admin` default elsewhere),
  which is the credential `Superset::Api` uses for the warehouse→Superset REST calls.

### Devise / Doorkeeper setup

We use oauth2 with the warehouse as the provider. In a pinch, you can just find `AUTH_TYPE` in
`docker/superset/op/superset_config.py` and comment that line out.

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
