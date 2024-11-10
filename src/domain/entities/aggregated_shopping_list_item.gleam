import birl.{type Day, type Weekday}
import domain/value_objects/unit_type.{type UnitType}
import domain/value_objects/unit_type_family.{type UnitTypeFamily}
import gleam/option.{type Option}
import youid/uuid.{type Uuid}

pub type AggregatedShoppingListItem {
  AggregatedShoppingListItem(
    ids: List(Uuid),
    user_id: Uuid,
    name: String,
    unit: Option(UnitType),
    unit_family: Option(UnitTypeFamily),
    quantity: Option(Float),
    meal_date: Option(Day),
    week_day: Option(Weekday),
    checked: Bool,
  )
}
