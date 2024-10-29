import application/context.{type Context, AuthContext}
import application/dto/auth_dto.{
  type LoginRequest, GoogleLoginRequest, PasswordLoginRequest,
}
import application/dto/user_dto.{type RegisterRequest, PasswordRegisterRequest}
import application/use_cases/login_user_use_case.{InvalidCredentials}
import application/use_cases/register_user_use_case
import gleam/bit_array
import gleam/dynamic.{type DecodeErrors, type Dynamic}
import gleam/io
import gleam/json
import gleam/list
import gleam/result
import gleam/string
import infrastructure/repositories/refresh_token_repository
import presentation/rest/encoders
import presentation/rest/middlewares
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
        Error(register_user_use_case.ValidationFailed(error)) -> {
          wisp.log_debug(string.inspect(error))
          wisp.unprocessable_entity()
        }
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
        Ok(result) ->
          encoders.encode_auth_tokens(result.access_token, result.refresh_token)
          |> json.to_string_builder
          |> wisp.json_response(200)
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

pub fn logout(req: Request, ctx: Context) -> Response {
  use AuthContext(user_id, _) <- middlewares.require_auth(req, ctx)

  case refresh_token_repository.revoke_all_active(user_id, ctx.pool) {
    Ok(Nil) -> wisp.no_content()
    Error(error) -> {
      wisp.log_error(string.inspect(error))
      wisp.internal_server_error()
    }
  }
}

pub fn google_login(req: Request, ctx: Context) -> Response {
  use json <- wisp.require_json(req)

  case decode_google_id_token(json) {
    Ok(decoded) ->
      case login_user_use_case.execute(decoded, ctx) {
        Ok(result) ->
          encoders.encode_auth_tokens(result.access_token, result.refresh_token)
          |> json.to_string_builder
          |> wisp.json_response(200)
        Error(error) -> {
          wisp.log_error(string.inspect(error))
          wisp.internal_server_error()
        }
      }
    Error(error) -> {
      wisp.log_error(string.inspect(error))
      wisp.response(401)
    }
  }
}

fn decode_password_register_request(
  json: Dynamic,
) -> Result(RegisterRequest, DecodeErrors) {
  json
  |> dynamic.decode3(
    PasswordRegisterRequest,
    dynamic.field("email", dynamic.string),
    dynamic.field("name", dynamic.string),
    dynamic.field("password", dynamic.string),
  )
}

fn decode_login_request(json: Dynamic) -> Result(LoginRequest, DecodeErrors) {
  json
  |> dynamic.decode2(
    PasswordLoginRequest,
    dynamic.field("email", dynamic.string),
    dynamic.field("password", dynamic.string),
  )
}

fn decode_google_id_token(
  json: Dynamic,
) -> Result(LoginRequest, json.DecodeError) {
  use id_token_request <- result.try(
    json
    |> dynamic.decode1(
      IdTokenRequest,
      dynamic.field("id_token", dynamic.string),
    )
    |> result.map_error(json.UnexpectedFormat),
  )
  use jwt_payload <- result.try(
    get_jwt_payload(id_token_request.id_token)
    |> result.replace_error(json.UnexpectedByte(id_token_request.id_token)),
  )

  // TODO: validate token with jwk, iss, aud, exp
  // https://developers.google.com/identity/openid-connect/openid-connect#validatinganidtoken
  jwt_payload
  |> json.decode_bits(dynamic.decode3(
    GoogleLoginRequest,
    dynamic.field("email", dynamic.string),
    dynamic.optional_field("name", dynamic.string),
    dynamic.field("sub", dynamic.string),
  ))
}

fn get_jwt_payload(jwt: String) -> Result(BitArray, Nil) {
  jwt
  |> string.split(".")
  |> list.take(2)
  |> list.last
  |> result.then(bit_array.base64_decode)
}

type IdTokenRequest {
  IdTokenRequest(id_token: String)
}
