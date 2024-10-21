import gleam/option.{type Option}

pub type User {
  User(id: String, email: String, name: String, google_id: Option(String))
}
