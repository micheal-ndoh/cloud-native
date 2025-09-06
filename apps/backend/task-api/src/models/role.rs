use std::fmt;

#[derive(Clone, Debug, PartialEq, Eq)]
pub enum Role {
    User,
    Admin,
}

impl From<String> for Role {
  fn from(s: String) -> Self {
      match s.to_lowercase().as_str() {
          "admin" => Role::Admin,
          "user" => Role::User,
          _ => Role::User,
      }
  }
}

impl fmt::Display for Role {
    fn fmt(&self, f: &mut fmt::Formatter<'_>) -> fmt::Result {
        match self {
            Role::User => write!(f, "user"),
            Role::Admin => write!(f, "admin"),
        }
    }
}


impl axum_keycloak_auth::role::Role for Role {}
