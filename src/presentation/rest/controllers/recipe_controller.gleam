import application/context.{type Context}
import gleam/json
import gleam/string
import infrastructure/repositories/recipe_repository
import presentation/rest/encoders
import wisp.{type Response}

pub fn list(ctx: Context) -> Response {
  case recipe_repository.find_all(ctx.pool) {
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
