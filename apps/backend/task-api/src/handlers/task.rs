use crate::models::{
    response::{TaskListResponse, TaskResponse},
    state::AppState,
    task::{CreateTaskSchema, Task},
    role::Role,
};
use axum::{
    extract::{Extension, Path, State},
    http::StatusCode,
    Json,
};
use serde_json::json;
use std::sync::Arc;
use tracing::{info, warn, error, debug};

#[utoipa::path(
    post,
    path = "/api/tasks",
    tag = "tasks",
    request_body = CreateTaskSchema,
    responses(
        (status = 201, description = "Task created successfully", body = TaskResponse),
        (status = 400, description = "Invalid input"),
        (status = 401, description = "Unauthorized"),
        (status = 500, description = "Internal server error")
    ),
    security(
        ("api_jwt_token" = [])
    )
)]
#[axum::debug_handler]
pub async fn create_task(
    Extension(token): Extension<axum_keycloak_auth::decode::KeycloakToken<Role>>,
    State(state): State<Arc<AppState>>,
    Json(payload): Json<CreateTaskSchema>,
) -> Result<(StatusCode, Json<serde_json::Value>), (StatusCode, Json<serde_json::Value>)> {
    let user_id_str = &token.subject;
    
    // Parse user_id string to UUID
    let user_id = uuid::Uuid::parse_str(user_id_str).map_err(|e| {
        error!(
            user_id_str = %user_id_str,
            error = %e,
            "Failed to parse user_id as UUID"
        );
        (
            StatusCode::BAD_REQUEST,
            Json(json!({
                "status": "fail",
                "error": "Invalid user ID format"
            })),
        )
    })?;
    
    debug!(
        user_id = %user_id,
        task_name = %payload.name,
        "Creating new task"
    );

    let task = sqlx::query_as::<_, Task>(
        r#"
        INSERT INTO tasks (name, description, user_id, created_at, updated_at)
        VALUES ($1, $2, $3, NOW(), NOW())
        RETURNING *
        "#,
    )
    .bind(&payload.name)
    .bind(&payload.description)
    .bind(user_id)
    .fetch_one(&state.db)
    .await
    .map_err(|e| {
        error!(
            user_id = %user_id,
            task_name = %payload.name,
            error = %e,
            "Failed to create task in database"
        );
        (
            StatusCode::INTERNAL_SERVER_ERROR,
            Json(json!({
                "status": "fail",
                "error": "Failed to create task",
                "details": e.to_string()
            })),
        )
    })?;

    info!(
        user_id = %user_id,
        task_id = %task.id,
        task_name = %task.name,
        "Task created successfully"
    );

    Ok((
        StatusCode::CREATED,
        Json(json!({
            "status": "success",
            "data": TaskResponse::from(task)
        })),
    ))
}

#[utoipa::path(
    get,
    path = "/api/tasks",
    tag = "tasks",
    responses(
        (status = 200, description = "List of tasks", body = TaskListResponse),
        (status = 401, description = "Unauthorized"),
        (status = 500, description = "Internal server error")
    ),
    security(
        ("api_jwt_token" = [])
    )
)]
pub async fn list_tasks(
    Extension(token): Extension<axum_keycloak_auth::decode::KeycloakToken<Role>>,
    State(state): State<Arc<AppState>>,
) -> Result<Json<serde_json::Value>, (StatusCode, Json<serde_json::Value>)> {
    let user_id_str = &token.subject;
    
    // Parse user_id string to UUID
    let user_id = uuid::Uuid::parse_str(user_id_str).map_err(|e| {
        error!(
            user_id_str = %user_id_str,
            error = %e,
            "Failed to parse user_id as UUID"
        );
        (
            StatusCode::BAD_REQUEST,
            Json(json!({
                "status": "fail",
                "error": "Invalid user ID format"
            })),
        )
    })?;
    
    debug!(
        user_id = %user_id,
        "Listing tasks for user"
    );

    let tasks = sqlx::query_as::<_, Task>(
        "SELECT * FROM tasks WHERE user_id = $1"
    )
    .bind(user_id)
    .fetch_all(&state.db)
    .await
    .map_err(|e| {
        error!(
            user_id = %user_id,
            error = %e,
            "Failed to fetch tasks from database"
        );
        (
            StatusCode::INTERNAL_SERVER_ERROR,
            Json(json!({
                "status": "fail",
                "error": "Failed to fetch tasks",
                "details": e.to_string()
            })),
        )
    })?;

    info!(
        user_id = %user_id,
        task_count = tasks.len(),
        "Tasks retrieved successfully"
    );

    Ok(Json(json!({
        "status": "success",
        "data": TaskListResponse::from(tasks)
    })))
}

#[utoipa::path(
    delete,
    path = "/api/tasks/{id}",
    tag = "tasks",
    params(
        ("id" = uuid::Uuid, Path, description = "Task ID")
    ),
    responses(
        (status = 204, description = "Task deleted successfully"),
        (status = 401, description = "Unauthorized"),
        (status = 404, description = "Task not found"),
        (status = 500, description = "Internal server error")
    ),
    security(
        ("api_jwt_token" = [])
    )
)]
pub async fn delete_task(
    Extension(token): Extension<axum_keycloak_auth::decode::KeycloakToken<Role>>,
    State(state): State<Arc<AppState>>,
    Path(id): Path<uuid::Uuid>,
) -> Result<StatusCode, (StatusCode, Json<serde_json::Value>)> {
    let user_id_str = &token.subject;
    
    // Parse user_id string to UUID
    let user_id = uuid::Uuid::parse_str(user_id_str).map_err(|e| {
        error!(
            user_id_str = %user_id_str,
            error = %e,
            "Failed to parse user_id as UUID"
        );
        (
            StatusCode::BAD_REQUEST,
            Json(json!({
                "status": "fail",
                "error": "Invalid user ID format"
            })),
        )
    })?;
    
    debug!(
        user_id = %user_id,
        task_id = %id,
        "Attempting to delete task"
    );

    let result = sqlx::query(
        "DELETE FROM tasks WHERE id = $1 AND user_id = $2"
    )
    .bind(id)
    .bind(user_id)
    .execute(&state.db)
    .await
    .map_err(|e| {
        error!(
            user_id = %user_id,
            task_id = %id,
            error = %e,
            "Failed to delete task from database"
        );
        (
            StatusCode::INTERNAL_SERVER_ERROR,
            Json(json!({
                "status": "fail",
                "error": "Failed to delete task",
                "details": e.to_string()
            })),
        )
    })?;

    if result.rows_affected() == 0 {
        warn!(
            user_id = %user_id,
            task_id = %id,
            "Task not found for deletion"
        );
        return Err((
            StatusCode::NOT_FOUND,
            Json(json!({
                "status": "fail",
                "error": "Task not found"
            })),
        ));
    }

    info!(
        user_id = %user_id,
        task_id = %id,
        "Task deleted successfully"
    );

    Ok(StatusCode::NO_CONTENT)
}