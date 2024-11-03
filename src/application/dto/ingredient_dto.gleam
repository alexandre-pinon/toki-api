import application/dto/common_dto
import domain/entities/ingredient.{type Ingredient}
import domain/value_objects/unit_type.{type UnitType}
import gleam/option.{type Option}
import valid.{type ValidatorResult}
import youid/uuid.{type Uuid}

pub type IngredientCreateRequest {
  IngredientCreateRequest(
    name: String,
    quantity: Option(Float),
    unit: Option(String),
  )
}

pub type IngredientCreateInput {
  IngredientCreateInput(
    name: String,
    quantity: Option(Float),
    unit: Option(UnitType),
  )
}

pub fn validate_ingredient_create_request(
  input: IngredientCreateRequest,
) -> ValidatorResult(IngredientCreateInput, String) {
  valid.build3(IngredientCreateInput)
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
  input: IngredientCreateInput,
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
