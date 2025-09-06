use sqlx::types::Uuid;
use chrono::{DateTime, Utc};
use serde::Deserialize;
use utoipa::{ToSchema, schema};

#[derive(sqlx::FromRow, ToSchema)]
pub struct Task {
    pub id: Uuid,
    pub name: String,
    pub description: Option<String>,
    pub user_id: Uuid,
    #[schema(value_type = String, format = DateTime)]
    pub created_at: DateTime<Utc>,
    #[schema(value_type = String, format = DateTime)]
    pub updated_at: DateTime<Utc>,
}

#[derive(sqlx::FromRow, Deserialize, ToSchema)]
pub struct CreateTaskSchema {
    pub name: String,
    pub description: Option<String>
}