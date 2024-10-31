import domain/value_objects/unit_type.{type UnitType}
import gleam/option.{type Option}
import youid/uuid.{type Uuid}

pub type Ingredient {
  Ingredient(
    id: Uuid,
    recipe_id: Uuid,
    name: String,
    quantity: Option(Float),
    unit: Option(UnitType),
  )
}
