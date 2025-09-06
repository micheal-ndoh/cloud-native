use axum::Json;
use serde_json::json;
use tracing::debug;

#[utoipa::path(
    get,
    path = "/api/health",
    responses(
        (status = 200, description = "App up and running", body = serde_json::Value)
    )
)]
pub async fn health() -> Json<serde_json::Value> {
    debug!("Health check requested");
    
    Json(json!({
        "status": "Active"
    }))
}
