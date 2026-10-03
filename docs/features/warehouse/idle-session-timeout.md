# Idle Session Timeout

## Overview
An idle warehouse session ends after about 30 minutes without activity. The inactivity modal warns 5 minutes before the end and offers "I'm still here". When the countdown reaches 0, it clears the page so nothing stays on screen once the session is gone.

The server decides when the session ends. The modal only tries to predict that moment. There are two auth arms, chosen by `AuthMethod`, and they track the session in different ways:

| Arm | What ends the session | What drives the countdown |
| --- | --- | --- |
| Devise | `Devise.timeout_in` (30m) | Time since the last request, from `X-app-user-id` |
| JWT | Keycloak idle timeout (30m), through Dex and oauth2-proxy | Forwarded token expiry, from the `app-session-remaining` `Server-Timing` entry |

On the JWT arm an idle session ends 25–30 minutes after the last request, and the warning appears 20–25 minutes after it. The window is fuzzy because oauth2-proxy refreshes the token only once the session cookie is at least 5 minutes old (see [What counts as activity](#what-counts-as-activity)).

## Devise arm
- `DeviseCurrentUser#inactive_session_countdown_values` seeds the modal with `session_lifetime_secs_value` (`Devise.timeout_in`).
- Every page load and jQuery AJAX response stamps `session_last_request_ts` in localStorage. The countdown is that stamp plus the lifetime, so all tabs share it.
- `/messages/poll` and requests with `skip_trackable=true` are not stamped, because they don't extend a Devise session.
- "I'm still here" POSTs to `Users::SessionsController#keepalive`, which returns `head :ok`. The request alone resets Devise's timer.

## JWT arm
The session is held by three layers. Each refresh restarts both the token's expiry and Keycloak's idle clock, so the token's expiry matches the real logout.

1. A request reaches oauth2-proxy with its session cookie.
2. If the cookie is older than `cookie_refresh` (5m), oauth2-proxy refreshes through Dex.
3. Dex does a `refresh_token` grant against Keycloak, which resets Keycloak's idle timer, and issues a new 30m token.
4. oauth2-proxy forwards that token to Rails on the same request, as `X-Forwarded-Access-Token`.

In the browser:

- `Idp::JwtCurrentUser#inactive_session_countdown_values` seeds the modal with `session_remaining_secs_value`, the token's remaining seconds.
- `ApplicationController#set_app_user_header` sends the same value on every response as a `Server-Timing` entry, `app-session-remaining;desc="<secs>"`. Server-Timing is used because the browser's Resource Timing API exposes it for every request type (fetch, XHR, iframes). It is only exposed on HTTPS pages, which every deployment is.
- The modal turns remaining seconds into a browser-clock expiry and stores it in the `session_expires_at` localStorage key. It does this on page load, on keepalive, and for every response a `PerformanceObserver` sees carrying the entry. The observer is buffered, so it also picks up requests that finished before the modal's controller connected. All tabs read the same key, so they count down together. Browsers without `serverTiming` (e.g. Safari before 16.4) update the countdown only on page load and keepalive.
- The expiry is measured from when the request started, not when the response arrived. The server reads the token early in the request, so a slow report page would otherwise push the expiry late by the action's run time.
- The newest request wins, not the largest expiry. The key stores each value with its request's start time, and a write from an older request is dropped, such as a slow response or a background tab whose observer ran late. Every tab shares one oauth2-proxy cookie, so the newest request carries the current token. A failed refresh must be able to pull the expiry earlier.
- The server sends seconds rather than a timestamp, so clock skew between browser and server doesn't matter.
- "I'm still here" POSTs to `Idp::SessionsController#keepalive`, which returns `remaining_seconds`. If the result is still inside the 5-minute warning window, the refresh failed (usually because the Keycloak session is gone). A reload wouldn't help, because oauth2-proxy keeps serving the old token until it expires. So the modal says the session can't be extended and swaps "I'm still here" for a Close button. Closing it keeps the modal shut for the rest of the countdown so the user can save their work. At 0 the page clears as usual.

## Settings that must stay consistent
Values are from the dev stack. Check each Deployment's own config before relying on them.

| Layer | Setting | Dev value | File |
| --- | --- | --- | --- |
| oauth2-proxy | `cookie_refresh` | 5m | `docker/auth/dev.oauth2-proxy-*.cfg` |
| oauth2-proxy | `cookie_expire` | 12h | same |
| Dex | `expiry.idTokens` (also the access token) | 30m | `docker/auth/dev.dex.yaml.template` |
| Dex | `expiry.refreshTokens.reuseInterval` | 30s | same |
| Dex | `expiry.refreshTokens.absoluteLifetime` | 3960h | same |
| Keycloak | `ssoSessionIdleTimeout` / `clientSessionIdleTimeout` | 1800s | `docker/keycloak/realm-import.json` |
| Keycloak | `ssoSessionMaxLifespan` | 28800s (8h) | same |
| Modal | `WARNING_WHEN_REMAINING_SECS` | 5m | `inactive_session_modal_controller.js` |

Constraints:

- `idTokens` ≤ the Keycloak idle timeout. Otherwise the countdown outlives the real session.
- `idTokens` > `cookie_refresh`. Otherwise a token can expire before oauth2-proxy will refresh it.
- Warning window ≤ `idTokens` − `cookie_refresh` (5m ≤ 30m − 5m). Otherwise "I'm still here" can arrive before the cookie is old enough to refresh, and the keepalive fails.
- Dex `absoluteLifetime` > `cookie_expire`. Otherwise the refresh token dies before the cookie does.

## What counts as activity
On the JWT arm, activity means any request that carries the oauth2-proxy cookie once the cookie is at least 5 minutes old. That includes XHR, `api_routes` and `skip_auth_routes`: oauth2-proxy loads and refreshes the session before it checks whether a route skips auth. Navigating within 5 minutes of the last refresh extends nothing.

Background pollers therefore count as activity. A page left open with one of these keeps the session alive up to the 8h `ssoSessionMaxLifespan`:

| Poller | Interval | File |
| --- | --- | --- |
| `poll_replace_controller` | 30s (default) | `app/javascript/controllers/poll_replace_controller.js` |
| `App.Rollups.Checker` | 30s | `app/assets/javascripts/rollups/checker.js.coffee` |
| `documentExport.js` | 3s | `app/assets/javascripts/documentExport.js` |
| `App.Clients.EtoApiRefresher` | 5s | `app/assets/javascripts/clients/eto_api_refresher.js.coffee` |

`/messages/poll` is fetched once per page load, not on a timer.

## Known limits
- Poller pages, above.
- Within Dex's 30s `reuseInterval`, a refresh reuses the last result and doesn't contact Keycloak.
- `ssoSessionMaxLifespan` (8h) ends the session however active the user is, which is earlier than `cookie_expire` (12h).
- The HMIS frontend keeps its own countdown in the `hmis-frontend` repo. Its idle behaviour, and whether it shares the warehouse's Keycloak session, are not documented here yet.

## Key Files
- `app/views/application/_inactive_session_modal.haml`
- `app/javascript/controllers/inactive_session_modal_controller.js`
- `app/controllers/application_controller.rb` (`set_app_user_header`)
- `app/controllers/concerns/devise_current_user.rb`
- `app/controllers/concerns/idp/jwt_current_user.rb`
- `app/controllers/idp/sessions_controller.rb` (`keepalive`)
- `app/controllers/users/sessions_controller.rb` (`keepalive`)
- `spec/requests/idp/warehouse_jwt_wiring_spec.rb`
- `spec/system/rails/inactive_session_modal_spec.rb` (runs only with `RUN_RAILS_SYSTEM_TESTS` and `AUTH_METHOD=jwt`)

## Related
- [Keycloak IDP Integration (dev stack)](../../developer/keycloak-idp.md): setup, and how to change realm session timeouts.
