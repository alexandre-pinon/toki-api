import domain/entities/aggregated_shopping_list_item.{
  type AggregatedShoppingListItem,
}
import gleam/list
import gleam/pgo
import gleam/result
import infrastructure/decoders/aggregated_shopping_list_item_decoder
import infrastructure/errors.{type DbError}
import infrastructure/postgres/db
import youid/uuid.{type Uuid}

pub fn find_all(
  for user_id: Uuid,
  on pool: pgo.Connection,
) -> Result(List(AggregatedShoppingListItem), DbError) {
  let query_input = [pgo.text(uuid.to_string(user_id))]

  "
    SELECT * FROM aggregated_shopping_list
    WHERE user_id = $1
    ORDER BY meal_date
    NULLS FIRST
  "
  |> db.execute(pool, query_input, aggregated_shopping_list_item_decoder.new())
  |> result.map(fn(returned) { returned.rows })
  |> result.then(list.try_map(
    _,
    aggregated_shopping_list_item_decoder.from_db_to_domain,
  ))
}
