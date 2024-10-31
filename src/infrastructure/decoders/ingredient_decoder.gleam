import domain/entities/ingredient.{type Ingredient}
import domain/value_objects/unit_type
import gleam/dynamic.{type Decoder}
import gleam/option.{type Option}
import gleam/pgo
import gleam/result
import infrastructure/decoders/common_decoder
import infrastructure/errors.{type DbError}
import youid/uuid

pub type IngredientRow {
  IngredientRow(
    id: BitArray,
    recipe_id: BitArray,
    name: String,
    quantity: Option(Float),
    unit: Option(String),
  )
}

pub type IngredientJsonRow {
  IngredientJsonRow(
    id: String,
    recipe_id: String,
    name: String,
    quantity: Option(Float),
    unit: Option(String),
  )
}

pub fn new() -> Decoder(IngredientRow) {
  dynamic.decode5(
    IngredientRow,
    dynamic.field("id", dynamic.bit_array),
    dynamic.field("recipe_id", dynamic.bit_array),
    dynamic.field("name", dynamic.string),
    dynamic.field("quantity", dynamic.optional(dynamic.float)),
    dynamic.field("unit", dynamic.optional(dynamic.string)),
  )
}

pub fn from_json() -> Decoder(IngredientJsonRow) {
  dynamic.decode5(
    IngredientJsonRow,
    dynamic.field("id", dynamic.string),
    dynamic.field("recipe_id", dynamic.string),
    dynamic.field("name", dynamic.string),
    dynamic.field("quantity", dynamic.optional(dynamic.float)),
    dynamic.field("unit", dynamic.optional(dynamic.string)),
  )
}

pub fn from_domain_to_db(ingredient: Ingredient) -> List(pgo.Value) {
  [
    pgo.text(uuid.to_string(ingredient.id)),
    pgo.text(uuid.to_string(ingredient.recipe_id)),
    pgo.text(ingredient.name),
    pgo.nullable(pgo.float, ingredient.quantity),
    pgo.nullable(pgo.text, ingredient.unit |> option.map(unit_type.to_string)),
  ]
}

pub fn from_db_to_domain(
  ingredient_row: IngredientRow,
) -> Result(Ingredient, DbError) {
  let IngredientRow(id, recipe_id, name, quantity, unit) = ingredient_row

  use id <- result.try(common_decoder.from_db_uuid_to_domain_uuid(id))
  use recipe_id <- result.try(common_decoder.from_db_uuid_to_domain_uuid(
    recipe_id,
  ))
  let unit = unit |> option.map(unit_type.from_string)

  Ok(ingredient.Ingredient(id, recipe_id, name, quantity, unit))
}

pub fn from_json_db_to_domain(
  ingredient_json_row: IngredientJsonRow,
) -> Result(Ingredient, DbError) {
  let IngredientJsonRow(id, recipe_id, name, quantity, unit) =
    ingredient_json_row

  use id <- result.try(common_decoder.from_json_db_uuid_to_domain_uuid(id))
  use recipe_id <- result.try(common_decoder.from_json_db_uuid_to_domain_uuid(
    recipe_id,
  ))
  let unit = unit |> option.map(unit_type.from_string)

  Ok(ingredient.Ingredient(id, recipe_id, name, quantity, unit))
}
