import gleam/dynamic.{type DecodeErrors, type Dynamic}
import gleam/option.{type Option}

pub type CreateUserRequest {
  CreateUserRequest(email: String, name: String, google_id: Option(String))
}

pub fn decode_create_user_request(
  json: Dynamic,
) -> Result(CreateUserRequest, DecodeErrors) {
  let decode =
    dynamic.decode3(
      CreateUserRequest,
      dynamic.field("email", dynamic.string),
      dynamic.field("name", dynamic.string),
      dynamic.optional_field("google_id", dynamic.string),
    )
  decode(json)
}
