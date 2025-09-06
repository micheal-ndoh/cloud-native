use serde::Deserialize;

#[derive(Deserialize, Clone)]
pub struct Config {
    pub database_url: String,
    pub host: String,
    pub port: u16,
    pub keycloak_url: String,
    pub realm: String,
    pub admin_client_id: String,
    pub admin_client_secret: String,
    pub audience: String,
}

impl Config {
    pub fn init() -> Self {
        dotenv::dotenv().ok();
        
        let database_url = std::env::var("DATABASE_URL").expect("DATABASE_URL must be set");
        let host = std::env::var("APP_HOST").expect("APP_HOST must be set");
        let port = std::env::var("APP_PORT").expect("APP_PORT must be set").parse().unwrap();
        let keycloak_url = std::env::var("KEYCLOAK_URL").expect("KEYCLOAK_URL must be set");
        let realm = std::env::var("KEYCLOAK_REALM").expect("KEYCLOAK_REALM must be set");
        let admin_client_id = std::env::var("KEYCLOAK_ADMIN_CLIENT_ID").expect("KEYCLOAK_ADMIN_CLIENT_ID must be set");
        let admin_client_secret = std::env::var("KEYCLOAK_ADMIN_CLIENT_SECRET").expect("KEYCLOAK_ADMIN_CLIENT_SECRET must be set");
        let audience = std::env::var("KEYCLOAK_AUDIENCE").expect("KEYCLOAK_AUDIENCE must be set");
        
        Config {
            database_url,
            host,
            port,
            keycloak_url,
            realm,
            admin_client_id,
            admin_client_secret,
            audience,
        }
    }
}