import gleam/option.{type Option}
import valid.{type ValidatorResult}

pub type LoginRequest {
  LoginRequest(email: String, password: String)
}

pub type RegisterInput {
  GoogleRegisterInput(email: String, name: String, google_id: Option(String))
  PasswordRegisterInput(email: String, name: String, password: String)
}

pub type RegisterRequest {
  GoogleRegisterRequest(email: String, name: String, google_id: Option(String))
  PasswordRegisterRequest(email: String, name: String, password: String)
}

pub fn validate_register_request(
  input: RegisterRequest,
) -> ValidatorResult(RegisterInput, String) {
  case input {
    GoogleRegisterRequest(email, name, google_id) -> {
      valid.build3(GoogleRegisterInput)
      |> valid.check(email, valid.string_is_email("invalid email"))
      |> valid.check(name, valid.string_is_not_empty("empty name"))
      |> valid.check(google_id, valid.ok())
    }
    PasswordRegisterRequest(email, name, password) -> {
      valid.build3(PasswordRegisterInput)
      |> valid.check(email, valid.string_is_email("invalid email"))
      |> valid.check(name, valid.string_is_not_empty("empty name"))
      |> valid.check(password, valid.string_is_not_empty("empty password"))
    }
  }
}

pub type UserUpdateInput {
  UserUpdateInput(
    email: Option(String),
    name: Option(String),
    google_id: Option(String),
  )
}

pub type UserUpdateRequest {
  UserUpdateRequest(
    email: Option(String),
    name: Option(String),
    google_id: Option(String),
  )
}

pub fn validate_user_update_request(
  input: UserUpdateRequest,
) -> ValidatorResult(UserUpdateInput, String) {
  valid.build3(UserUpdateInput)
  |> valid.check(
    input.email,
    valid.if_some(valid.string_is_email("invalid email")),
  )
  |> valid.check(
    input.name,
    valid.if_some(valid.string_is_not_empty("empty name")),
  )
  |> valid.check(input.google_id, valid.ok())
}
