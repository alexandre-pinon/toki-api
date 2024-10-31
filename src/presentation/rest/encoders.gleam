import domain/entities/recipe.{type Recipe}
import domain/entities/user.{type User}
import domain/value_objects/cuisine_type
import gleam/json.{type Json}
import gleam/option
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

pub fn encode_recipe(recipe: Recipe) -> Json {
  json.object([
    #("id", json.string(uuid.to_string(recipe.id) |> string.lowercase)),
    #(
      "user_id",
      json.string(uuid.to_string(recipe.user_id) |> string.lowercase),
    ),
    #("title", json.string(recipe.title)),
    #("prep_time", json.nullable(recipe.prep_time, json.int)),
    #("cook_time", json.nullable(recipe.cook_time, json.int)),
    #("servings", json.nullable(recipe.servings, json.int)),
    #("source_url", json.nullable(recipe.source_url, json.string)),
    #("image_url", json.nullable(recipe.image_url, json.string)),
    #(
      "cuisine_type",
      json.nullable(
        recipe.cuisine_type |> option.map(cuisine_type.to_string),
        json.string,
      ),
    ),
  ])
}
