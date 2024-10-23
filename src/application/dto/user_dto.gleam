import gleam/option.{type Option}
import valid.{type ValidatorResult}

pub type UserCreateInput {
  UserCreateInput(email: String, name: String, google_id: Option(String))
}

pub type UserCreateRequest {
  UserCreateRequest(email: String, name: String, google_id: Option(String))
}

pub fn validate_user_create_request(
  input: UserCreateRequest,
) -> ValidatorResult(UserCreateInput, String) {
  valid.build3(UserCreateInput)
  |> valid.check(input.email, valid.string_is_email("invalid email"))
  |> valid.check(input.name, valid.string_is_not_empty("empty name"))
  |> valid.check(input.google_id, valid.ok())
}
