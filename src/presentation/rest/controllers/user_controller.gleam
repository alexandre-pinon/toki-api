import application/context.{type Context}
import application/dto/user_application_dto.{CreateUserInput}
import application/use_cases/create_user_use_case
import domain/entities/user.{type User}
import gleam/json.{type Json}
import gleam/option.{None, Some}
import gleam/string
import infrastructure/repositories/user_repository
import presentation/rest/dto/user_rest_dto.{
  CreateUserRequest, decode_create_user_request,
}
import presentation/rest/middlewares
import wisp.{type Request, type Response}
import youid/uuid

pub fn list(ctx: Context) -> Response {
  case user_repository.find_all(ctx.pool) {
    Ok(users) ->
      json.array(users, encode_user)
      |> json.to_string_builder
      |> wisp.json_response(200)
    Error(error) -> {
      wisp.log_error(string.inspect(error))
      wisp.internal_server_error()
    }
  }
}

pub fn show(ctx: Context, id: String) -> Response {
  use user_id <- middlewares.require_uuid(id)

  case user_repository.find_by_id(ctx.pool, user_id) {
    Ok(Some(user)) ->
      encode_user(user)
      |> json.to_string_builder
      |> wisp.json_response(200)
    Ok(None) -> wisp.not_found()
    Error(error) -> {
      wisp.log_error(string.inspect(error))
      wisp.internal_server_error()
    }
  }
}

pub fn create(req: Request, ctx: Context) -> Response {
  use json <- wisp.require_json(req)

  case decode_create_user_request(json) {
    Ok(CreateUserRequest(email, name, google_id)) -> {
      let use_case_result =
        create_user_use_case.execute(
          CreateUserInput(email, name, google_id),
          ctx,
        )

      case use_case_result {
        Ok(Some(user)) ->
          encode_user(user)
          |> json.to_string_builder
          |> wisp.json_response(201)
        Ok(None) -> wisp.unprocessable_entity()
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

fn encode_user(user: User) -> Json {
  json.object([
    #("id", json.string(uuid.to_string(user.id) |> string.lowercase)),
    #("email", json.string(user.email)),
    #("name", json.string(user.name)),
    #("google_id", json.nullable(user.google_id, json.string)),
  ])
}
