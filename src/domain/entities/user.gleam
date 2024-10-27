import gleam/option.{type Option}
import youid/uuid.{type Uuid}

pub type User {
  User(
    id: Uuid,
    email: String,
    name: String,
    google_id: Option(String),
    password_hash: Option(String),
  )
}
