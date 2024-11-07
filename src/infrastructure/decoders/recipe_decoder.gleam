import domain/entities/recipe.{type Recipe}
import domain/value_objects/cuisine_type
import gleam/dynamic.{type Decoder}
import gleam/option.{type Option}
import gleam/pgo
import gleam/result
import infrastructure/decoders/common_decoder
import infrastructure/errors.{type DbError}
import youid/uuid

pub type RecipeRow {
  RecipeRow(
    id: BitArray,
    user_id: BitArray,
    title: String,
    prep_time: Option(Int),
    cook_time: Option(Int),
    servings: Int,
    source_url: Option(String),
    image_url: Option(String),
    cuisine_type: Option(String),
    rating: Option(Int),
  )
}

pub fn new() -> Decoder(RecipeRow) {
  common_decoder.decode10(
    RecipeRow,
    dynamic.field("id", dynamic.bit_array),
    dynamic.field("user_id", dynamic.bit_array),
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

pub fn from_domain_to_db(recipe: Recipe) -> List(pgo.Value) {
  [
    pgo.text(uuid.to_string(recipe.id)),
    pgo.text(uuid.to_string(recipe.user_id)),
    pgo.text(recipe.title),
    pgo.nullable(pgo.int, recipe.prep_time),
    pgo.nullable(pgo.int, recipe.cook_time),
    pgo.int(recipe.servings),
    pgo.nullable(pgo.text, recipe.source_url),
    pgo.nullable(pgo.text, recipe.image_url),
    pgo.nullable(
      pgo.text,
      recipe.cuisine_type |> option.map(cuisine_type.to_string),
    ),
    pgo.nullable(pgo.int, recipe.rating),
  ]
}

pub fn from_db_to_domain(recipe_row: RecipeRow) -> Result(Recipe, DbError) {
  let RecipeRow(
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
  ) = recipe_row

  use id <- result.try(common_decoder.from_db_uuid_to_domain_uuid(id))
  use user_id <- result.try(common_decoder.from_db_uuid_to_domain_uuid(user_id))
  let cuisine_type = cuisine_type |> option.map(cuisine_type.from_string)

  Ok(recipe.Recipe(
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
  ))
}
