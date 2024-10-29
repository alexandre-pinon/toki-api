import domain/entities/user.{type User}
import gleam/json.{type Json}
import gleam/string
import youid/uuid

pub fn encode_user(user: User) -> Json {
  json.object([
    #("id", json.string(uuid.to_string(user.id) |> string.lowercase)),
    #("email", json.string(user.email)),
    #("name", json.string(user.name)),
  ])
}

pub fn encode_auth_tokens(access_token: String, refresh_token: String) -> Json {
  json.object([
    #("access_token", json.string(access_token)),
    #("refresh_token", json.string(refresh_token)),
  ])
}
