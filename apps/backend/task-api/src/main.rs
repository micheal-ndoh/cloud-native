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
    let logging_config = LoggingConfig::from_env();
    let _guard = logging_config.init();
    
    info!("Starting Task API server");
    
    let config = Config::init();
    info!("Configuration loaded successfully");

    info!("Connecting to database");
    let db = PgPool::connect(&config.database_url).await.map_err(|e| {
        error!("Failed to connect to database: {}", e);
        e
    })?;
    info!("Database connection established");

    // Run embedded migrations at startup
    static MIGRATOR: Migrator = sqlx::migrate!();
    info!("Running database migrations");
    MIGRATOR.run(&db).await.map_err(|e| {
        error!("Failed to run migrations: {}", e);
        e
    })?;
    info!("Database migrations applied");
    
    let state = Arc::new(AppState {
        db,
        config: config.clone(),
    });
    info!("Application state initialized");

    // Initialize Keycloak instance for auth
    info!("Initializing Keycloak authentication");
    let keycloak_config = KeycloakConfig::builder()
        .server(Url::parse(config.keycloak_url.as_str()).unwrap())
        .realm(config.realm.clone())
        .build();

    let keycloak_instance = Arc::new(KeycloakAuthInstance::new(keycloak_config));
    info!("Keycloak authentication initialized");

    let static_service = get_service(
        ServeDir::new("static").append_index_html_on_directories(true),
    )
    .handle_error(|err| async move {
        (axum::http::StatusCode::INTERNAL_SERVER_ERROR, format!("static file error: {}", err))
    });

    let app = routes::create_routes(state.clone(), keycloak_instance)
        .merge(SwaggerUi::new("/swagger-ui").url("/api-docs/openapi.json", ApiDoc::openapi()))
        .route("/docs", axum::routing::get(|| async { Redirect::temporary("/swagger-ui") }))
        .nest_service("/", static_service);

    let addr = format!("{}:{}", state.config.host, state.config.port);
    let listener = TcpListener::bind(&addr).await.map_err(|e| {
        error!("Failed to bind to address {}: {}", addr, e);
        e
    })?;
    
    info!(
        address = %addr,
        "Task API server listening"
    );
    info!(
        swagger_url = format!("http://{}/swagger-ui", addr),
        "Swagger UI available"
    );

    info!("Starting HTTP server");
    serve(listener, app).await.map_err(|e| {
        error!("Server error: {}", e);
        e
    })?;

    info!("Server shutdown");
    Ok(())
}
