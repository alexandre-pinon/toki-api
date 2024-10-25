import domain/entities/user.{type User}
import gleam/json.{type Json}
import gleam/string
import youid/uuid

pub fn encode_user(user: User) -> Json {
  json.object([
    #("id", json.string(uuid.to_string(user.id) |> string.lowercase)),
    #("email", json.string(user.email)),
    #("name", json.string(user.name)),
    #("google_id", json.nullable(user.google_id, json.string)),
  ])
}
