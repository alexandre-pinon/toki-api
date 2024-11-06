import application/dto/common_dto
import domain/entities/ingredient.{type Ingredient}
import domain/value_objects/unit_type.{type UnitType}
import gleam/option.{type Option}
import valid.{type ValidatorResult}
import youid/uuid.{type Uuid}

pub type IngredientUpsertRequest {
  IngredientUpsertRequest(
    name: String,
    quantity: Option(Float),
    unit: Option(String),
  )
}

pub type IngredientUpsertInput {
  IngredientUpsertInput(
    name: String,
    quantity: Option(Float),
    unit: Option(UnitType),
  )
}

pub fn validate_ingredient_upsert_request(
  input: IngredientUpsertRequest,
) -> ValidatorResult(IngredientUpsertInput, String) {
  valid.build3(IngredientUpsertInput)
  |> valid.check(input.name, valid.string_is_not_empty("empty name"))
  |> valid.check(
    input.quantity,
    valid.if_some(common_dto.float_min(0.0, "negative quantity")),
  )
  |> valid.check(
    input.unit,
    valid.if_some(fn(input) { Ok(unit_type.from_string(input)) }),
  )
}

pub fn to_entity(
  input: IngredientUpsertInput,
  for recipe_id: Uuid,
) -> Ingredient {
  ingredient.Ingredient(
    id: uuid.v4(),
    recipe_id: recipe_id,
    name: input.name,
    quantity: input.quantity,
    unit: input.unit,
  )
}
