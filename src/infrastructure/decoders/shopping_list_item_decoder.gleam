import birl.{Day}
import domain/entities/shopping_list_item.{type ShoppingListItem}
import domain/value_objects/db_date.{type DbDate}
import domain/value_objects/unit_type
import domain/value_objects/unit_type_family
import gleam/dynamic.{type Decoder}
import gleam/option.{type Option}
import gleam/pgo
import gleam/result
import infrastructure/decoders/common_decoder
import infrastructure/errors.{type DbError}
import youid/uuid

pub type ShoppingListItemRow {
  ShoppingListItemRow(
    id: BitArray,
    user_id: BitArray,
    planned_meal_id: Option(BitArray),
    name: String,
    unit: Option(String),
    unit_family: Option(String),
    quantity: Option(Float),
    meal_date: Option(DbDate),
    checked: Bool,
  )
}

pub fn new() -> Decoder(ShoppingListItemRow) {
  dynamic.decode9(
    ShoppingListItemRow,
    dynamic.field("id", dynamic.bit_array),
    dynamic.field("user_id", dynamic.bit_array),
    dynamic.field("planned_meal_id", dynamic.optional(dynamic.bit_array)),
    dynamic.field("name", dynamic.string),
    dynamic.field("unit", dynamic.optional(dynamic.string)),
    dynamic.field("unit_family", dynamic.optional(dynamic.string)),
    dynamic.field("quantity", dynamic.optional(dynamic.float)),
    dynamic.field("meal_date", dynamic.optional(pgo.decode_date)),
    dynamic.field("checked", dynamic.bool),
  )
}

pub fn from_domain_to_db(
  shopping_list_item: ShoppingListItem,
) -> List(pgo.Value) {
  [
    pgo.text(uuid.to_string(shopping_list_item.id)),
    pgo.text(uuid.to_string(shopping_list_item.user_id)),
    pgo.nullable(
      pgo.text,
      shopping_list_item.planned_meal_id |> option.map(uuid.to_string),
    ),
    pgo.text(shopping_list_item.name),
    pgo.nullable(
      pgo.text,
      shopping_list_item.unit |> option.map(unit_type.to_string),
    ),
    pgo.nullable(
      pgo.text,
      shopping_list_item.unit_family |> option.map(unit_type_family.to_string),
    ),
    pgo.nullable(pgo.float, shopping_list_item.quantity),
    pgo.nullable(
      pgo.date,
      shopping_list_item.meal_date
        |> option.map(fn(day) { #(day.year, day.month, day.date) }),
    ),
    pgo.bool(shopping_list_item.checked),
  ]
}

pub fn from_db_to_domain(
  shopping_list_item_row: ShoppingListItemRow,
) -> Result(ShoppingListItem, DbError) {
  let ShoppingListItemRow(
    id,
    user_id,
    planned_meal_id,
    name,
    unit,
    unit_family,
    quantity,
    meal_date,
    checked,
  ) = shopping_list_item_row

  use id <- result.try(common_decoder.from_db_uuid_to_domain_uuid(id))
  use user_id <- result.try(common_decoder.from_db_uuid_to_domain_uuid(user_id))
  use planned_meal_id <- result.try(
    common_decoder.from_optional_db_uuid_to_optional_domain_uuid(
      planned_meal_id,
    ),
  )
  let unit = unit |> option.map(unit_type.from_string)
  use unit_family <- result.try(common_decoder.parse_optional(
    unit_family,
    unit_type_family.from_string,
    "unit_family",
  ))
  let meal_date =
    meal_date
    |> option.map(fn(db_date) { Day(db_date.0, db_date.1, db_date.2) })

  Ok(shopping_list_item.ShoppingListItem(
    id,
    user_id,
    planned_meal_id,
    name,
    unit,
    unit_family,
    quantity,
    meal_date,
    checked,
  ))
}
