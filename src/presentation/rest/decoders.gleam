import application/dto/auth_dto.{type RegisterRequest, GoogleRegisterRequest}
import gleam/dynamic.{type DecodeErrors, type Dynamic}

pub fn decode_google_register_request(
  json: Dynamic,
) -> Result(RegisterRequest, DecodeErrors) {
  json
  |> dynamic.decode3(
    GoogleRegisterRequest,
    dynamic.field("email", dynamic.string),
    dynamic.field("name", dynamic.string),
    dynamic.field("google_id", dynamic.string),
  )
}
