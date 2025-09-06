use axum::{
    extract::{Extension, Request},
    http::StatusCode,
    middleware::Next,
    response::Response,
};
use axum_keycloak_auth::decode::KeycloakToken;
use crate::models::role::Role;

pub async fn admin_guard(
    Extension(token): Extension<KeycloakToken<Role>>,
    req: Request,
    next: Next,
) -> Result<Response, (StatusCode, &'static str)> {
    if !token.roles.iter().any(|r| *r.role() == Role::Admin) {
        return Err((StatusCode::FORBIDDEN, "Admin access required"));
    }

    Ok(next.run(req).await)
}
