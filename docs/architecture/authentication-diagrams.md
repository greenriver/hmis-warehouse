# Authentication Architecture - Mermaid Diagrams

## System Architecture Diagram

```mermaid
graph TB
    User["👤 User<br/>(Browser)"]
    Traefik["🔀 Traefik<br/>(Optional for HTTPS)<br/>Port 443"]
    O2P["🔐 OAuth2-Proxy<br/>(Node.js)<br/>Port 4180-4182"]
    Dex["🔑 Dex<br/>(OIDC Broker)<br/>Port 4443"]

    Zitadel["👥 Zitadel<br/>(User IDP)<br/>Port 8080"]
    GitHub["🐙 GitHub<br/>(Optional)"]
    LocalAuth["🧪 Local Users<br/>(Dev Only)"]

    Rails["🚂 Rails App<br/>(HMIS Warehouse)<br/>Port 3000"]
    DB["🗄️ PostgreSQL<br/>(Users, Auth Sources,<br/>IDP Configs)"]

    User -->|HTTP/HTTPS| Traefik
    Traefik -->|HTTP| O2P
    O2P -->|Validates| Rails
    O2P -->|Auth Request| Dex

    Dex -->|User Auth| Zitadel
    Dex -->|OAuth| GitHub
    Dex -->|Test Users| LocalAuth

    Rails -->|Query/Update| DB

    style User fill:#e1f5ff
    style Traefik fill:#ffe0b2
    style O2P fill:#f3e5f5
    style Dex fill:#ede7f6
    style Zitadel fill:#e8f5e9
    style GitHub fill:#f5f5f5
    style LocalAuth fill:#fff9c4
    style Rails fill:#e0f2f1
    style DB fill:#fce4ec
```

## OAuth2 Authentication Flow

```mermaid
sequenceDiagram
    actor User
    participant Browser
    participant OAuth2P as OAuth2-Proxy
    participant Dex
    participant Zitadel as Zitadel IDP
    participant Rails
    participant DB as PostgreSQL

    User->>Browser: 1. Visit https://hmis-warehouse.dev.test
    Browser->>OAuth2P: GET /
    OAuth2P->>OAuth2P: Check session cookie

    alt No valid session
        OAuth2P-->>Browser: 302 Redirect to /oauth2/auth
        Browser->>Dex: GET /dex/auth
        Dex-->>Browser: Show connector options
        Browser->>User: 2. Select Authentication Method
        User->>Browser: Choose Zitadel
        Browser->>Dex: Initiate OIDC flow
        Dex-->>Browser: Redirect to Zitadel

        Browser->>Zitadel: GET /login
        Zitadel-->>Browser: Show login form
        Browser->>User: 3. Enter credentials
        User->>Browser: email + password
        Browser->>Zitadel: POST /login
        Zitadel->>DB: Verify credentials

        Zitadel-->>Browser: Redirect to Dex callback
        Browser->>Dex: GET /callback?code=AUTH_CODE
        Dex->>Zitadel: 4. Exchange code for ID token
        Zitadel-->>Dex: ID token + Access token
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
    OAuth2P->>OAuth2P: 6. Inject headers:<br/>X-Forwarded-User<br/>X-Forwarded-Access-Token<br/>X-Forwarded-Groups
    OAuth2P->>Rails: Forward request + headers

    Rails->>Rails: CurrentUser middleware
    Rails->>Rails: JwtHelper.validate_jwt()
    Rails->>Rails: 7. Verify RS256 signature
    Rails->>Rails: Verify issuer & audience
    Rails->>Rails: Verify expiration
    Rails->>Rails: Extract claims

    Rails->>DB: 8. Find/Create User
    DB-->>Rails: User found or created
    Rails->>Rails: Set current_user
    Rails-->>Browser: 9. Return authenticated response
    Browser->>User: Display HMIS Warehouse
```

## Token Lifecycle and Auto-Refresh

```mermaid
timeline
    title JWT Token Lifecycle (30 minute expiry)

    section Token Issued
    0m : JWT issued by Dex
        : Stored in HTTP-only cookie
        : Expires at 30 minutes

    section Active Use
    5m : User browsing
        : Token still valid
        : Auto-refresh disabled
    10m : User browsing
        : Token still valid
        : Auto-refresh disabled

    section Pre-Expiry Window
    20m : 10 minutes until expiry
        : ⚠️ Auto-refresh triggered
        : New JWT requested from Dex
        : Cookie updated with new token

    section Still Active
    23m : User continues working
        : Using NEW token (exp 53m)
        : Auto-refresh window reset

    section Expiry
    30m : ORIGINAL token would expire
        : But already refreshed at 20m
        : User unaffected (transparent)

    section Session Timeout Warning
    25m : If user INACTIVE for 5 min
        : Session timeout modal appears
        : User prompted to continue
        : If ignored → logout after 30m
```

## Data Models

```mermaid
erDiagram
    USERS ||--o{ USER_AUTHENTICATION_SOURCES : has
    USERS ||--o{ IDP_SERVICE_CONFIGS : manages

    USERS {
        uuid id
        string email
        string first_name
        string last_name
        datetime last_activity_at
        string denylist_token_subject "For force logout"
        boolean active
        datetime created_at
        datetime updated_at
    }

    USER_AUTHENTICATION_SOURCES {
        uuid id
        uuid user_id
        string connector_id "zitadel, github, etc"
        string connector_user_id "User ID from IDP"
        boolean enabled
        datetime deleted_at
        datetime created_at
        datetime updated_at
    }

    IDP_SERVICE_CONFIGS {
        uuid id
        string connector_id "zitadel, okta, etc"
        string name "Display name"
        string api_url "IDP API endpoint"
        string encrypted_service_token "Encrypted PAT"
        string org_id "Organization ID"
        string project_id "Project ID"
        jsonb additional_config "Extra settings"
        boolean active
        datetime deleted_at
        datetime created_at
        datetime updated_at
    }
```

## JWT Token Structure and Claims

```mermaid
graph TD
    JWT["JWT Token"]

    Header["Header<br/>───────<br/>alg: RS256<br/>typ: JWT"]

    Payload["Payload<br/>───────<br/>Standard Claims:<br/>iss: Dex URL<br/>sub: User ID<br/>aud: App IDs<br/>exp: Expiry<br/>iat: Issued At<br/><br/>Custom Claims:<br/>email: user@example.com<br/>name: John Doe<br/>groups: [...roles]<br/>connectorID: zitadel<br/>at_hash: Session ID"]

    Signature["Signature<br/>───────<br/>RS256(<br/>Header + Payload,<br/>Private Key<br/>)<br/>= Cryptographic proof"]

    JWT --> Header
    JWT --> Payload
    JWT --> Signature

    style JWT fill:#e3f2fd
    style Header fill:#f3e5f5
    style Payload fill:#e8f5e9
    style Signature fill:#fff3e0
```

## Component Interaction Diagram

```mermaid
graph LR
    subgraph "Client Layer"
        A["Browser<br/>(Client Session)"]
    end

    subgraph "Reverse Proxy (Optional)"
        Optional["🔀 Traefik<br/>(Optional for HTTPS<br/>in dev environment)"]
    end

    subgraph "Authentication Layer"
        B["OAuth2-Proxy<br/>(JWT Validation<br/>Session Mgmt)"]
        C["Dex<br/>(OIDC Broker)"]
    end

    subgraph "Identity Layer"
        D["Zitadel<br/>(User Management)"]
        E["GitHub<br/>(Optional)"]
    end

    subgraph "Application Layer"
        F["Rails App<br/>(Authorization<br/>Business Logic)"]
        G["PostgreSQL<br/>(Persistent State)"]
    end

    A -->|1. Browser| Optional
    Optional -->|2. HTTP| B
    B -->|3. Auth Request| C
    C -->|4. Connector Selection| D
    C -->|4. Connector Selection| E
    D -->|5. User Auth| G
    C -->|6. Issue JWT| B
    B -->|7. Forward Request<br/>+JWT Headers| F
    F -->|8. Extract JWT<br/>Validate Signature| C
    F -->|9. Find/Create User| G
    F -->|10. Authenticate| A

    style A fill:#e1f5ff
    style Optional fill:#ffe0b2
    style B fill:#f3e5f5
    style C fill:#ede7f6
    style D fill:#e8f5e9
    style E fill:#f5f5f5
    style F fill:#e0f2f1
    style G fill:#fce4ec
```

## Session Management State Machine

```mermaid
stateDiagram-v2
    [*] --> NoSession: User visits app

    NoSession --> Authenticating: Redirect to OAuth2

    Authenticating --> AwaitingIDPAuth: OAuth2-proxy initiates<br/>Dex OIDC flow

    AwaitingIDPAuth --> IDPAuthComplete: User enters<br/>credentials

    IDPAuthComplete --> TokenExchange: Dex receives<br/>auth code

    TokenExchange --> JWTIssued: Dex issues JWT<br/>to OAuth2-proxy

    JWTIssued --> SessionActive: Session cookie<br/>stored

    SessionActive --> SessionActive: User requests<br/>Auto-refresh<br/>at 20 min

    SessionActive --> InactivityWarning: 25 min inactivity<br/>warning shown

    InactivityWarning --> SessionActive: User continues

    InactivityWarning --> SessionExpired: User ignores warning<br/>30 min reached

    SessionExpired --> [*]: Redirect to login

    SessionActive --> SessionExpired: 12 hour hard<br/>limit reached

    note right of SessionActive
        Token expiry: 30 min
        Hard limit: 12 hours
        Idle warning: 5 min
        Auto-refresh: 10 min before expiry
    end note
```

## Request Validation Pipeline

```mermaid
graph TD
    A["HTTP Request<br/>with JWT Cookie"] -->|1. Extract Cookie| B["Parse Cookie<br/>Get JWT String"]
    B -->|2. Verify Signature| C["RS256 Signature Check<br/>using Dex Public Keys"]

    C -->|✓ Valid| D{"Check Issuer"}
    C -->|✗ Invalid| E["❌ Authentication Failed<br/>401 Unauthorized"]

    D -->|✓ Matches ISS_URL| F{"Check Audience"}
    D -->|✗ Mismatch| E

    F -->|✓ In AUD List| G{"Check Expiration"}
    F -->|✗ Not in audience| E

    G -->|✓ Not Expired| H["Extract Claims<br/>email, name, groups, sub"]
    G -->|✗ Expired| E

    H --> I["Lookup User by<br/>UserAuthenticationSource"]
    I -->|Found| J["Set current_user<br/>Request Allowed"]
    I -->|Not Found| K{"Auto-create<br/>enabled?"}

    K -->|Yes| L["Create User +<br/>AuthSource"]
    K -->|No| E

    L --> J["Set current_user<br/>Request Allowed"]

    J --> M["✅ Request Proceeds<br/>with Authorization"]
    E --> N["🛑 Request Rejected<br/>Redirect to Login"]

    style A fill:#e3f2fd
    style C fill:#fff3e0
    style E fill:#ffebee
    style H fill:#e8f5e9
    style J fill:#c8e6c9
    style M fill:#a5d6a7
    style N fill:#ef9a9a
```
