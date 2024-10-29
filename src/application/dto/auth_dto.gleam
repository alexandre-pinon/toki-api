import gleam/option.{type Option}

pub type LoginRequest {
  PasswordLoginRequest(email: String, password: String)
  GoogleLoginRequest(email: String, name: Option(String), google_id: String)
}
