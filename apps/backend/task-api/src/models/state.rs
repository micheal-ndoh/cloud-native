#[derive(Clone)]
pub struct AppState {
    pub db: sqlx::PgPool,
    pub config: crate::models::config::Config,
}