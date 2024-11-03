import birl.{Day}
import domain/entities/planned_meal.{type PlannedMeal}
import domain/value_objects/db_date.{type DbDate}
import domain/value_objects/meal_type
import gleam/dynamic.{type Decoder}
import gleam/option.{type Option}
import gleam/pgo
import gleam/result
import infrastructure/decoders/common_decoder
import infrastructure/errors.{type DbError, DecodingFailed}
import youid/uuid

pub type PlannedMealRow {
  PlannedMealRow(
    id: BitArray,
    user_id: BitArray,
    recipe_id: Option(BitArray),
    meal_date: DbDate,
    meal_type: String,
    servings: Int,
  )
}

pub fn new() -> Decoder(PlannedMealRow) {
  dynamic.decode6(
    PlannedMealRow,
    dynamic.field("id", dynamic.bit_array),
    dynamic.field("user_id", dynamic.bit_array),
    dynamic.field("recipe_id", dynamic.optional(dynamic.bit_array)),
    dynamic.field("meal_date", pgo.decode_date),
    dynamic.field("meal_type", dynamic.string),
    dynamic.field("servings", dynamic.int),
  )
}

pub fn from_domain_to_db(planned_meal: PlannedMeal) -> List(pgo.Value) {
  let Day(year, month, date) = planned_meal.meal_date
  [
    pgo.text(uuid.to_string(planned_meal.id)),
    pgo.text(uuid.to_string(planned_meal.user_id)),
    pgo.nullable(pgo.text, planned_meal.recipe_id |> option.map(uuid.to_string)),
    pgo.date(#(year, month, date)),
    pgo.text(meal_type.to_string(planned_meal.meal_type)),
    pgo.int(planned_meal.servings),
  ]
}

pub fn from_db_to_domain(
  planned_meal_row: PlannedMealRow,
) -> Result(PlannedMeal, DbError) {
  let PlannedMealRow(id, user_id, recipe_id, meal_date, meal_type, servings) =
    planned_meal_row

  use id <- result.try(common_decoder.from_db_uuid_to_domain_uuid(id))
  use user_id <- result.try(common_decoder.from_db_uuid_to_domain_uuid(user_id))
  use recipe_id <- result.try(
    common_decoder.from_optional_db_uuid_to_optional_domain_uuid(recipe_id),
  )
  use meal_type <- result.try(
    meal_type.from_string(meal_type)
    |> result.replace_error(DecodingFailed("couldn't deserialize db meal_type")),
  )
  let meal_date = Day(meal_date.0, meal_date.1, meal_date.2)

  Ok(planned_meal.PlannedMeal(
    id,
    user_id,
    recipe_id,
    meal_date,
    meal_type,
    servings,
  ))
}
