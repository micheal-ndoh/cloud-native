use chrono::{DateTime, Utc};
use serde::Serialize;
use uuid::Uuid;
use utoipa::{ToSchema, schema};

use crate::models::task::Task;

#[derive(Serialize, ToSchema)]
pub struct UserResponse {
    pub id: Uuid,
    pub name: String,
    pub email: String,
    pub role: String,
    pub verified: bool,
    #[serde(rename = "createdAt")]
    #[schema(value_type = Option<String>, format = DateTime)]
    pub created_at: Option<DateTime<Utc>>,
    #[serde(rename = "updatedAt")]
    #[schema(value_type = Option<String>, format = DateTime)]
    pub updated_at: Option<DateTime<Utc>>,
}

#[derive(Serialize, ToSchema)]
pub struct TaskResponse {
    pub id: Uuid,
    pub name: String,
    pub user_id: Uuid,
    pub description: Option<String>,
    #[serde(rename = "createdAt")]
    #[schema(value_type = String, format = DateTime)]
    pub created_at: DateTime<Utc>,
    #[serde(rename = "updatedAt")]
    #[schema(value_type = String, format = DateTime)]
    pub updated_at: DateTime<Utc>,
}


#[derive(Serialize, ToSchema)]
pub struct TaskListResponse {
    pub tasks: Vec<TaskResponse>,
    pub total: usize
}


impl From<Task> for TaskResponse {
  fn from(task: Task) -> Self {
      TaskResponse {
          id: task.id,
          name: task.name,
          user_id: task.user_id,
          description: task.description,
          created_at: task.created_at,
          updated_at: task.updated_at,
      }
  }
}

impl From<Vec<Task>> for TaskListResponse {
  fn from(tasks: Vec<Task>) -> Self {
      let task_responses: Vec<TaskResponse> = tasks.into_iter().map(TaskResponse::from).collect();
      TaskListResponse {
          total: task_responses.len(),
          tasks: task_responses,
      }
  }
}