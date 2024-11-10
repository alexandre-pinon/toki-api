import application/context.{type Context, AuthContext}
import gleam/json
import gleam/string
import infrastructure/repositories/aggregated_shopping_list_item_repository
import presentation/rest/encoders
import presentation/rest/middlewares
import wisp.{type Request, type Response}

pub fn list(req: Request, ctx: Context) -> Response {
  use AuthContext(user_id, _) <- middlewares.require_auth(req, ctx)

  case aggregated_shopping_list_item_repository.find_all(user_id, ctx.pool) {
    Ok(items) ->
      json.array(items, encoders.encode_aggregated_shopping_list_item)
      |> json.to_string_builder
      |> wisp.json_response(200)
    Error(error) -> {
      wisp.log_error(string.inspect(error))
      wisp.internal_server_error()
    }
  }
}
