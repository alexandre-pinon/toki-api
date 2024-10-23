import gleam/option.{type Option}

pub type CreateUserInput {
  CreateUserInput(email: String, name: String, google_id: Option(String))
}
