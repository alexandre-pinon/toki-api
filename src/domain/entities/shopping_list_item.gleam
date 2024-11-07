import birl.{type Day}
import domain/value_objects/unit_type.{type UnitType}
import domain/value_objects/unit_type_family.{type UnitTypeFamily}
import gleam/option.{type Option}
import youid/uuid.{type Uuid}

pub type ShoppingListItem {
  ShoppingListItem(
    id: Uuid,
    user_id: Uuid,
    planned_meal_id: Option(Uuid),
    name: String,
    unit: Option(UnitType),
    unit_family: Option(UnitTypeFamily),
    quantity: Option(Float),
    meal_date: Option(Day),
    checked: Bool,
  )
}
