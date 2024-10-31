import application/context.{type Context, AuthContext}
import gleam/json
import gleam/option.{None, Some}
import gleam/string
import infrastructure/repositories/recipe_repository
import presentation/rest/encoders
import presentation/rest/middlewares
import wisp.{type Request, type Response}

pub fn list(req: Request, ctx: Context) -> Response {
  use AuthContext(user_id, _) <- middlewares.require_auth(req, ctx)

  case recipe_repository.find_all(user_id, ctx.pool) {
    Ok(recipes) ->
      json.array(recipes, encoders.encode_recipe)
      |> json.to_string_builder
      |> wisp.json_response(200)
    Error(error) -> {
      wisp.log_error(string.inspect(error))
      wisp.internal_server_error()
    }
  }
}

pub fn show(req: Request, ctx: Context, id: String) -> Response {
  use AuthContext(user_id, _) <- middlewares.require_auth(req, ctx)
  use recipe_id <- middlewares.require_uuid(id)

  case recipe_repository.find_by_id(recipe_id, user_id, ctx.pool) {
    Ok(Some(recipe_details)) ->
      encoders.encode_recipe_details(recipe_details)
      |> json.to_string_builder
      |> wisp.json_response(200)
    Ok(None) -> wisp.not_found()
    Error(error) -> {
      wisp.log_error(string.inspect(error))
      wisp.internal_server_error()
    }
  }
}
