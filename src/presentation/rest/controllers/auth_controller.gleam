import application/context.{type Context}
import application/dto/user_dto.{
  type LoginRequest, type RegisterRequest, PasswordRegisterRequest,
}
import application/use_cases/login_user_use_case.{InvalidCredentials}
import application/use_cases/register_user_use_case
import gleam/dynamic.{type DecodeErrors, type Dynamic}
import gleam/json
import gleam/string
import presentation/rest/encoders
import wisp.{type Request, type Response}

pub fn register(req: Request, ctx: Context) -> Response {
  use json <- wisp.require_json(req)

  case decode_password_register_request(json) {
    Ok(decoded) -> {
      case register_user_use_case.execute(decoded, ctx) {
        Ok(user) ->
          encoders.encode_user(user)
          |> json.to_string_builder
          |> wisp.json_response(201)
        Error(register_user_use_case.EmailAlreadyExists) -> wisp.response(409)
        Error(register_user_use_case.ValidationFailed(_)) ->
          wisp.unprocessable_entity()
        Error(error) -> {
          wisp.log_error(string.inspect(error))
          wisp.internal_server_error()
        }
      }
    }
    Error(error) -> {
      wisp.log_error(string.inspect(error))
      wisp.unprocessable_entity()
    }
  }
}

pub fn login(req: Request, ctx: Context) -> Response {
  use json <- wisp.require_json(req)

  case decode_login_request(json) {
    Ok(decoded) -> {
      case login_user_use_case.execute(decoded, ctx) {
        Ok(True) ->
          json.object([#("valid_credentials", json.bool(True))])
          |> json.to_string_builder
          |> wisp.json_response(200)
        Ok(False) -> wisp.response(401)
        Error(InvalidCredentials) -> wisp.response(401)
        Error(error) -> {
          wisp.log_error(string.inspect(error))
          wisp.internal_server_error()
        }
      }
    }
    Error(error) -> {
      wisp.log_error(string.inspect(error))
      wisp.unprocessable_entity()
    }
  }
}

fn decode_password_register_request(
  json: Dynamic,
) -> Result(RegisterRequest, DecodeErrors) {
  let decode =
    dynamic.decode3(
      PasswordRegisterRequest,
      dynamic.field("email", dynamic.string),
      dynamic.field("name", dynamic.string),
      dynamic.field("password", dynamic.string),
    )
  decode(json)
}

fn decode_login_request(json: Dynamic) -> Result(LoginRequest, DecodeErrors) {
  let decode =
    dynamic.decode2(
      user_dto.LoginRequest,
      dynamic.field("email", dynamic.string),
      dynamic.field("password", dynamic.string),
    )
  decode(json)
}
