use crate::models::config::Config;
use crate::models::{state::AppState, response::UserResponse};
use axum::{
    extract::{Path, State},
    http::StatusCode,
    Json,
};
use chrono::{TimeZone, Utc};
use reqwest;
use serde_json::json;
use std::sync::Arc;
use tracing::{info, warn, error, debug};

async fn get_admin_token(config: &Config) -> Result<String, (StatusCode, Json<serde_json::Value>)> {
    debug!("Requesting admin token from Keycloak");
    
    let client = reqwest::Client::new();
    let url = format!(
        "{}/realms/{}/protocol/openid-connect/token",
        config.keycloak_url,
        config.realm
    );
    let mut params = std::collections::HashMap::new();
    params.insert("grant_type", "client_credentials".to_string());
    params.insert("client_id", config.admin_client_id.clone());
    params.insert("client_secret", config.admin_client_secret.clone());

    let res = client.post(&url)
        .form(&params)
        .send()
        .await
        .map_err(|e| {
            error!(error = %e, "Failed to request admin token from Keycloak");
            (
                StatusCode::INTERNAL_SERVER_ERROR,
                Json(json!({"status": "fail", "error": "Failed to get admin token", "details": e.to_string()})),
            )
        })?;

    if !res.status().is_success() {
        error!(status = %res.status(), "Invalid admin credentials for Keycloak");
        return Err((
            StatusCode::INTERNAL_SERVER_ERROR,
            Json(json!({"status": "fail", "error": "Invalid admin credentials"})),
        ));
    }

    let token_res: serde_json::Value = res.json().await.map_err(|e| (
        StatusCode::INTERNAL_SERVER_ERROR,
        Json(json!({"status": "fail", "error": "Failed to parse token", "details": e.to_string()})),
    ))?;

    token_res["access_token"]
        .as_str()
        .map(|t| t.to_string())
        .ok_or((
            StatusCode::INTERNAL_SERVER_ERROR,
            Json(json!({"status": "fail", "error": "No access token in response"})),
        ))
}

#[utoipa::path(
    get,
    path = "/api/admin/users",
    tag = "users",
    responses(
        (status = 200, description = "List of users", body = [UserResponse]),
        (status = 401, description = "Unauthorized"),
        (status = 403, description = "Forbidden"),
        (status = 500, description = "Internal server error")
    ),
    security(
        ("api_jwt_token" = [])
    )
)]
pub async fn list_users(
    State(state): State<Arc<AppState>>,
) -> Result<Json<Vec<UserResponse>>, (StatusCode, Json<serde_json::Value>)> {
    debug!("Listing users from Keycloak");
    
    let token = get_admin_token(&state.config).await?;

    let client = reqwest::Client::new();
    let url = format!(
        "{}/admin/realms/{}/users",
        state.config.keycloak_url, state.config.realm
    );

    let res = client.get(&url)
        .header("Authorization", format!("Bearer {}", token))
        .header("Accept", "application/json")
        .send()
        .await
        .map_err(|e| {
            error!(error = %e, "Failed to fetch users from Keycloak API");
            (
                StatusCode::INTERNAL_SERVER_ERROR,
                Json(json!({"status": "fail", "error": "Failed to fetch users from Keycloak", "details": e.to_string()})),
            )
        })?;

    if !res.status().is_success() {
        error!(status = %res.status(), "Keycloak API error when fetching users");
        return Err((
            StatusCode::INTERNAL_SERVER_ERROR,
            Json(json!({"status": "fail", "error": "Keycloak API error"})),
        ));
    }

    let kc_users: Vec<serde_json::Value> = res.json().await.map_err(|e| {
        error!(error = %e, "Failed to parse users JSON from Keycloak");
        (
            StatusCode::INTERNAL_SERVER_ERROR,
            Json(json!({"status": "fail", "error": "Failed to parse users", "details": e.to_string()})),
        )
    })?;

    let user_responses: Vec<UserResponse> = kc_users
        .into_iter()
        .map(|u| {
            let id_str = u["id"].as_str().unwrap_or("");
            let id = uuid::Uuid::parse_str(id_str).unwrap_or(uuid::Uuid::nil());
            let role = u["role"].to_string().into();
            let name = u["username"].as_str().unwrap_or("unknown").to_string();
            let email = u["email"].as_str().unwrap_or("").to_string();
            let created_ts = u["createdTimestamp"].as_i64().unwrap_or(0);
            let created_at = Some(Utc.timestamp_millis_opt(created_ts).unwrap());

            UserResponse {
                id,
                name,
                email,
                role,
                verified: true,
                created_at,
                updated_at: created_at,
            }
        })
        .collect();

    info!(
        user_count = user_responses.len(),
        "Users retrieved successfully from Keycloak"
    );

    Ok(Json(user_responses))
}

#[utoipa::path(
    delete,
    path = "/api/admin/users/{id}",
    tag = "users",
    params(
        ("id" = uuid::Uuid, Path, description = "User ID")
    ),
    responses(
        (status = 200, description = "User deleted successfully"),
        (status = 401, description = "Unauthorized"),
        (status = 403, description = "Forbidden"),
        (status = 404, description = "User not found"),
        (status = 500, description = "Internal server error")
    ),
    security(
        ("api_jwt_token" = [])
    )
)]
pub async fn delete_user(
    State(state): State<Arc<AppState>>,
    Path(id): Path<uuid::Uuid>,
) -> Result<Json<serde_json::Value>, (StatusCode, Json<serde_json::Value>)> {
    debug!(
        user_id = %id,
        "Attempting to delete user"
    );
    
    let token = get_admin_token(&state.config).await?;

    let client = reqwest::Client::new();
    let url = format!(
        "{}/admin/realms/{}/users/{}",
        state.config.keycloak_url, state.config.realm, id
    );

    let res = client.delete(&url)
        .header("Authorization", format!("Bearer {}", token))
        .send()
        .await
        .map_err(|e| {
            error!(
                user_id = %id,
                error = %e,
                "Failed to delete user from Keycloak API"
            );
            (
                StatusCode::INTERNAL_SERVER_ERROR,
                Json(json!({"status": "fail", "error": "Failed to delete user from Keycloak", "details": e.to_string()})),
            )
        })?;

    if res.status() == StatusCode::NOT_FOUND {
        warn!(
            user_id = %id,
            "User not found in Keycloak for deletion"
        );
        return Err((
            StatusCode::NOT_FOUND,
            Json(json!({"status": "fail", "error": "User not found in Keycloak"})),
        ));
    } else if !res.status().is_success() {
        let status = res.status();
        let text = res.text().await.unwrap_or_else(|_| "<no body>".to_string());
        error!(
            user_id = %id,
            status = %status,
            body = %text,
            "Keycloak API error when deleting user"
        );
        return Err((
            StatusCode::INTERNAL_SERVER_ERROR,
            Json(json!({"status": "fail", "error": "Keycloak API error", "details": text})),
        ));
    }    

    // Clean up tasks
    debug!(
        user_id = %id,
        "Cleaning up user tasks from database"
    );
    
    let result = sqlx::query("DELETE FROM tasks WHERE user_id = $1")
        .bind(id)
        .execute(&state.db)
        .await
        .map_err(|e| {
            error!(
                user_id = %id,
                error = %e,
                "Failed to clean up user tasks from database"
            );
            (
                StatusCode::INTERNAL_SERVER_ERROR,
                Json(json!({"status": "fail", "error": "Failed to clean up tasks", "details": e.to_string()})),
            )
        })?;

    info!(
        user_id = %id,
        tasks_deleted = result.rows_affected(),
        "User and associated tasks deleted successfully"
    );

    Ok(Json(
        json!({"status": "success", "message": format!("User {} deleted successfully", id)}),
    ))
}
