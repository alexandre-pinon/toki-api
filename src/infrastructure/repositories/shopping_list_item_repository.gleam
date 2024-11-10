import domain/entities/shopping_list_item.{type ShoppingListItem}
import gleam/dynamic
import gleam/list
import gleam/pgo
import gleam/result
import gleam/string
import infrastructure/decoders/shopping_list_item_decoder
import infrastructure/errors.{type DbError, EntityNotFound}
import infrastructure/postgres/db
import youid/uuid.{type Uuid}

pub fn upsert(
  item: ShoppingListItem,
  on pool: pgo.Connection,
) -> Result(ShoppingListItem, DbError) {
  let query_input = shopping_list_item_decoder.from_domain_to_db(item)

  use query_result <- result.try(
    "
      INSERT INTO shopping_list_items (id, user_id, planned_meal_id, name, unit, unit_family, quantity, meal_date, checked, created_at, updated_at)
      VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9, DEFAULT, NOW())
      ON CONFLICT (id) DO UPDATE SET 
        name = EXCLUDED.name,
        unit = EXCLUDED.unit,
        unit_family = EXCLUDED.unit_family,
        quantity = EXCLUDED.quantity,
        checked = EXCLUDED.checked,
        updated_at = NOW()
      RETURNING id, user_id, planned_meal_id, name, unit, unit_family, quantity, meal_date, checked
    "
    |> db.execute(pool, query_input, shopping_list_item_decoder.new()),
  )

  list.first(query_result.rows)
  |> result.replace_error(EntityNotFound)
  |> result.then(shopping_list_item_decoder.from_db_to_domain)
}

pub fn bulk_create(
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

pub fn check(
  id: Uuid,
  for user_id: Uuid,
  on pool: pgo.Connection,
) -> Result(Bool, DbError) {
  let query_input = [
    pgo.text(uuid.to_string(id)),
    pgo.text(uuid.to_string(user_id)),
  ]

  "
    UPDATE shopping_list_items
    SET checked = TRUE
    WHERE id = $1 AND user_id = $2
  "
  |> db.execute(pool, query_input, dynamic.dynamic)
  |> result.map(fn(returned) { returned.count > 0 })
}

pub fn uncheck(
  id: Uuid,
  for user_id: Uuid,
  on pool: pgo.Connection,
) -> Result(Bool, DbError) {
  let query_input = [
    pgo.text(uuid.to_string(id)),
    pgo.text(uuid.to_string(user_id)),
  ]

  "
    UPDATE shopping_list_items
    SET checked = FALSE
    WHERE id = $1 AND user_id = $2
  "
  |> db.execute(pool, query_input, dynamic.dynamic)
  |> result.map(fn(returned) { returned.count > 0 })
}

pub fn delete(
  id: Uuid,
  for user_id: Uuid,
  on pool: pgo.Connection,
) -> Result(Bool, DbError) {
  let query_input = [
    pgo.text(uuid.to_string(id)),
    pgo.text(uuid.to_string(user_id)),
  ]

  "DELETE FROM shopping_list_items WHERE id = $1 AND user_id = $2"
  |> db.execute(pool, query_input, dynamic.dynamic)
  |> result.map(fn(returned) { returned.count > 0 })
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
