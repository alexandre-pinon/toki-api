import application/context.{type Context}
import application/dto/user_dto.{type UserCreateRequest, type UserUpdateRequest}
import application/use_cases/create_user_use_case
import application/use_cases/update_user_use_case.{UpdateUserUseCasePort}
import domain/entities/user.{type User}
import gleam/dynamic.{type DecodeErrors, type Dynamic}
import gleam/json.{type Json}
import gleam/option.{None, Some}
import gleam/string
import infrastructure/repositories/user_repository
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

  case decode_user_create_request(json) {
    Ok(decoded) -> {
      case create_user_use_case.execute(decoded, ctx) {
        Ok(user) ->
          encode_user(user)
          |> json.to_string_builder
          |> wisp.json_response(201)
        Error(create_user_use_case.EmailAlreadyExists) -> wisp.response(409)
        Error(create_user_use_case.ValidationFailed(_)) ->
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

pub fn update(req: Request, ctx: Context, id: String) -> Response {
  use user_id <- middlewares.require_uuid(id)
  use json <- wisp.require_json(req)

  case decode_user_update_request(json) {
    Ok(decoded) -> {
      let port = UpdateUserUseCasePort(user_id, decoded)

      case update_user_use_case.execute(port, ctx) {
        Ok(user) ->
          encode_user(user)
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

pub fn delete(ctx: Context, id: String) -> Response {
  use user_id <- middlewares.require_uuid(id)

  case user_repository.delete(ctx.pool, user_id) {
    Ok(True) -> wisp.no_content()
    Ok(False) -> wisp.not_found()
    Error(error) -> {
      wisp.log_error(string.inspect(error))
      wisp.internal_server_error()
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

fn decode_user_create_request(
  json: Dynamic,
) -> Result(UserCreateRequest, DecodeErrors) {
  let decode =
    dynamic.decode3(
      user_dto.UserCreateRequest,
      dynamic.field("email", dynamic.string),
      dynamic.field("name", dynamic.string),
      dynamic.optional_field("google_id", dynamic.string),
    )
  decode(json)
}

fn decode_user_update_request(
  json: Dynamic,
) -> Result(UserUpdateRequest, DecodeErrors) {
  let decode =
    dynamic.decode3(
      user_dto.UserUpdateRequest,
      dynamic.optional_field("email", dynamic.string),
      dynamic.optional_field("name", dynamic.string),
      dynamic.optional_field("google_id", dynamic.string),
    )
  decode(json)
}
