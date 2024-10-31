import domain/entities/recipe_details.{type RecipeDetails}
import gleam/dynamic.{type Decoder}
import gleam/json
import gleam/list
import gleam/option.{type Option}
import gleam/result
import infrastructure/decoders/common_decoder
import infrastructure/decoders/ingredient_decoder
import infrastructure/decoders/instruction_decoder
import infrastructure/decoders/recipe_decoder.{RecipeRow}
import infrastructure/errors.{type DbError}

pub type RecipeDetailsRow {
  RecipeDetailsRow(
    id: BitArray,
    user_id: BitArray,
    title: String,
    prep_time: Option(Int),
    cook_time: Option(Int),
    servings: Option(Int),
    source_url: Option(String),
    image_url: Option(String),
    cuisine_type: Option(String),
    rating: Option(Int),
    // stringified json array
    ingredients: String,
    // stringified json array
    instructions: String,
  )
}

pub fn new() -> Decoder(RecipeDetailsRow) {
  common_decoder.decode12(
    RecipeDetailsRow,
    dynamic.field("id", dynamic.bit_array),
    dynamic.field("user_id", dynamic.bit_array),
    dynamic.field("title", dynamic.string),
    dynamic.field("prep_time", dynamic.optional(dynamic.int)),
    dynamic.field("cook_time", dynamic.optional(dynamic.int)),
    dynamic.field("servings", dynamic.optional(dynamic.int)),
    dynamic.field("source_url", dynamic.optional(dynamic.string)),
    dynamic.field("image_url", dynamic.optional(dynamic.string)),
    dynamic.field("cuisine_type", dynamic.optional(dynamic.string)),
    dynamic.field("rating", dynamic.optional(dynamic.int)),
    dynamic.field("ingredients", dynamic.string),
    dynamic.field("instructions", dynamic.string),
  )
}

pub fn from_db_to_domain(
  recipe_details_row: RecipeDetailsRow,
) -> Result(RecipeDetails, DbError) {
  let RecipeDetailsRow(
    id,
    user_id,
    title,
    prep_time,
    cook_time,
    servings,
    source_url,
    image_url,
    cuisine_type,
    rating,
    ingredients,
    instructions,
  ) = recipe_details_row

  use recipe <- result.try(
    recipe_decoder.from_db_to_domain(RecipeRow(
      id,
      user_id,
      title,
      prep_time,
      cook_time,
      servings,
      source_url,
      image_url,
      cuisine_type,
      rating,
    )),
  )
  use ingredients <- result.try(
    ingredients
    |> json.decode(dynamic.list(ingredient_decoder.from_json()))
    |> result.map_error(errors.JsonDecodingFailed)
    |> result.then(list.try_map(_, ingredient_decoder.from_json_db_to_domain)),
  )
  use instructions <- result.try(
    instructions
    |> json.decode(dynamic.list(instruction_decoder.from_json()))
    |> result.map_error(errors.JsonDecodingFailed)
    |> result.then(list.try_map(_, instruction_decoder.from_json_db_to_domain)),
  )

  Ok(recipe_details.RecipeDetails(recipe, ingredients, instructions))
}
