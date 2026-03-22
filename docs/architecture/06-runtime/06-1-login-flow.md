# 6.1 Login Flow

[← 6 Runtime View](06-0-runtime-view.md) | [Table of Contents](../README.md) | [Next: 6.2 HUD CSV Import →](06-2-data-sync.md)

This scenario describes the process of a user authenticating with the Open Path Platform using the distributed identity layer.

## Scenario Description
A user attempts to access the HMIS Warehouse. The request is intercepted by the authentication layer, which brokers the identity request through Dex to a configured Identity Provider (Keycloak). Upon successful authentication, a JWT is issued and injected into the request headers for the Warehouse Application to consume.

## Involved Building Blocks
- **User (Browser)**: The client initiating the request.
- **[Authentication Layer](../05-building-blocks/05-2-3-authentication.md)**: OAuth2-Proxy and Dex working together to validate and broker identity.
- **[Keycloak](../05-building-blocks/05-2-3-authentication.md)**: The primary Identity Provider (IDP).
- **[Warehouse Application](../05-building-blocks/05-2-1-warehouse.md)**: The Rails backend that authorizes the user based on the provided JWT claims.

## Sequence Diagram

```mermaid
sequenceDiagram
    actor User
    participant Browser
    participant OAuth2P as OAuth2-Proxy
    participant Dex
    participant Keycloak as Keycloak IDP
    participant Rails as Warehouse App
    participant DB as Warehouse DB

    User->>Browser: 1. Visit https://hmis.openpath.org
    Browser->>OAuth2P: GET /
    OAuth2P->>OAuth2P: Check session cookie

    alt No valid session
        OAuth2P-->>Browser: 302 Redirect to /oauth2/auth
        Browser->>Dex: GET /dex/auth
        Dex-->>Browser: Show connector options
        Browser->>User: 2. Select Authentication Method
        User->>Browser: Choose Keycloak
        Browser->>Dex: Initiate OIDC flow
        Dex-->>Browser: Redirect to Keycloak

        Browser->>Keycloak: GET /login
        Keycloak-->>Browser: Show login form
        Browser->>User: 3. Enter credentials
        User->>Browser: email + password
        Browser->>Keycloak: POST /login
        Keycloak->>Keycloak: Verify credentials

        Keycloak-->>Browser: Redirect to Dex callback
        Browser->>Dex: GET /callback?code=AUTH_CODE
        Dex->>Keycloak: 4. Exchange code for ID token
        Keycloak-->>Dex: ID token + Access token
        Dex->>Dex: Issue JWT token
        Dex-->>Browser: Redirect to OAuth2P callback

        Browser->>OAuth2P: GET /callback?code=DEX_CODE
        OAuth2P->>Dex: Exchange code for JWT
        Dex-->>OAuth2P: JWT token
        OAuth2P->>OAuth2P: Validate JWT signature
        OAuth2P->>OAuth2P: Create session cookie
        OAuth2P-->>Browser: 302 Redirect to /
    end

    Browser->>OAuth2P: 5. GET / (with session cookie)
    OAuth2P->>OAuth2P: Validate JWT from cookie
    OAuth2P->>OAuth2P: Extract user info from JWT
    OAuth2P->>OAuth2P: 6. Inject headers (X-Forwarded-User, etc.)
    OAuth2P->>Rails: Forward request + headers

    Rails->>Rails: CurrentUser middleware
    Rails->>Rails: 7. Verify JWT signature & claims
    Rails->>DB: 8. Find/Create User record
    DB-->>Rails: User found
    Rails->>Rails: Set current_user context
    Rails-->>Browser: 9. Return authenticated response
    Browser->>User: Display HMIS Dashboard
```

## Notable Aspects
1. **Header-Based Identity**: The Warehouse Application trusts the `X-Forwarded-User` and other headers because it is situated behind the OAuth2-Proxy, which is responsible for the cryptographic validation of the JWT.
2. **Transparent Refresh**: (See Section 8.x for details) The OAuth2-Proxy can automatically refresh tokens before they expire, providing a seamless user experience.
3. **Just-In-Time (JIT) Provisioning**: The Warehouse Application creates a local `User` record upon the first successful login if one does not already exist, using the claims provided in the JWT.
