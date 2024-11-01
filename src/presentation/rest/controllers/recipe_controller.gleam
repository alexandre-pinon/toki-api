import application/context.{type Context, AuthContext}
import application/dto/ingredient_dto.{type IngredientCreateRequest}
import application/dto/instruction_dto.{type InstructionCreateRequest}
import application/dto/recipe_details_dto.{type RecipeDetailsCreateRequest}
import application/dto/recipe_dto.{type RecipeCreateRequest}
import application/use_cases/upsert_recipe_use_case
import gleam/dynamic.{type DecodeErrors, type Dynamic}
import gleam/json
import gleam/option.{None, Some}
import gleam/string
import infrastructure/decoders/common_decoder
import infrastructure/repositories/recipe_repository
import presentation/rest/encoders
import presentation/rest/middlewares
import wisp.{type Request, type Response}

pub fn list(req: Request, ctx: Context) -> Response {
  use AuthContext(user_id, _) <- middlewares.require_auth(req, ctx)

  case recipe_repository.find_all(user_id, ctx.pool) {
    Ok(recipes) ->
      json.array(recipes, encoders.encode_recipe)
      |> json.to_string_builder
      |> wisp.json_response(200)
    Error(error) -> {
      wisp.log_error(string.inspect(error))
      wisp.internal_server_error()
    }
  }
}

pub fn show(req: Request, ctx: Context, id: String) -> Response {
  use AuthContext(user_id, _) <- middlewares.require_auth(req, ctx)
  use recipe_id <- middlewares.require_uuid(id)

  case recipe_repository.find_by_id(recipe_id, user_id, ctx.pool) {
    Ok(Some(recipe_details)) ->
      encoders.encode_recipe_details(recipe_details)
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
  use auth_ctx <- middlewares.require_auth(req, ctx)
  use json <- wisp.require_json(req)

  case decode_recipe_details_create_request(json) {
    Ok(decoded) -> {
      case upsert_recipe_use_case.execute(decoded, auth_ctx) {
        Ok(recipe_details) ->
          encoders.encode_recipe_details(recipe_details)
          |> json.to_string_builder
          |> wisp.json_response(201)
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

fn decode_recipe_details_create_request(
  json: Dynamic,
) -> Result(RecipeDetailsCreateRequest, DecodeErrors) {
  json
  |> dynamic.decode3(
    recipe_details_dto.RecipeDetailsCreateRequest,
    dynamic.field("recipe", decode_recipe_create_request),
    dynamic.field("ingredients", dynamic.list(decode_ingredient_create_request)),
    dynamic.field(
      "instructions",
      dynamic.list(decode_instruction_create_request),
    ),
  )
}

fn decode_recipe_create_request(
  json: Dynamic,
) -> Result(RecipeCreateRequest, DecodeErrors) {
  json
  |> dynamic.decode8(
    recipe_dto.RecipeCreateRequest,
    dynamic.field("title", dynamic.string),
    dynamic.field("prep_time", dynamic.optional(dynamic.int)),
    dynamic.field("cook_time", dynamic.optional(dynamic.int)),
    dynamic.field("servings", dynamic.optional(dynamic.int)),
    dynamic.field("source_url", dynamic.optional(dynamic.string)),
    dynamic.field("image_url", dynamic.optional(dynamic.string)),
    dynamic.field("cuisine_type", dynamic.optional(dynamic.string)),
    dynamic.field("rating", dynamic.optional(dynamic.int)),
  )
}

fn decode_ingredient_create_request(
  json: Dynamic,
) -> Result(IngredientCreateRequest, DecodeErrors) {
  json
  |> dynamic.decode3(
    ingredient_dto.IngredientCreateRequest,
    dynamic.field("name", dynamic.string),
    dynamic.field("quantity", dynamic.optional(dynamic.float)),
    dynamic.field("unit", dynamic.optional(dynamic.string)),
  )
}

fn decode_instruction_create_request(
  json: Dynamic,
) -> Result(InstructionCreateRequest, DecodeErrors) {
  json
  |> dynamic.decode2(
    instruction_dto.InstructionCreateRequest,
    dynamic.field("step_number", dynamic.int),
    dynamic.field("instruction", dynamic.string),
  )
}
