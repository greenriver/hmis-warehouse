# Zitadel IDP

The warehouse previously used the [devise](https://github.com/heartcombo/devise) gem for authentication. The application has fully migrated to an OAuth2 authentication system using [OAuth2-proxy](https://oauth2-proxy.github.io/oauth2-proxy/) in front of [Dex](https://dexidp.io) which proxies to any IDP. For installations where the community does not have an existing IDP, we use a stand-alone installation of [Zitadel](https://zitadel.com) to provide user management.

This document covers:
- How JWT-based authentication works in the application
- How to configure Zitadel, Dex, and OAuth2-proxy for development and production
- How to migrate user data from the old Devise system
- How to test with JWT authentication in RSpec

This document does not cover installation of Zitadel itself.

## Local Development Setup

Zitadel runs automatically as part of the docker-compose stack. No special profile or manual configuration is needed.

### Prerequisites

Add `op-zitadel.dev.test` to your `/etc/hosts` file:

```
127.0.0.1 op-zitadel.dev.test
```

### Starting the Stack

```bash
docker compose up
```

This automatically:
1. Creates a `zitadel` database in PostgreSQL
2. Starts Zitadel at http://op-zitadel.dev.test:8080
3. Starts the Zitadel Login UI (accessible via port 3001)
4. Runs the setup script to configure the Dex OIDC application
5. Generates credentials in `docker/auth/zitadel-credentials.env`
6. Starts Dex with the Zitadel connector configured

On first run, the `zitadel-setup` container will create the necessary project and application in Zitadel. On subsequent runs, it detects the existing configuration and exits immediately.

### Zitadel Console Access

- URL: http://op-zitadel.dev.test:8080/ui/console
- Admin Login: `admin@openpath.op-zitadel.dev.test`
- Password: `AdminPassword1!`

### Manual Setup (if needed)

If you need to reconfigure Zitadel:

```bash
# Delete existing credentials
rm docker/auth/zitadel-credentials.env

# Restart to trigger setup
docker compose restart zitadel-setup dex
```

Or run the setup script manually:

```bash
./docker/zitadel/setup.sh
```

---

# Authentication Architecture

## JWT Token Flow

The authentication system uses JWT (JSON Web Token) tokens to authenticate users:

1. **User Login**: User authenticates via OAuth2-proxy → Dex → Zitadel
2. **Token Issuance**: Zitadel issues an ID token to Dex, which issues its own JWT to OAuth2-proxy
3. **Header Injection**: OAuth2-proxy validates the JWT and injects it into the `X-Forwarded-Access-Token` header on every request to the Rails application
4. **Rails Validation**: The Rails application reads the JWT from `HTTP_X_FORWARDED_ACCESS_TOKEN` header
5. **User Identification**: `JwtHelper` validates the JWT signature using the JWKS endpoint and verifies claims (issuer, audience, expiration)
6. **Session Setup**: `CurrentUser` concern extracts user information and sets `current_user` for the request

## Key Components

### JwtHelper
- Validates JWT tokens by fetching public keys from Dex's JWKS endpoint
- Verifies JWT claims: issuer (`ISS_URL`), audience (`IDP_AUD`), expiration
- Extracts user information: email, connector ID, connector user ID
- Class methods: `authenticated?(token)` and `user_id_from_token(token)`

### CurrentUser Concern
- Included in both `ApplicationController` (Warehouse) and `Hmis::BaseController` (HMIS)
- Provides `current_user` (Warehouse) or `current_hmis_user` (HMIS)
- Provides `authenticate_user!` or `authenticate_hmis_user!`
- Redirects unauthenticated users to OAuth2-proxy sign-in endpoint

### UserAuthenticationSource
- Links users to IDP connectors using `connector_id` and `connector_user_id`
- Allows users to have multiple authentication sources (e.g., GitHub, Zitadel)
- Created automatically on first login or during user migration

### User Lookup Process
1. Look up by `connector_id` + `connector_user_id` in `UserAuthenticationSource`
2. Fallback to email address lookup
3. Automatically create `UserAuthenticationSource` if missing

## HTTP Headers

OAuth2-proxy injects these headers into every request:

- `HTTP_X_FORWARDED_ACCESS_TOKEN`: JWT access token (primary authentication mechanism)
- `X-Forwarded-User`: User's email address
- `X-Forwarded-Groups`: User's groups (comma-separated)

The Rails application primarily uses `HTTP_X_FORWARDED_ACCESS_TOKEN` for authentication.

## Warehouse vs HMIS Authentication

Both applications use the same JWT-based authentication but with separate controllers and user types:

**Warehouse Application:**
- Controller: `Users::SessionsController`
- User model: `User`
- Authentication method: `authenticate_user!`
- Current user method: `current_user`
- Logout client ID: `ZITADEL_IDP_WAREHOUSE_CLIENT_ID`

**HMIS Application:**
- Controller: `Hmis::SessionsController`
- User model: `Hmis::User` (STI - same table as `User`)
- Authentication method: `authenticate_hmis_user!`
- Current user method: `current_hmis_user`
- Logout client ID: `ZITADEL_IDP_HMIS_CLIENT_ID`

# Architecture Overview

This setup uses **a single Dex connector** to Zitadel with **three OAuth2-Proxy instances**:

## OAuth2-Proxy Instances

1. **oauth2-proxy-warehouse** (`hmis-warehouse.dev.test:4180`)
   - Proxies requests to the Warehouse Rails application
   - Cookie name: `_oauth2_proxy_warehouse`
   - Client ID: Uses `ZITADEL_IDP_WAREHOUSE_CLIENT_ID`

2. **oauth2-proxy-hmis** (`hmis.dev.test:4181`)
   - Proxies requests to the HMIS React frontend (Vite dev server)
   - Cookie name: `_oauth2_proxy_hmis` (shared with hmis-backend)
   - Client ID: Uses `ZITADEL_IDP_HMIS_CLIENT_ID`

3. **oauth2-proxy-hmis-backend** (`hmis-backend.dev.test:4182`)
   - Proxies API requests from HMIS frontend to Rails backend
   - Cookie name: `_oauth2_proxy_hmis` (shared with frontend)
   - Client ID: Uses `ZITADEL_IDP_HMIS_CLIENT_ID`

## Cookie and Session Architecture

- **Warehouse** uses a separate cookie (`_oauth2_proxy_warehouse`) so logout from warehouse doesn't affect HMIS
- **HMIS frontend and backend** share the same cookie (`_oauth2_proxy_hmis`) for seamless API access
- All cookies are set for domain `.dev.test` to enable SSO behavior across subdomains
- Access control is managed via **Zitadel project grants** - you can restrict which users can access which projects
- You can optionally create separate Zitadel projects for Warehouse and HMIS to manage users independently

## Dex Configuration

Dex acts as an OIDC broker between OAuth2-proxy and Zitadel:

- **Static Clients**: Two clients configured in Dex:
  - `hmis-warehouse`: Used by oauth2-proxy-warehouse
  - `hmis-frontend`: Used by oauth2-proxy-hmis and oauth2-proxy-hmis-backend
- **JWT Expiration**: ID tokens expire after 1 hour
- **Connector Selection**: Use `connector_id` query parameter to specify which IDP connector to use (e.g., `zitadel`, `github_idp`, `local`)
- **JWKS Endpoint**: Dex exposes public keys at `/dex/keys` for JWT signature validation

# Session Management & Logout

## Session Persistence

- Sessions are managed by OAuth2-proxy cookies, not Rails sessions
- The Rails application is stateless - it validates the JWT on every request
- JWT tokens expire after 1 hour
- OAuth2-proxy may automatically refresh tokens if a refresh token is available
- No separate Rails session timeout - authentication is purely JWT-based

## Logout Flow

### Warehouse Logout

When a user logs out of the Warehouse application:

1. `DELETE /users/sign_out` is called
2. Rails generates a logout URL using `idp_logout_url` helper with:
   - `final_redirect_uri`: Where to redirect after logout (typically root URL)
   - `client_id`: `ZITADEL_IDP_WAREHOUSE_CLIENT_ID`
3. User is redirected to Zitadel's OIDC RP-Initiated Logout endpoint:
   ```
   {zitadel_url}/oidc/v1/end_session?post_logout_redirect_uri={oauth2_proxy_signout}&client_id={client_id}
   ```
4. Zitadel clears its session and redirects to OAuth2-proxy's sign-out endpoint:
   ```
   /oauth2/sign_out?rd={final_redirect_uri}
   ```
5. OAuth2-proxy clears its cookie and redirects to the final destination

### HMIS Logout

HMIS uses a slightly different flow because the frontend is a React application:

1. `DELETE /hmis/logout` is called (returns JSON, not a redirect)
2. Response includes the logout URL
3. Frontend JavaScript redirects the browser to the logout URL
4. Same flow as Warehouse from step 3 onwards

## Logout URL Helper

The `idp_logout_url` helper generates the appropriate logout URL for the configured IDP:

- **Zitadel**: Generates OIDC RP-Initiated Logout URL (clears Zitadel session)
- **Other IDPs**: Falls back to OAuth2-proxy sign-out URL (clears OAuth2-proxy session only)

## Session Timeout & Refresh Tokens

### Overview

Sessions are designed to balance security with user experience:
- **Session Duration**: 30 minutes
- **Refresh Window**: 10 minutes before expiry (active users auto-extend)
- **Warning Modal**: Appears 5 minutes before expiry
- **Absolute Maximum**: 12 hours (hard limit on session lifetime)

### How It Works

The refresh token mechanism ensures that users who are actively using the application never see a session expiry modal. Sessions are automatically extended for active users.

#### Token Flow

1. **User Login**: Zitadel issues a refresh token to Dex
2. **Dex to oauth2-proxy**: Dex issues a refresh token to oauth2-proxy
3. **Active Browsing**: When a user makes a request within the 10-minute refresh window, oauth2-proxy automatically refreshes the JWT token
4. **Session Extended**: New JWT with new expiration time is issued (another 30 minutes)
5. **Result**: Active users never reach the warning modal

#### Warning Modal Behavior

If a user is inactive or approaching the 10-minute refresh window:

1. **At 5 minutes remaining**: Modal appears asking "Are you still here?" / "Is your session expiring soon?"
2. **User clicks button**: Application calls `/session_keepalive` (GET request)
3. **Token is refreshed**: If within refresh window, oauth2-proxy refreshes the token
4. **New expiration received**: Frontend updates countdown, modal hides
5. **Session extended**: User gets another 30 minutes

If user dismisses the modal or doesn't click the button:
- Modal remains visible with countdown timer
- At 0 seconds: Session expires, user is logged out

### Configuration

The timeout values are configured in multiple locations:

#### Dex Configuration (docker/auth/dev.dex.yaml)

```yaml
expiry:
  idTokens: "30m"           # Session duration
  refreshTokens:
    validIfNotUsedFor: "12h" # Maximum session lifetime
```

#### OAuth2-Proxy Configuration (all 4 CFG files)

```
cookie_refresh="10m"        # Refresh token within this window
cookie_expire="12h"         # Hard cookie expiration limit
```

Files:
- `docker/auth/dev.oauth2-proxy.cfg`
- `docker/auth/dev.oauth2-proxy-warehouse.cfg`
- `docker/auth/dev.oauth2-proxy-hmis.cfg`
- `docker/auth/dev.oauth2-proxy-hmis-backend.cfg`

#### Warehouse JavaScript Controller

File: `app/javascript/controllers/inactive_session_modal_controller.js`

```javascript
const WARNING_WHEN_REMAINING_SECS = 5 * 60;     // Show modal at 5 minutes
const REFRESH_WHEN_REMAINING_SECS = 10 * 60;    // Refresh available within 10 minutes
const POLL_INTERVAL_SECS = 30;                  // Check every 30 seconds
```

#### HMIS Frontend React

File: `src/routes/AppRoutes.tsx`

```typescript
const promptToExtendBefore = 60 * 5; // Show modal at 5 minutes remaining
```

### Implementation Details

#### Warehouse (Stimulus Controller)

- Polls session expiration every 30 seconds
- Uses Stimulus `values` pattern to receive expiration time from server
- Modal countdown updates every 1 second when visible
- Clicking "I'm still here" calls `GET /session_keepalive`
- Dismissing modal (ESC key or backdrop click) resets state and resumes polling
- Development logging shows time remaining every 30 seconds (see console logs)

#### HMIS Frontend (React)

- Session duration comes from `HmisUser.sessionDuration`
- Tracks session via `useSessionTracking` hook (monitors `X-HMIS-Session-UID` header)
- Shows modal via `ConfirmationDialog` component
- Clicking "Keep me signed-in" calls `GET /hmis/session_keepalive`
- Session expires automatically if user is inactive
- Development logging shows time remaining every 30 seconds (only in dev mode)

### Server Endpoints

Both applications provide session keepalive endpoints:

#### Warehouse: `GET /session_keepalive`

Response:
```json
{
  "success": true,
  "expiration_time": 1704067200,
  "remaining_seconds": 1800
}
```

#### HMIS: `GET /hmis/session_keepalive`

Same response format. Both endpoints:
- Read the JWT from `HTTP_X_FORWARDED_ACCESS_TOKEN` header
- Validate the JWT signature
- Return the current (or refreshed) expiration time
- OAuth2-proxy may refresh the token if within the 10-minute window

### Testing the Session Behavior

To test the modal and refresh token behavior:

1. Log in to the application
2. Wait 25 minutes (token will be within 5-minute warning window)
3. Modal should appear with countdown
4. Click "Keep me signed-in" or "I'm still here"
5. Session should extend by another 30 minutes
6. Modal should hide

For faster testing, you can temporarily modify:
- `WARNING_WHEN_REMAINING_SECS` in warehouse controller (e.g., 2 minutes)
- `promptToExtendBefore` in HMIS AppRoutes (e.g., 2 minutes)
- `idTokens: "5m"` in Dex config for shorter sessions

Remember to revert these changes before committing.

### Production Configuration

For production deployments, review and adjust:
- Session duration: typically 30-60 minutes
- Refresh window: 20% of session duration
- Warning time: 5 minutes (user perspective matters)
- Maximum lifetime: 12-24 hours depending on security requirements

Ensure these values are synchronized across:
1. Dex configuration
2. All OAuth2-proxy instances
3. JavaScript/React constants
4. Any reverse proxy or load balancer configurations

# Environment Configuration Reference

The application requires these environment variables for JWT authentication:

## JWT Validation

```bash
# JWT issuer - must match Dex issuer
ISS_URL=https://dex.dev.test/dex

# JWKS endpoint for fetching public keys
JWKS_URL=http://dex:4443/dex/keys

# JWT signature algorithm
JWT_ALGORITHM=RS256

# Valid JWT audiences (comma-separated)
IDP_AUD=hmis-warehouse,hmis-frontend,superset
```

## Zitadel API Configuration

```bash
# Zitadel API base URL
ZITADEL_API_URL=http://op-zitadel.dev.test:8080

# Service user token for user management API
ZITADEL_SERVICE_USER_TOKEN=<service-user-token>

# Zitadel organization ID
ZITADEL_ORG_ID=<organization-id>
```

## Dex Connector Configuration

```bash
# Dex application client ID (created in Zitadel)
ZITADEL_IDP_CLIENT_ID=<dex-client-id>

# Dex application client secret (created in Zitadel)
ZITADEL_IDP_CLIENT_SECRET=<dex-client-secret>
```

## Logout Redirect Configuration

```bash
# Client IDs used for logout redirect URL generation
# These are typically the same as ZITADEL_IDP_CLIENT_ID
# but kept separate for flexibility

# Warehouse logout client ID
ZITADEL_IDP_WAREHOUSE_CLIENT_ID=<dex-client-id>

# HMIS logout client ID
ZITADEL_IDP_HMIS_CLIENT_ID=<dex-client-id>
```

## Optional: Project-based Access Control

```bash
# Zitadel project IDs for rake task user management
# Only needed if using project-based access control

ZITADEL_WAREHOUSE_PROJECT_ID=<warehouse-project-id>
ZITADEL_HMIS_PROJECT_ID=<hmis-project-id>
```

---

# Manual Configuration (Production or Custom Setup)

The following instructions are for manually configuring Zitadel, which may be needed for production deployments or custom setups.

## 1. Configure Zitadel Organization and SMTP

1. Login to Zitadel as an administrator
2. Click **Default Settings** (or your organization name)
3. Click **SMTP Provider**
4. Click **Generic SMTP**
5. Give it a name (mailhog)
6. Host and Port: `mailhog:1025`, user: `local`, password: `local`, click **Continue**
7. Sender Email Address: `noreply@zitadel.dev.test` Sender Name: `Zitadel Dev`, click **Continue**
8. Click **Test**, you should receive a test message in Mailhog.  Click **Create**, Click **Activate**

## 2. Create Dex Application in Zitadel

1. Click **Projects**
2. Create a project called **Identity Provider** (or use an existing project)
3. Click **+** to add an Application
4. Name the application **Dex Connector** and choose type **WEB**, click **Continue**
5. Choose **CODE**, click **Continue**
6. Turn on **Development Mode** to allow using `http` in development (not needed in production)
7. Add a **Redirect URI**: `https://dex.dev.test/dex/callback`
8. Add **Post Logout URIs** (IMPORTANT for logout redirect):
   - `https://hmis-warehouse.dev.test/oauth2/sign_out`
   - `https://hmis.dev.test/oauth2/sign_out`
9. Click **Continue**, click **Create**
10. **IMPORTANT**: After creating the application, click on it and go to **Token Settings**:
    - Change **Auth Token Type** to **JWT** (if not already)
    - Under **Additional Settings**, enable **Assert Roles on Authentication**
    - **This allows all organization users to authenticate without needing project-specific grants**
11. **Copy the ClientId and ClientSecret** - add to `.env.local`:
    ```bash
    ZITADEL_IDP_CLIENT_ID=<client-id>
    ZITADEL_IDP_CLIENT_SECRET=<client-secret>
    # Separate client IDs for proper logout redirect handling
    ZITADEL_IDP_WAREHOUSE_CLIENT_ID=<client-id>
    ZITADEL_IDP_HMIS_CLIENT_ID=<client-id>
    ```
12. Copy the **Organization ID** (from organization settings) to `.env.local`:
    ```bash
    ZITADEL_ORG_ID=<org-id>
    ```

## 3. (Optional) Create Separate Projects for Access Control

If you want to manage Warehouse and HMIS users separately:

1. Click **Projects**
2. Create a project called **Warehouse** and note its Project ID
3. Create a project called **HMIS** and note its Project ID
4. Add these to `.env.local`:
    ```bash
    ZITADEL_WAREHOUSE_PROJECT_ID=<warehouse-project-id>
    ZITADEL_HMIS_PROJECT_ID=<hmis-project-id>
    ```
5. Use Zitadel's **Project Grants** feature to assign users to specific projects

**Note**: Even with separate projects, users log in once and can access both applications by default. Use project grants to restrict access if needed.

## 4. Create a Service User for Managing Users

The service user is needed for the rake tasks that import/export users.

1. Go to your Zitadel **Organization** (not a specific project)
2. Click on **Users**, then **Service Users**, then **New**
3. Set the User Name and Name to **rails-app**, leave Access Token Type as **Bearer**, click **Create**
4. Click **Personal Access Tokens**, Click **New**, leave the expiration date empty
5. **Copy the token** and add to `.env.local`:
   ```bash
   ZITADEL_API_URL=http://op-zitadel.dev.test:8080
   ZITADEL_SERVICE_USER_TOKEN=<your-service-user-token>
   ```
6. Click **Organization**, then click the `+` next to the Actions menu
7. Choose the `rails-app` user and check **Org User Manager**, click **Add**
8. Click **Default Settings**
9. Click the `+` next to the ZA and Robot icons
10. Choose the **rails-app** user, grant **Iam Owner** and **Iam User Manager**, click **Add**

## 5. Complete Environment Configuration

Your `.env.local` should now have the necessary Zitadel configuration from the steps above:

```bash
# Zitadel API Configuration
ZITADEL_API_URL=http://op-zitadel.dev.test:8080
ZITADEL_SERVICE_USER_TOKEN=<service-user-token>
ZITADEL_ORG_ID=<org-id>

# Dex Application in Zitadel
ZITADEL_IDP_CLIENT_ID=<dex-client-id>
ZITADEL_IDP_CLIENT_SECRET=<dex-client-secret>

# Logout redirect handling (typically same as ZITADEL_IDP_CLIENT_ID)
ZITADEL_IDP_WAREHOUSE_CLIENT_ID=<dex-client-id>
ZITADEL_IDP_HMIS_CLIENT_ID=<dex-client-id>

# Optional: Project-based access control
ZITADEL_WAREHOUSE_PROJECT_ID=<warehouse-project-id>
ZITADEL_HMIS_PROJECT_ID=<hmis-project-id>
```

**Note**: See the "Environment Configuration Reference" section above for the complete list of JWT validation and authentication variables required by the application.

## 6. Restart Services

```bash
docker compose restart dex oauth2-proxy-warehouse oauth2-proxy-hmis oauth2-proxy-hmis-backend
```

# User Migration

## Test Connection

```bash
rails zitadel:test_connection
```

## Export and Import Warehouse Users

1. Export a sample of 2 Warehouse users for testing:
   ```bash
   rails zitadel:export_users[warehouse,2]
   ```

2. Verify `tmp/zitadel_warehouse_users_export.json` looks correct

3. Import users to Warehouse project:
   ```bash
   rails zitadel:import_users[warehouse,tmp/zitadel_warehouse_users_export.json]
   ```

4. Export all Warehouse users:
   ```bash
   rails zitadel:export_users[warehouse]
   ```

5. Import all users:
   ```bash
   rails zitadel:import_users[warehouse]
   ```

## Export and Import HMIS Users

1. Export HMIS users:
   ```bash
   rails zitadel:export_users[hmis,2]
   ```

2. Verify `tmp/zitadel_hmis_users_export.json` looks correct

3. Import users to HMIS project:
   ```bash
   rails zitadel:import_users[hmis,tmp/zitadel_hmis_users_export.json]
   ```

## Import Single User (for testing)

```bash
# Import to Warehouse project
rails zitadel:import_single_user[warehouse,user@example.com]

# Import to HMIS project
rails zitadel:import_single_user[hmis,user@example.com]
```

# Access Control

Users can be added to one or both projects:

- **Warehouse only**: User added to Warehouse project → can access Warehouse only
- **HMIS only**: User added to HMIS project → can access HMIS only
- **Both applications**: User added to both projects → can access both with SSO

To add an existing user to a project:
1. In Zitadel, navigate to the project (Warehouse or HMIS)
2. Click **Authorizations**
3. Click **+** to add a user
4. Search for and select the user
5. Grant appropriate role (or leave default)

# Testing with JWT Authentication

The test suite includes a `sign_in` helper that mocks JWT authentication for request specs and controller specs.

## Using sign_in in Request Specs

```ruby
RSpec.describe 'Some Feature', type: :request do
  let(:user) { create(:user) }

  it 'allows authenticated users to access the page' do
    sign_in(user)

    get some_path

    expect(response).to be_successful
  end
end
```

## How It Works

The `sign_in` helper (defined in `spec/support/jwt_authentication_helper.rb`):

1. **Generates a mock JWT token**: Creates a unique token like `mock-jwt-token-{user_id}-{random_hex}`
2. **Stubs JwtHelper methods**:
   - `JwtHelper.new` returns a mock helper for the token
   - `JwtHelper.authenticated?(token)` returns true for the mock token
   - `JwtHelper.user_id_from_token(token)` returns the user's ID
3. **Stubs User lookup**: `User.find_from_jwt` returns the signed-in user
4. **Injects headers automatically**: Prepends HTTP method overrides (`get`, `post`, etc.) to automatically include `HTTP_X_FORWARDED_ACCESS_TOKEN` header in all requests
5. **Creates authentication source**: Ensures `UserAuthenticationSource` exists for the user

## Automatic Header Injection

The helper overrides HTTP methods to automatically inject JWT headers:

```ruby
# No need to manually pass headers - they're added automatically
sign_in(user)

get '/path'                          # JWT header included
post '/path', params: { data: 'x' }  # JWT header included
put '/path', params: { data: 'x' }   # JWT header included
```

## Controller Specs

The helper also supports controller specs by stubbing `current_user`:

```ruby
RSpec.describe SomeController, type: :controller do
  let(:user) { create(:user) }

  it 'loads the user' do
    sign_in(user)

    get :index

    expect(controller.current_user).to eq(user)
  end
end
```

## What Gets Stubbed

- **JwtHelper instance**: Mock helper with `token?`, `validate!`, `connector_id`, `connector_user_id`, `payload_email`, `expiration_time`
- **JwtHelper class methods**: `authenticated?(token)`, `user_id_from_token(token)`, `new(access_token:)`
- **User lookup**: `User.find_from_jwt(jwt_helper)`
- **Controller helpers**: `current_user`, `user_signed_in?` (controller specs only)

## Implementation Details

The test helper uses `and_wrap_original` to conditionally stub methods:
- Returns mock values for the generated mock token
- Calls original methods for any other tokens (useful for edge cases)

This approach ensures tests can authenticate as different users sequentially and that JWT authentication works correctly through the entire request cycle.

## Next Steps
Outstanding Questions:

1. How do we replace the following we had in the warehouse:
  a. Single browser login - a user can't be logged in to multiple browsers at once
  b. Password expiration
  c. Forced logout & password reset (API?)
  d. Session timeout length with extension based on use
  e. Account expiration
  f. Invitations
  g. ToTP memory (30 days? optional)
  h. password complexity
  i. max login attempts
  j. password reuse

2. We need to thoroughly test
  a. Session modal
  b. multi-browser login
  c. PDF generation (ensure permisions are obeyed)
  d. logouts
  e. Warden Proxy
  f. User migration

4. We need to build/fix:
  a. Test are still failing
  b. Theme for Dex & Zitadel
  c. Better login links where we can go to the full Dex login if we want, but force most people to default to the right IDP
  d. Superset
  e. CAS
