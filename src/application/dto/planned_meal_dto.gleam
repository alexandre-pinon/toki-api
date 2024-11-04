import application/dto/common_dto
import birl.{type Day}
import domain/entities/planned_meal.{type PlannedMeal}
import domain/value_objects/meal_type.{type MealType}
import gleam/option.{Some}
import gleam/result
import non_empty_list
import valid.{type ValidatorResult}
import youid/uuid.{type Uuid}

pub type PlannedMealUpsertRequest {
  PlannedMealUpsertRequest(
    recipe_id: String,
    meal_date: String,
    meal_type: String,
    servings: Int,
  )
}

pub type PlannedMealUpsertInput {
  PlannedMealUpsertInput(
    recipe_id: Uuid,
    meal_date: Day,
    meal_type: MealType,
    servings: Int,
  )
}

pub fn validate_planned_meal_upsert_request(
  input: PlannedMealUpsertRequest,
) -> ValidatorResult(PlannedMealUpsertInput, String) {
  valid.build4(PlannedMealUpsertInput)
  |> valid.check(
    input.recipe_id,
    common_dto.string_is_uuid("invalid recipe_id"),
  )
  |> valid.check(
    input.meal_date,
    common_dto.string_is_date("invalid meal_date"),
  )
  |> valid.check(input.meal_type, fn(input) {
    meal_type.from_string(input)
    |> result.replace_error(non_empty_list.new("invalid meal_type", []))
  })
  |> valid.check(input.servings, valid.int_min(1, "servings inferior to 1"))
}

pub fn to_entity(dto: PlannedMealUpsertInput, for user_id: Uuid) -> PlannedMeal {
  planned_meal.PlannedMeal(
    id: uuid.v4(),
    user_id: user_id,
    recipe_id: Some(dto.recipe_id),
    meal_date: dto.meal_date,
    meal_type: dto.meal_type,
    servings: dto.servings,
  )
}
