import application/context.{type Context, AuthContext}
import application/use_cases/upsert_planned_meal_use_case.{
  UpsertPlannedMealUseCasePort,
}
import birl.{type Day}
import gleam/json
import gleam/string
import infrastructure/repositories/planned_meal_repository
import presentation/rest/decoders
import presentation/rest/encoders
import presentation/rest/middlewares
import wisp.{type Request, type Response}
import youid/uuid

pub fn list(req: Request, ctx: Context) -> Response {
  use AuthContext(user_id, _) <- middlewares.require_auth(req, ctx)
  use start_date_str <- middlewares.require_query(req, "start_date")
  use end_date_str <- middlewares.require_query(req, "end_date")
  use start_date <- parse_timestamp_as_date(start_date_str)
  use end_date <- parse_timestamp_as_date(end_date_str)

  case
    planned_meal_repository.find_all(user_id, start_date, end_date, ctx.pool)
  {
    Ok(planned_meals_with_recipe) ->
      json.array(
        planned_meals_with_recipe,
        encoders.encode_planned_meal_with_recipe,
      )
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

  case decoders.decode_planned_meal_upsert_request(json) {
    Ok(decoded) -> {
      case
        upsert_planned_meal_use_case.execute(
          UpsertPlannedMealUseCasePort(uuid.v4(), decoded),
          auth_ctx,
        )
      {
        Ok(planned_meal) ->
          encoders.encode_planned_meal(planned_meal)
          |> json.to_string_builder
          |> wisp.json_response(201)
        Error(upsert_planned_meal_use_case.ValidationFailed(error)) -> {
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
  use planned_meal_id <- middlewares.require_uuid(id)
  use json <- wisp.require_json(req)

  case decoders.decode_planned_meal_upsert_request(json) {
    Ok(decoded) -> {
      case
        upsert_planned_meal_use_case.execute(
          UpsertPlannedMealUseCasePort(planned_meal_id, decoded),
          auth_ctx,
        )
      {
        Ok(planned_meal) ->
          encoders.encode_planned_meal(planned_meal)
          |> json.to_string_builder
          |> wisp.json_response(200)
        Error(upsert_planned_meal_use_case.ValidationFailed(error)) -> {
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

pub fn delete(req: Request, ctx: Context, id: String) -> Response {
  use AuthContext(user_id, _) <- middlewares.require_auth(req, ctx)
  use planned_meal_id <- middlewares.require_uuid(id)

  case planned_meal_repository.delete(planned_meal_id, user_id, ctx.pool) {
    Ok(True) -> wisp.no_content()
    Ok(False) -> wisp.not_found()
    Error(error) -> {
      wisp.log_error(string.inspect(error))
      wisp.internal_server_error()
    }
  }
}

fn parse_timestamp_as_date(
  timestamp: String,
  next: fn(Day) -> Response,
) -> Response {
  case birl.parse(timestamp) {
    Ok(timestamp) -> next(birl.get_day(timestamp))
    Error(Nil) -> {
      wisp.log_info("Invalid timestamp: " <> timestamp)
      wisp.bad_request()
    }
  }
}
