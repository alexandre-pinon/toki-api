import application/context.{type Context, AuthContext}
import application/use_cases/upsert_shopping_list_item_use_case.{
  UpsertShoppingListItemUseCasePort,
}
import gleam/json
import gleam/string
import infrastructure/repositories/aggregated_shopping_list_item_repository
import infrastructure/repositories/shopping_list_item_repository
import presentation/rest/decoders
import presentation/rest/encoders
import presentation/rest/middlewares
import wisp.{type Request, type Response}
import youid/uuid

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

pub fn create(req: Request, ctx: Context) -> Response {
  use auth_ctx <- middlewares.require_auth(req, ctx)
  use json <- wisp.require_json(req)

  case decoders.decode_ingredient_upsert_request(json) {
    Ok(decoded) -> {
      case
        upsert_shopping_list_item_use_case.execute(
          UpsertShoppingListItemUseCasePort(uuid.v4(), decoded),
          auth_ctx,
        )
      {
        Ok(item) ->
          encoders.encode_shopping_list_item(item)
          |> json.to_string_builder
          |> wisp.json_response(201)
        Error(upsert_shopping_list_item_use_case.ValidationFailed(error)) -> {
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

pub fn update(req: Request, ctx: Context, id: String) -> Response {
  use auth_ctx <- middlewares.require_auth(req, ctx)
  use shopping_list_item_id <- middlewares.require_uuid(id)
  use json <- wisp.require_json(req)

  case decoders.decode_ingredient_upsert_request(json) {
    Ok(decoded) -> {
      case
        upsert_shopping_list_item_use_case.execute(
          UpsertShoppingListItemUseCasePort(shopping_list_item_id, decoded),
          auth_ctx,
        )
      {
        Ok(item) ->
          encoders.encode_shopping_list_item(item)
          |> json.to_string_builder
          |> wisp.json_response(200)
        Error(upsert_shopping_list_item_use_case.ValidationFailed(error)) -> {
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

pub fn check(req: Request, ctx: Context, id: String) -> Response {
  use AuthContext(user_id, _) <- middlewares.require_auth(req, ctx)
  use shopping_list_item_id <- middlewares.require_uuid(id)

  case
    shopping_list_item_repository.check(
      shopping_list_item_id,
      user_id,
      ctx.pool,
    )
  {
    Ok(True) -> wisp.no_content()
    Ok(False) -> wisp.not_found()
    Error(error) -> {
      wisp.log_error(string.inspect(error))
      wisp.internal_server_error()
    }
  }
}

pub fn uncheck(req: Request, ctx: Context, id: String) -> Response {
  use AuthContext(user_id, _) <- middlewares.require_auth(req, ctx)
  use shopping_list_item_id <- middlewares.require_uuid(id)

  case
    shopping_list_item_repository.uncheck(
      shopping_list_item_id,
      user_id,
      ctx.pool,
    )
  {
    Ok(True) -> wisp.no_content()
    Ok(False) -> wisp.not_found()
    Error(error) -> {
      wisp.log_error(string.inspect(error))
      wisp.internal_server_error()
    }
  }
}

pub fn delete(req: Request, ctx: Context, id: String) -> Response {
  use AuthContext(user_id, _) <- middlewares.require_auth(req, ctx)
  use shopping_list_item_id <- middlewares.require_uuid(id)

  case
    shopping_list_item_repository.delete(
      shopping_list_item_id,
      user_id,
      ctx.pool,
    )
  {
    Ok(True) -> wisp.no_content()
    Ok(False) -> wisp.not_found()
    Error(error) -> {
      wisp.log_error(string.inspect(error))
      wisp.internal_server_error()
    }
  }
}
