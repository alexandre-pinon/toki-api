import application/context.{type Context, AuthContext}
import gleam/json
import gleam/option.{None, Some}
import gleam/string
import infrastructure/repositories/user_repository
import presentation/rest/encoders
import presentation/rest/middlewares
import wisp.{type Request, type Response}

pub fn profile(req: Request, ctx: Context) -> Response {
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
