import gleam/list
import gleam/option.{type Option}
import gleam/string
import non_empty_list
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
      let validate_password =
        valid.string_is_not_empty("empty password")
        |> valid.then(valid.string_min_length(
          8,
          "password must be 8 characters min",
        ))
        |> valid.then(must_contain_number(_, "password"))
        |> valid.then(must_contain_special_char(_, "password"))

      valid.build3(PasswordRegisterInput)
      |> valid.check(email, valid.string_is_email("invalid email"))
      |> valid.check(name, valid.string_is_not_empty("empty name"))
      |> valid.check(password, validate_password)
    }
  }
}

fn must_contain_number(
  str: String,
  field: String,
) -> ValidatorResult(String, String) {
  let has_number =
    string.to_graphemes(str)
    |> list.any(string.contains("0123456789", _))

  case has_number {
    True -> Ok(str)
    False -> Error(non_empty_list.new(field <> " must contain a number", []))
  }
}

fn must_contain_special_char(
  str: String,
  field: String,
) -> ValidatorResult(String, String) {
  let has_special_char =
    string.to_graphemes(str)
    |> list.any(string.contains("!@#$%^&*()_+-=[]{}|;:,.<>?", _))

  case has_special_char {
    True -> Ok(str)
    False ->
      Error(
        non_empty_list.new(field <> " must contain a special character", []),
      )
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
