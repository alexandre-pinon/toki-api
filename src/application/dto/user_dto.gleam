import gleam/option.{type Option}
import valid.{type ValidatorResult}

pub type CreateUserInput {
  CreateUserInput(email: String, name: String, google_id: Option(String))
}

pub type CreateUserRequest {
  CreateUserRequest(email: String, name: String, google_id: Option(String))
}

pub fn validate_create_user_request(
  input: CreateUserRequest,
) -> ValidatorResult(CreateUserInput, String) {
  valid.build3(CreateUserInput)
  |> valid.check(input.email, valid.string_is_email("invalid email"))
  |> valid.check(input.name, valid.string_is_not_empty("empty name"))
  |> valid.check(input.google_id, valid.ok())
}
