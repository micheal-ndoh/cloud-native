# Task API - Rust Backend with Keycloak Authentication

A RESTful API built with Rust using the **Axum** framework, featuring Keycloak authentication, comprehensive logging, and Swagger UI documentation.

## Features

* **Keycloak Authentication**: JWT token-based authentication with role-based access control
* **Task Management**: Create, list, and delete tasks with user isolation
* **Admin User Management**: List and delete users (admin-only endpoints)
* **PostgreSQL Integration**: Database operation
* **Structured Logging**: Comprehensive logging with tracing and configurable output formats

* **API Documentation**: Interactive Swagger UI with authentication support
* **Cloud Native**: Kubernetes deployment ready with proper service configuration
* **Docker Support**: Container deployment with Docker and Docker Compose

---

## Prerequisites

* Rust (latest stable version)
* Docker and Docker Compose
* `cargo` installed for building locally

---

## Getting Started

### Environment Setup

1. Copy the example environment file:

```bash
cp .env.example .env
```

2. Edit `.env` with your configuration, including Keycloak settings:

```bash
# Database Configuration
DATABASE_URL=postgresql://admin:password123@localhost:5432/database_name

# Server Configuration
APP_HOST=localhost
APP_PORT=3000

# Keycloak Authentication
KEYCLOAK_URL=http://localhost:8080
KEYCLOAK_REALM=task-realm
KEYCLOAK_ADMIN_CLIENT_ID=admin-cli
KEYCLOAK_ADMIN_CLIENT_SECRET=your-admin-secret
KEYCLOAK_AUDIENCE=task-api-client

# Logging Configuration
LOG_LEVEL=info
LOG_FORMAT=pretty
LOG_OUTPUT=stdout
```

---

### Running with Docker Compose

Start the backend API, PostgreSQL database, and PgAdmin with:

```bash
docker compose up -d
```

Services will be available at:

* **Backend API:** `http://localhost:3000`
* **PostgreSQL:** `localhost:6500`
* **PgAdmin:** `http://localhost:5050`

---

### Database Setup

After starting the services, run database migrations using **SQLx CLI**:

```bash
# Install SQLx CLI if not already installed
cargo install sqlx-cli --no-default-features --features native-tls,postgres

# Run migrations
sqlx migrate run
```

---

### Accessing PgAdmin

1. Open your browser at: `http://localhost:5050`
2. Login with:

   * Email: `admin@admin.com`
   * Password: `password123`
3. Add a new server with the following details:

   * Host: `postgres` (inside Docker network)
   * Port: `5432`
   * Username: `admin`
   * Password: `password123`
   * Database: `database`

> Adjust credentials according to your `.env` file.

---

### Running Locally

```bash
cargo run
```

Application starts on: `http://localhost:3000`

---

### Running with Docker

Build and run the Docker container:

```bash
# Build the Docker image
docker build -t task-api:latest .

# Run the container
docker run -d -p 3000:3000 \
  -e DATABASE_URL=postgresql://admin:password123@localhost:6500/database \
  -e JWT_SECRET=your_ultra_secure_secret \
  -e APP_HOST=0.0.0.0 \
  -e APP_PORT=3000 \
  task-api:latest
```

---

## API Documentation

Swagger UI documentation is available at:

```
http://localhost:3000/swagger-ui
```

OpenAPI JSON specification is available at:

```
http://localhost:3000/api-docs/openapi.json
```

---

### Authentication

The API uses **Keycloak for authentication** with JWT tokens. Most endpoints require authentication with proper role-based access control.

**For complete Keycloak setup instructions, see [../../auth/README.md](../../auth/README.md)**

#### Getting a JWT Token

```bash
# Get token from Keycloak
TOKEN=$(curl -s -X POST "http://localhost:8080/realms/task-realm/protocol/openid-connect/token" \
  -H "Content-Type: application/x-www-form-urlencoded" \
  -d "grant_type=password" \
  -d "client_id=task-api-client" \
  -d "username=testuser" \
  -d "password=testpass" | jq -r .access_token)
```

#### Using the Token

Include the JWT token in the `Authorization` header:

```bash
curl -H "Authorization: Bearer $TOKEN" http://localhost:3000/api/tasks
```


### API Endpoints

#### Health Check

- `GET /api/health` - Application health check (no authentication required)

#### Tasks (User Role Required)

- `POST /api/tasks` - Create a new task
- `GET /api/tasks` - List all tasks for the current user
- `DELETE /api/tasks/{id}` - Delete a task by ID

#### Admin (Admin Role Required)

- `GET /api/admin/users` - List all users from Keycloak
- `DELETE /api/admin/users/{id}` - Delete a user by ID (also cleans up associated tasks)

#### Authentication Features

- **JWT Token Validation**: All protected endpoints validate JWT tokens from Keycloak
- **Role-Based Access**: Different endpoints require different Keycloak roles
- **UUID Handling**: Proper conversion of user IDs from JWT claims to UUID database types
- **Structured Logging**: All requests and authentication events are logged

## Logging

The application implements comprehensive structured logging using the Rust `tracing` ecosystem.

### Features

- **Structured Output**: JSON or pretty-printed logs
- **Request Tracking**: HTTP request/response logging with timing
- **Authentication Events**: Login attempts and token validation
- **Database Operations**: Task creation, updates, and errors
- **UUID Operations**: User ID parsing and validation events
- **Error Tracking**: Detailed error context and stack traces

### Configuration

```bash
# Log level (trace, debug, info, warn, error)
LOG_LEVEL=info

# Output format (pretty for development, json for production)
LOG_FORMAT=json

# Output destination (stdout or file path)
LOG_OUTPUT=stdout
```

### Example Log Output

```json
{
  "timestamp": "2024-01-15T10:30:00.123Z",
  "level": "INFO",
  "fields": {
    "user_id": "123e4567-e89b-12d3-a456-426614174000",
    "task_id": "987fcdeb-51a2-43d1-9c4e-123456789abc",
    "task_name": "Complete project"
  },
  "target": "task_api::handlers::task",
  "message": "Task created successfully"
}
```
