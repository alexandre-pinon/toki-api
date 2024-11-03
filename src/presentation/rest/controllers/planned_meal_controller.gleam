import application/context.{type Context}
import birl.{type Day}
import gleam/json
import gleam/string
import infrastructure/repositories/planned_meal_repository
import presentation/rest/encoders
import presentation/rest/middlewares
import wisp.{type Request, type Response}

pub fn list(req: Request, ctx: Context) -> Response {
  use start_date_str <- middlewares.require_query(req, "start_date")
  use end_date_str <- middlewares.require_query(req, "end_date")
  use start_date <- parse_timestamp_as_date(start_date_str)
  use end_date <- parse_timestamp_as_date(end_date_str)

  case planned_meal_repository.find_all(start_date, end_date, ctx.pool) {
    Ok(planned_meals) ->
      json.array(planned_meals, encoders.encode_planned_meal)
      |> json.to_string_builder
      |> wisp.json_response(200)
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
