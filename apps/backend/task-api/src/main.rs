use axum::{
    serve,
    response::Redirect,
    routing::get_service,
};
use reqwest::Url;
use sqlx::{PgPool, migrate::Migrator};
use std::sync::Arc;
use tokio::net::TcpListener;
use utoipa::OpenApi;
use utoipa_swagger_ui::SwaggerUi;
use tower_http::services::ServeDir;

mod handlers;
mod models;
mod routes;

use crate::models::{config::Config, state::AppState, logging::LoggingConfig};
use axum_keycloak_auth::instance::{KeycloakAuthInstance, KeycloakConfig};
use tracing::{info, error};

#[derive(OpenApi)]
#[openapi(
    paths(
        handlers::task::create_task,
        handlers::task::list_tasks,
        handlers::task::delete_task,
        handlers::user::list_users,
        handlers::user::delete_user,
        handlers::health::health,
    ),
    components(
        schemas(
            models::task::Task,
            models::task::CreateTaskSchema,
            models::response::UserResponse,
            models::response::TaskResponse,
            models::response::TaskListResponse,
        )
    ),
    tags(
        (name = "tasks", description = "Task management endpoints"),
        (name = "users", description = "User management endpoints (admin only)"),
        (name = "health", description = "Check app health"),
    ),
    security(
        ("api_jwt_token" = [])
    ),
    modifiers(&SecurityAddon)
)]
struct ApiDoc;

struct SecurityAddon;

impl utoipa::Modify for SecurityAddon {
    fn modify(&self, openapi: &mut utoipa::openapi::OpenApi) {
        let components = openapi.components.as_mut().unwrap();
        components.add_security_scheme(
            "api_jwt_token",
            utoipa::openapi::security::SecurityScheme::Http(
                utoipa::openapi::security::HttpBuilder::new()
                    .scheme(utoipa::openapi::security::HttpAuthScheme::Bearer)
                    .bearer_format("JWT")
                    .build(),
            ),
        );
    }
}

#[tokio::main]
async fn main() -> Result<(), Box<dyn std::error::Error>> {
    // Initialize logging first, before any other operations
    println!("DEBUG: Starting application initialization...");
    let logging_config = LoggingConfig::from_env();
    println!("DEBUG: Logging config created");
    let _guard = logging_config.init();
    println!("DEBUG: Logging initialized");
    
    info!("Starting Task API server");
    println!("DEBUG: About to load configuration...");
    
    let config = Config::init();
    info!("Configuration loaded successfully");
    println!("DEBUG: Configuration loaded successfully");

    info!("Connecting to database");
    println!("DEBUG: About to connect to database: {}", config.database_url);
    let db = PgPool::connect(&config.database_url).await.map_err(|e| {
        error!("Failed to connect to database: {}", e);
        println!("DEBUG: Database connection failed: {}", e);
        e
    })?;
    info!("Database connection established");
    println!("DEBUG: Database connection established");

    // Run embedded migrations at startup
    static MIGRATOR: Migrator = sqlx::migrate!();
    info!("Running database migrations");
    println!("DEBUG: About to run migrations...");
    MIGRATOR.run(&db).await.map_err(|e| {
        error!("Failed to run migrations: {}", e);
        println!("DEBUG: Migration failed: {}", e);
        e
    })?;
    info!("Database migrations applied");
    println!("DEBUG: Database migrations applied");
    
    let state = Arc::new(AppState {
        db,
        config: config.clone(),
    });
    info!("Application state initialized");
    println!("DEBUG: Application state initialized");

    // Initialize Keycloak instance for auth
    info!("Initializing Keycloak authentication");
    println!("DEBUG: About to initialize Keycloak...");
    let keycloak_config = KeycloakConfig::builder()
        .server(Url::parse(config.keycloak_url.as_str()).unwrap())
        .realm(config.realm.clone())
        .build();

    let keycloak_instance = Arc::new(KeycloakAuthInstance::new(keycloak_config));
    info!("Keycloak authentication initialized");
    println!("DEBUG: Keycloak authentication initialized");

    println!("DEBUG: About to create static service...");
    let static_service = get_service(
        ServeDir::new("static").append_index_html_on_directories(true),
    )
    .handle_error(|err| async move {
        (axum::http::StatusCode::INTERNAL_SERVER_ERROR, format!("static file error: {}", err))
    });
    println!("DEBUG: Static service created");

    println!("DEBUG: About to create routes...");
    let app = routes::create_routes(state.clone(), keycloak_instance)
        .merge(SwaggerUi::new("/swagger-ui").url("/api-docs/openapi.json", ApiDoc::openapi()))
        .route("/docs", axum::routing::get(|| async { Redirect::temporary("/swagger-ui") }))
        .fallback_service(static_service);
    println!("DEBUG: Routes created");

    let addr = format!("{}:{}", state.config.host, state.config.port);
    println!("DEBUG: About to bind to address: {}", addr);
    let listener = TcpListener::bind(&addr).await.map_err(|e| {
        error!("Failed to bind to address {}: {}", addr, e);
        println!("DEBUG: Failed to bind to address {}: {}", addr, e);
        e
    })?;
    println!("DEBUG: Successfully bound to address: {}", addr);
    
    info!(
        address = %addr,
        "Task API server listening"
    );
    info!(
        swagger_url = format!("http://{}/swagger-ui", addr),
        "Swagger UI available"
    );

    info!("Starting HTTP server");
    println!("DEBUG: About to start HTTP server...");
    serve(listener, app).await.map_err(|e| {
        error!("Server error: {}", e);
        println!("DEBUG: Server error: {}", e);
        e
    })?;

    info!("Server shutdown");
    println!("DEBUG: Server shutdown");
    Ok(())
}
