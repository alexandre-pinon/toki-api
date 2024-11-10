import application/context.{type Context, AuthContext}
import application/use_cases/login_user_use_case.{InvalidCredentials}
import application/use_cases/refresh_access_token_use_case.{
  ActiveRefreshTokenNotFound,
}
import application/use_cases/register_user_use_case
import gleam/json
import gleam/string
import infrastructure/repositories/refresh_token_repository
import presentation/rest/decoders
import presentation/rest/encoders
import presentation/rest/middlewares
import wisp.{type Request, type Response}

pub fn register(req: Request, ctx: Context) -> Response {
  use json <- wisp.require_json(req)

  case decoders.decode_password_register_request(json) {
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

  case decoders.decode_login_request(json) {
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

  case decoders.decode_google_id_token_request(json) {
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

pub fn refresh_access_token(req: Request, ctx: Context) -> Response {
  use json <- wisp.require_json(req)

  case decoders.decode_refresh_access_token_request(json) {
    Ok(decoded) ->
      case refresh_access_token_use_case.execute(decoded, ctx) {
        Ok(result) ->
          encoders.encode_auth_tokens(result.access_token, result.refresh_token)
          |> json.to_string_builder
          |> wisp.json_response(200)
        Error(ActiveRefreshTokenNotFound) -> wisp.response(401)
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
