import application/dto/auth_dto.{
  type LoginRequest, type RefreshAccessTokenRequest, type RegisterRequest,
  GoogleIdTokenRequest, GoogleLoginRequest, PasswordLoginRequest,
  PasswordRegisterRequest,
}
import gleam/option.{None, Some}

import application/dto/ingredient_dto.{type IngredientUpsertRequest}
import application/dto/instruction_dto.{type InstructionUpsertRequest}
import application/dto/planned_meal_dto.{type PlannedMealUpsertRequest}
import application/dto/recipe_details_dto.{type RecipeDetailsUpsertRequest}
import application/dto/recipe_dto.{type RecipeUpsertRequest}
import application/dto/user_dto.{type UserUpdateRequest}
import gleam/bit_array
import gleam/dynamic.{type DecodeErrors, type Dynamic}
import gleam/json
import gleam/list
import gleam/result
import gleam/string

pub fn decode_password_register_request(
  json: Dynamic,
) -> Result(RegisterRequest, DecodeErrors) {
  json
  |> dynamic.decode3(
    PasswordRegisterRequest,
    dynamic.field("email", dynamic.string),
    dynamic.field("name", dynamic.string),
    dynamic.field("password", dynamic.string),
  )
}

pub fn decode_login_request(json: Dynamic) -> Result(LoginRequest, DecodeErrors) {
  json
  |> dynamic.decode2(
    PasswordLoginRequest,
    dynamic.field("email", dynamic.string),
    dynamic.field("password", dynamic.string),
  )
}

pub fn decode_google_id_token_request(
  json: Dynamic,
) -> Result(LoginRequest, json.DecodeError) {
  use id_token_request <- result.try(
    json
    |> dynamic.decode1(
      GoogleIdTokenRequest,
      dynamic.field("id_token", dynamic.string),
    )
    |> result.map_error(json.UnexpectedFormat),
  )
  use jwt_payload <- result.try(
    get_jwt_payload(id_token_request.id_token)
    |> result.replace_error(json.UnexpectedByte(id_token_request.id_token)),
  )

  // TODO: validate token with jwk, iss, aud, exp
  // https://developers.google.com/identity/openid-connect/openid-connect#validatinganidtoken
  jwt_payload
  |> json.decode_bits(dynamic.decode3(
    GoogleLoginRequest,
    dynamic.field("email", dynamic.string),
    dynamic.optional_field("name", dynamic.string),
    dynamic.field("sub", dynamic.string),
  ))
}

fn get_jwt_payload(jwt: String) -> Result(BitArray, Nil) {
  jwt
  |> string.split(".")
  |> list.take(2)
  |> list.last
  |> result.then(bit_array.base64_decode)
}

pub fn decode_refresh_access_token_request(
  json: Dynamic,
) -> Result(RefreshAccessTokenRequest, DecodeErrors) {
  json
  |> dynamic.decode1(
    auth_dto.RefreshAccessTokenRequest,
    dynamic.field("refresh_token", dynamic.string),
  )
}

pub fn decode_user_profile_update_request(
  json: Dynamic,
) -> Result(UserUpdateRequest, DecodeErrors) {
  json
  |> dynamic.decode1(
    fn(name: String) {
      user_dto.UserUpdateRequest(email: None, name: Some(name), google_id: None)
    },
    dynamic.field("name", dynamic.string),
  )
}

pub fn decode_recipe_details_upsert_request(
  json: Dynamic,
) -> Result(RecipeDetailsUpsertRequest, DecodeErrors) {
  json
  |> dynamic.decode3(
    recipe_details_dto.RecipeDetailsUpsertRequest,
    dynamic.field("recipe", decode_recipe_upsert_request),
    dynamic.field("ingredients", dynamic.list(decode_ingredient_upsert_request)),
    dynamic.field(
      "instructions",
      dynamic.list(decode_instruction_upsert_request),
    ),
  )
}

pub fn decode_recipe_upsert_request(
  json: Dynamic,
) -> Result(RecipeUpsertRequest, DecodeErrors) {
  json
  |> dynamic.decode8(
    recipe_dto.RecipeUpsertRequest,
    dynamic.field("title", dynamic.string),
    dynamic.field("prep_time", dynamic.optional(dynamic.int)),
    dynamic.field("cook_time", dynamic.optional(dynamic.int)),
    dynamic.field("servings", dynamic.int),
    dynamic.field("source_url", dynamic.optional(dynamic.string)),
    dynamic.field("image_url", dynamic.optional(dynamic.string)),
    dynamic.field("cuisine_type", dynamic.optional(dynamic.string)),
    dynamic.field("rating", dynamic.optional(dynamic.int)),
  )
}

pub fn decode_ingredient_upsert_request(
  json: Dynamic,
) -> Result(IngredientUpsertRequest, DecodeErrors) {
  json
  |> dynamic.decode3(
    ingredient_dto.IngredientUpsertRequest,
    dynamic.field("name", dynamic.string),
    dynamic.optional_field("quantity", dynamic.float),
    dynamic.optional_field("unit", dynamic.string),
  )
}

pub fn decode_instruction_upsert_request(
  json: Dynamic,
) -> Result(InstructionUpsertRequest, DecodeErrors) {
  json
  |> dynamic.decode2(
    instruction_dto.InstructionUpsertRequest,
    dynamic.field("step_number", dynamic.int),
    dynamic.field("instruction", dynamic.string),
  )
}

pub fn decode_planned_meal_upsert_request(
  json: Dynamic,
) -> Result(PlannedMealUpsertRequest, DecodeErrors) {
  json
  |> dynamic.decode4(
    planned_meal_dto.PlannedMealUpsertRequest,
    dynamic.field("recipe_id", dynamic.string),
    dynamic.field("meal_date", dynamic.string),
    dynamic.field("meal_type", dynamic.string),
    dynamic.field("servings", dynamic.int),
  )
}
