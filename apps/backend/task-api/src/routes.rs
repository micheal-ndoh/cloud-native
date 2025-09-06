use crate::{
    handlers::{
        health::health,
        logging_middleware::logging_middleware,
        middleware::admin_guard,
        task::{create_task, delete_task, list_tasks},
        user::{delete_user, list_users},
    },
    models::{role::Role, state::AppState},
};
use axum::{
    middleware,
    routing::{delete, get, post},
    Router,
};
use axum_keycloak_auth::instance::KeycloakAuthInstance;
use axum_keycloak_auth::{layer::KeycloakAuthLayer, PassthroughMode};
use std::sync::Arc;

pub fn create_routes(state: Arc<AppState>, keycloak_instance: Arc<KeycloakAuthInstance>) -> Router {
    let auth_layer: KeycloakAuthLayer<Role> = KeycloakAuthLayer::<Role>::builder()
        .instance(keycloak_instance)
        .passthrough_mode(PassthroughMode::Block)
        .persist_raw_claims(true)
        .expected_audiences(vec![state.config.audience.clone()])
        .required_roles(vec![Role::User])
        .build();

    let public_routes = Router::new().route("/api/health", get(health));

    let protected_routes = Router::new()
        .route("/api/tasks", post(create_task).get(list_tasks))
        .route("/api/tasks/{id}", delete(delete_task))
        .layer(auth_layer.clone());

    let admin_routes = Router::new()
        .route("/api/admin/users", get(list_users))
        .route("/api/admin/users/{id}", delete(delete_user))
        .layer(middleware::from_fn(admin_guard))
        .layer(auth_layer);

    Router::new()
        .merge(public_routes)
        .merge(protected_routes)
        .merge(admin_routes)
        .layer(middleware::from_fn(logging_middleware))
        .with_state(state)
}
