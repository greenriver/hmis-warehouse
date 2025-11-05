# External IDP Authentication

The HMIS Warehouse uses an external Identity Provider (IDP) for user authentication instead of managing users directly within the application. This architectural decision provides several key benefits: improved security through centralized identity management, support for Single Sign-On (SSO) across multiple applications, delegation of password management and two-factor authentication to specialized systems, and the ability to integrate with existing organizational IDPs that communities may already have in place.

The authentication flow involves three main components working together. When a user accesses the warehouse, **OAuth2-proxy** acts as a reverse proxy in front of the application, intercepting all requests and validating authentication. OAuth2-proxy communicates with **Dex**, which serves as an identity broker capable of connecting to various upstream IDPs. For communities with their own IDPs, Dex plays intermediary, for communities that do not have IDP infrastructure, we use **Zitadel** to provide account management. The warehouse application itself receives validated JWT tokens from OAuth2-proxy via HTTP headers and uses these tokens to identify and authenticate users without handling passwords or authentication credentials directly.

The warehouse application receives authentication information through standardized HTTP headers injected by OAuth2-proxy. The `X-Forwarded-Access-Token` header contains the JWT access token that includes user identity claims such as email, name, and connector information. The application's `CurrentUser` concern validates this token, extracts user information, and looks up or creates the corresponding `User` record in the warehouse database. This process ensures that users authenticated via any supported IDP can access the warehouse seamlessly, while the warehouse maintains its own user records for authorization and audit purposes.

User management responsibilities are clearly separated between the IDP and the warehouse application. The IDP handles all authentication-related concerns including password policies, password resets, account locking, two-factor authentication, and session expiration. The warehouse application focuses solely on authorization—determining what authenticated users are permitted to access based on their roles, permissions, and data access assignments.

The system supports multiple IDP backends through Dex's connector architecture, allowing deployments to use existing identity infrastructure or a standalone Zitadel instance for communities without an existing IDP. The warehouse tracks which IDP each user authenticated through via the `UserAuthenticationSource` model, which links warehouse users to their IDP user accounts. This design enables communities to migrate from one IDP to another or support multiple IDPs simultaneously, while maintaining consistent user experience and access control within the warehouse application.

## Key Components

- **OAuth2-proxy**: Reverse proxy that validates authentication and injects JWT tokens into requests
- **Dex**: Identity broker that supports multiple upstream IDP connectors
- **IDP** (e.g., Zitadel, Okta, Azure AD): Handles user authentication and credential management
- **Warehouse Application**: Validates JWT tokens and manages authorization and access control

## Authentication Flow

1. User requests access to warehouse application
2. OAuth2-proxy intercepts request and checks for valid session
3. If unauthenticated, user is redirected to IDP login page
4. User authenticates with IDP (via Dex)
5. IDP issues JWT token to OAuth2-proxy
6. OAuth2-proxy validates token and forwards request with `X-Forwarded-Access-Token` header
7. Warehouse application validates JWT and looks up/creates User record
8. User is authenticated and authorized based on warehouse permissions

## Session Management

- Session expiration is controlled entirely by the IDP and reflected in JWT token expiration
- The warehouse application reads expiration time from JWT tokens for display purposes
- Session keepalive endpoint triggers OAuth2-proxy to refresh tokens when possible
- Default session timeout (30 minutes) is centralized in `Idp::ServiceFactory.default_session_timeout`
