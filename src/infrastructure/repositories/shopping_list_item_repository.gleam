import domain/entities/shopping_list_item.{type ShoppingListItem}
import gleam/dynamic
import gleam/list
import gleam/pgo
import gleam/result
import gleam/string
import infrastructure/decoders/shopping_list_item_decoder
import infrastructure/errors.{type DbError}
import infrastructure/postgres/db
import youid/uuid.{type Uuid}

pub fn bulk_insert(
  shopping_list_items: List(ShoppingListItem),
  on pool: pgo.Connection,
) -> Result(List(ShoppingListItem), DbError) {
  let query_input =
    shopping_list_items
    |> list.flat_map(shopping_list_item_decoder.from_domain_to_db)

  use query_result <- result.try(
    "INSERT INTO shopping_list_items (id, user_id, planned_meal_id, name, unit, unit_family, quantity, meal_date, checked, created_at, updated_at) VALUES"
    |> string.append(db.generate_values_clause(shopping_list_items, 9))
    |> string.append(
      "RETURNING id, user_id, planned_meal_id, name, unit, unit_family, quantity, meal_date, checked",
    )
    |> db.execute(pool, query_input, shopping_list_item_decoder.new()),
  )

  query_result.rows
  |> list.try_map(shopping_list_item_decoder.from_db_to_domain)
}

pub fn delete_meal_items(
  planned_meal_id: Uuid,
  for user_id: Uuid,
  on pool: pgo.Connection,
) -> Result(Bool, DbError) {
  let query_input = [
    pgo.text(uuid.to_string(planned_meal_id)),
    pgo.text(uuid.to_string(user_id)),
  ]

  "DELETE FROM shopping_list_items WHERE planned_meal_id = $1 AND user_id = $2"
  |> db.execute(pool, query_input, dynamic.dynamic)
  |> result.map(fn(returned) { returned.count > 0 })
}
