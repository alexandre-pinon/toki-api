import birl.{Day}
import domain/entities/aggregated_shopping_list_item.{
  type AggregatedShoppingListItem,
}
import domain/value_objects/day
import domain/value_objects/db_date.{type DbDate}
import domain/value_objects/unit_type
import domain/value_objects/unit_type_family
import gleam/dynamic.{type Decoder}
import gleam/list
import gleam/option.{type Option}
import gleam/pgo
import gleam/result
import infrastructure/decoders/common_decoder
import infrastructure/errors.{type DbError}

pub type AggregatedShoppingListItemRow {
  AggregatedShoppingListItemRow(
    ids: List(BitArray),
    user_id: BitArray,
    name: String,
    unit: Option(String),
    unit_family: Option(String),
    quantity: Option(Float),
    meal_date: Option(DbDate),
    week_day: Option(Int),
    checked: Bool,
  )
}

pub fn new() -> Decoder(AggregatedShoppingListItemRow) {
  dynamic.decode9(
    AggregatedShoppingListItemRow,
    dynamic.field("ids", dynamic.list(dynamic.bit_array)),
    dynamic.field("user_id", dynamic.bit_array),
    dynamic.field("name", dynamic.string),
    dynamic.field("unit", dynamic.optional(dynamic.string)),
    dynamic.field("unit_family", dynamic.optional(dynamic.string)),
    dynamic.field("quantity", dynamic.optional(dynamic.float)),
    dynamic.field("meal_date", dynamic.optional(pgo.decode_date)),
    dynamic.field("week_day", dynamic.optional(dynamic.int)),
    dynamic.field("checked", dynamic.bool),
  )
}

pub fn from_db_to_domain(
  row: AggregatedShoppingListItemRow,
) -> Result(AggregatedShoppingListItem, DbError) {
  use ids <- result.try(list.try_map(
    row.ids,
    common_decoder.from_db_uuid_to_domain_uuid,
  ))
  use user_id <- result.try(common_decoder.from_db_uuid_to_domain_uuid(
    row.user_id,
  ))
  let unit = row.unit |> option.map(unit_type.from_string)
  use unit_family <- result.try(common_decoder.parse_optional(
    row.unit_family,
    unit_type_family.from_string,
    "unit_family",
  ))
  let meal_date =
    row.meal_date
    |> option.map(fn(db_date) { Day(db_date.0, db_date.1, db_date.2) })
  use week_day <- result.try(common_decoder.parse_optional(
    row.week_day,
    day.weekday_from_int,
    "week_day",
  ))

  Ok(aggregated_shopping_list_item.AggregatedShoppingListItem(
    ids: ids,
    user_id: user_id,
    name: row.name,
    unit: unit,
    unit_family: unit_family,
    quantity: row.quantity,
    meal_date: meal_date,
    week_day: week_day,
    checked: row.checked,
  ))
}
