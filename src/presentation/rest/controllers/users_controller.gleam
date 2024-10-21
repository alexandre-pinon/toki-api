import application/context.{type Context}
import domain/entities/user.{type User}
import gleam/json.{type Json}
import gleam/option.{type Option, None, Some}
import gleam/result
import gleam/string
import infrastructure/errors.{
  type DbError, type DecoderError, DecodingFailed, InvalidUUID,
}
import infrastructure/repositories/user_repository
import wisp.{type Response}
import youid/uuid.{type Uuid}

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
  case find_user_by_id(ctx, id) {
    Ok(Some(user)) ->
      encode_user(user)
      |> json.to_string_builder
      |> wisp.json_response(200)

    Ok(None) -> wisp.not_found()

    Error(DecodingFailed(error)) ->
      json.object([#("reason", json.string(string.inspect(error)))])
      |> json.to_string_builder
      |> wisp.json_response(400)

    Error(error) -> {
      wisp.log_error(string.inspect(error))
      wisp.internal_server_error()
    }
  }
}

fn find_user_by_id(ctx: Context, id: String) -> Result(Option(User), DbError) {
  validate_id(id)
  |> result.map_error(DecodingFailed)
  |> result.then(user_repository.find_by_id(ctx.pool, _))
}

fn validate_id(id: String) -> Result(Uuid, DecoderError) {
  uuid.from_string(id)
  |> result.replace_error(InvalidUUID)
}

fn encode_user(user: User) -> Json {
  json.object([
    #("id", json.string(user.id)),
    #("email", json.string(user.email)),
    #("name", json.string(user.name)),
    #("google_id", json.nullable(user.google_id, json.string)),
  ])
}
