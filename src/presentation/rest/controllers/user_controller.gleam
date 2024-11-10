import application/context.{type Context, AuthContext}
import application/use_cases/update_user_use_case.{UpdateUserUseCasePort}
import gleam/json
import gleam/option.{None, Some}
import gleam/string
import infrastructure/repositories/user_repository
import presentation/rest/decoders
import presentation/rest/encoders
import presentation/rest/middlewares
import wisp.{type Request, type Response}

pub fn list(ctx: Context) -> Response {
  case user_repository.find_all(ctx.pool) {
    Ok(users) ->
      json.array(users, encoders.encode_user)
      |> json.to_string_builder
      |> wisp.json_response(200)
    Error(error) -> {
      wisp.log_error(string.inspect(error))
      wisp.internal_server_error()
    }
  }
}

pub fn get_profile(req: Request, ctx: Context) -> Response {
  use AuthContext(user_id, _) <- middlewares.require_auth(req, ctx)

  case user_repository.find_by_id(user_id, ctx.pool) {
    Ok(Some(user)) ->
      encoders.encode_user(user)
      |> json.to_string_builder
      |> wisp.json_response(200)
    Ok(None) -> wisp.not_found()
    Error(error) -> {
      wisp.log_error(string.inspect(error))
      wisp.internal_server_error()
    }
  }
}

pub fn update_profile(req: Request, ctx: Context) -> Response {
  use AuthContext(user_id, _) <- middlewares.require_auth(req, ctx)
  use json <- wisp.require_json(req)

  case decoders.decode_user_profile_update_request(json) {
    Ok(decoded) -> {
      case
        update_user_use_case.execute(
          UpdateUserUseCasePort(user_id, decoded),
          ctx,
        )
      {
        Ok(user) ->
          encoders.encode_user(user)
          |> json.to_string_builder
          |> wisp.json_response(200)
        Error(update_user_use_case.UserNotFound) -> wisp.not_found()
        Error(update_user_use_case.EmailAlreadyExists) -> wisp.response(409)
        Error(update_user_use_case.ValidationFailed(_)) ->
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
