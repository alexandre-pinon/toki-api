import gleam/option.{type Option}
import valid.{type ValidatorResult}

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
