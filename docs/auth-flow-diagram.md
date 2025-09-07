# Cloud Native Gauntlet - Authentication Flow Diagram

## JWT Authentication Flow with Keycloak

```mermaid
sequenceDiagram
    participant U as User
    participant W as Web Browser
    participant KC as Keycloak
    participant API as Task API
    participant DB as PostgreSQL
    
    Note over U,DB: Authentication Flow
    
    %% Initial Access
    U->>W: Access task-api.local
    W->>API: GET /tasks (no token)
    API-->>W: 401 Unauthorized
    
    %% Redirect to Keycloak
    W->>KC: Redirect to /auth/realms/master/protocol/openid-connect/auth
    KC->>W: Login Form
    
    %% User Login
    U->>KC: Enter credentials
    KC->>KC: Validate credentials
    KC->>KC: Generate JWT token
    
    %% Token Response
    KC->>W: Redirect with authorization code
    W->>KC: Exchange code for token
    KC->>W: Return JWT token (access_token, refresh_token)
    
    %% API Access with Token
    W->>API: GET /tasks + Authorization: Bearer <JWT>
    API->>API: Validate JWT signature
    API->>API: Extract user claims (sub, roles, exp)
    
    %% Database Query
    API->>DB: SELECT * FROM tasks WHERE user_id = ?
    DB->>API: Return user tasks
    API->>W: 200 OK + JSON response
    
    %% Subsequent Requests
    loop Subsequent API calls
        W->>API: Request + JWT token
        API->>API: Validate token
        API->>DB: Database operation
        DB->>API: Response
        API->>W: JSON response
    end
    
    %% Token Refresh
    Note over W,KC: Token Refresh Flow
    W->>KC: POST /auth/realms/master/protocol/openid-connect/token
    Note right of W: grant_type=refresh_token<br/>refresh_token=<token>
    KC->>KC: Validate refresh token
    KC->>W: New access_token + refresh_token
    
    %% Logout
    Note over U,KC: Logout Flow
    U->>W: Click logout
    W->>KC: POST /auth/realms/master/protocol/openid-connect/logout
    KC->>W: Logout confirmation
    W->>W: Clear stored tokens
```

## Role-Based Access Control (RBAC)

```mermaid
graph TB
    subgraph "Keycloak Realm"
        REALM[Master Realm]
        USERS[Users]
        ROLES[Roles]
        CLIENTS[Clients]
    end
    
    subgraph "User Roles"
        ADMIN[Admin Role]
        USER[User Role]
    end
    
    subgraph "API Endpoints"
        ADMIN_ENDPOINTS[Admin Endpoints:<br/>- GET /admin/users<br/>- POST /admin/tasks<br/>- DELETE /admin/tasks]
        USER_ENDPOINTS[User Endpoints:<br/>- GET /tasks<br/>- POST /tasks<br/>- PUT /tasks/:id<br/>- DELETE /tasks/:id]
    end
    
    subgraph "JWT Token Claims"
        SUB[sub: user-id]
        ROLES_CLAIM[roles: ['admin', 'user']]
        EXP[exp: expiration]
        ISS[iss: keycloak issuer]
    end
    
    %% Role assignments
    USERS --> ADMIN
    USERS --> USER
    
    %% Role to endpoint mapping
    ADMIN --> ADMIN_ENDPOINTS
    ADMIN --> USER_ENDPOINTS
    USER --> USER_ENDPOINTS
    
    %% Token generation
    REALM --> ROLES_CLAIM
    ADMIN --> ROLES_CLAIM
    USER --> ROLES_CLAIM
    
    %% Styling
    classDef keycloak fill:#e3f2fd
    classDef roles fill:#f1f8e9
    classDef endpoints fill:#fff3e0
    classDef token fill:#fce4ec
    
    class REALM,USERS,ROLES,CLIENTS keycloak
    class ADMIN,USER roles
    class ADMIN_ENDPOINTS,USER_ENDPOINTS endpoints
    class SUB,ROLES_CLAIM,EXP,ISS token
```

## Service Mesh Security (mTLS)

```mermaid
graph TB
    subgraph "Service Mesh Security"
        LINKERD[Linkerd Control Plane]
        IDENTITY[Identity Service]
        CERT_MGR[Certificate Manager]
    end
    
    subgraph "Services with mTLS"
        KC[Keycloak]
        API[Task API]
        PG[PostgreSQL]
        PROM[Prometheus]
        GRAF[Grafana]
    end
    
    subgraph "Certificate Flow"
        CERT_GEN[Certificate Generation]
        CERT_VALID[Certificate Validation]
        CERT_ROTATE[Certificate Rotation]
    end
    
    %% Certificate management
    LINKERD --> IDENTITY
    IDENTITY --> CERT_MGR
    CERT_MGR --> CERT_GEN
    
    %% Service enrollment
    KC --> LINKERD
    API --> LINKERD
    PG --> LINKERD
    PROM --> LINKERD
    GRAF --> LINKERD
    
    %% Certificate distribution
    CERT_GEN --> KC
    CERT_GEN --> API
    CERT_GEN --> PG
    CERT_GEN --> PROM
    CERT_GEN --> GRAF
    
    %% Validation
    KC --> CERT_VALID
    API --> CERT_VALID
    PG --> CERT_VALID
    PROM --> CERT_VALID
    GRAF --> CERT_VALID
    
    %% Rotation
    CERT_MGR --> CERT_ROTATE
    CERT_ROTATE --> KC
    CERT_ROTATE --> API
    CERT_ROTATE --> PG
    CERT_ROTATE --> PROM
    CERT_ROTATE --> GRAF
    
    %% Styling
    classDef mesh fill:#e8f5e8
    classDef services fill:#fff3e0
    classDef certs fill:#fce4ec
    
    class LINKERD,IDENTITY,CERT_MGR mesh
    class KC,API,PG,PROM,GRAF services
    class CERT_GEN,CERT_VALID,CERT_ROTATE certs
```

## Security Features

### JWT Authentication
- **Keycloak Integration**: Centralized identity management
- **OpenID Connect**: Industry-standard authentication protocol
- **Token Validation**: Signature verification and expiration checking
- **Role-Based Access**: Fine-grained permission control

### Service Mesh Security
- **mTLS Encryption**: Automatic encryption between services
- **Certificate Management**: Automatic certificate generation and rotation
- **Identity Verification**: Service-to-service authentication
- **Traffic Encryption**: All inter-service communication encrypted

### API Security
- **Bearer Token**: JWT tokens in Authorization header
- **Role Validation**: Endpoint access based on user roles
- **Token Refresh**: Automatic token renewal
- **Secure Logout**: Proper token invalidation

### Network Security
- **Ingress Controller**: Traefik provides TLS termination
- **Local Domains**: No external DNS exposure
- **Firewall Rules**: VM-level network isolation
- **Private Registry**: Container images stored locally