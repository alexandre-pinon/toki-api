import application/dto/common_dto
import domain/value_objects/unit_type.{type UnitType}
import gleam/option.{type Option}
import valid.{type ValidatorResult}

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
