# External IDP Authentication

The HMIS Warehouse uses an external Identity Provider (IDP) for user authentication instead of managing users directly within the application. This architectural decision provides several key benefits: improved security through centralized identity management, support for Single Sign-On (SSO) across multiple applications, delegation of password management and two-factor authentication to specialized systems, and the ability to integrate with existing organizational IDPs that communities may already have in place.

The authentication flow involves multiple components working together through **three separate OAuth2-Proxy instances**:

1. **oauth2-proxy-warehouse** - Handles authentication for the Warehouse Rails application
2. **oauth2-proxy-hmis** - Handles authentication for the HMIS React frontend
3. **oauth2-proxy-hmis-backend** - Validates authentication for API requests from HMIS frontend to Rails backend

When a user accesses either application, the appropriate **OAuth2-proxy** instance acts as a reverse proxy, intercepting requests and validating authentication. OAuth2-proxy communicates with **Dex**, which serves as an identity broker capable of connecting to various upstream IDPs. For communities with their own IDPs, Dex plays intermediary; for communities without IDP infrastructure, we use **Zitadel** to provide account management. The Rails application receives validated JWT tokens from OAuth2-proxy via HTTP headers and uses these tokens to identify and authenticate users without handling passwords or authentication credentials directly.

The three-proxy architecture enables **session isolation**: logging out of Warehouse doesn't affect HMIS, and vice versa. The HMIS frontend and backend proxies share the same authentication cookie (`_oauth2_proxy_hmis`) to allow seamless API access, while Warehouse uses a separate cookie (`_oauth2_proxy_warehouse`).

The warehouse application receives authentication information through standardized HTTP headers injected by OAuth2-proxy. The `X-Forwarded-Access-Token` header contains the JWT access token that includes user identity claims such as email, name, and connector information. The application's `CurrentUser` concern validates this token, extracts user information, and looks up or creates the corresponding `User` record in the warehouse database. This process ensures that users authenticated via any supported IDP can access the warehouse seamlessly, while the warehouse maintains its own user records for authorization and audit purposes.

User management responsibilities are clearly separated between the IDP and the warehouse application. The IDP handles all authentication-related concerns including password policies, password resets, account locking, two-factor authentication, and session expiration. The warehouse application focuses solely on authorization—determining what authenticated users are permitted to access based on their roles, permissions, and data access assignments.

The system supports multiple IDP backends through Dex's connector architecture, allowing deployments to use existing identity infrastructure or a standalone Zitadel instance for communities without an existing IDP. The warehouse tracks which IDP each user authenticated through via the `UserAuthenticationSource` model, which links warehouse users to their IDP user accounts. This design enables communities to migrate from one IDP to another or support multiple IDPs simultaneously, while maintaining consistent user experience and access control within the warehouse application.

## Key Components

- **oauth2-proxy-warehouse** (`hmis-warehouse.dev.test`): Reverse proxy for Warehouse application, uses `_oauth2_proxy_warehouse` cookie
- **oauth2-proxy-hmis** (`hmis.dev.test`): Reverse proxy for HMIS React frontend, uses `_oauth2_proxy_hmis` cookie
- **oauth2-proxy-hmis-backend** (`hmis-backend.dev.test`): Reverse proxy for HMIS API requests, shares `_oauth2_proxy_hmis` cookie with frontend
- **Dex**: Identity broker that supports multiple upstream IDP connectors
- **IDP** (e.g., Zitadel, Okta, Azure AD): Handles user authentication and credential management
- **Rails Application**: Validates JWT tokens and manages authorization and access control for both Warehouse and HMIS

## Authentication Flow

### Warehouse Authentication

1. User requests access to `hmis-warehouse.dev.test`
2. oauth2-proxy-warehouse intercepts request and checks for valid session cookie (`_oauth2_proxy_warehouse`)
3. If unauthenticated, user is redirected to IDP login page
4. User authenticates with IDP (via Dex)
5. IDP issues JWT token to oauth2-proxy-warehouse
6. oauth2-proxy-warehouse sets cookie and forwards request with `X-Forwarded-Access-Token` header
7. Rails application validates JWT and looks up/creates User record
8. User is authenticated and authorized based on warehouse permissions

### HMIS Authentication

1. User requests access to `hmis.dev.test`
2. oauth2-proxy-hmis intercepts request and checks for valid session cookie (`_oauth2_proxy_hmis`)
3. If unauthenticated, user is redirected to IDP login page (same flow as Warehouse)
4. User authenticates and oauth2-proxy-hmis sets the `_oauth2_proxy_hmis` cookie
5. React frontend loads and makes API requests to `/hmis/*` endpoints
6. Vite dev server proxies these requests to `hmis-backend.dev.test`
7. oauth2-proxy-hmis-backend validates the shared `_oauth2_proxy_hmis` cookie and injects JWT headers
8. Rails application validates JWT and processes the API request

**Key point**: The HMIS frontend and backend share the same authentication cookie, enabling seamless API access without requiring separate authentication.

## Session Management

- Session expiration is controlled entirely by the IDP and reflected in JWT token expiration
- The warehouse application reads expiration time from JWT tokens for display purposes
- Session keepalive endpoint triggers OAuth2-proxy to refresh tokens when possible
- Default session timeout (30 minutes) is centralized in `Idp::ServiceFactory.default_session_timeout`
