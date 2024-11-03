import birl.{type Day}
import domain/entities/planned_meal.{type PlannedMeal}
import gleam/list
import gleam/pgo
import gleam/result
import infrastructure/decoders/planned_meal_decoder
import infrastructure/errors.{type DbError}
import infrastructure/postgres/db

pub fn find_all(
  from start_date: Day,
  to end_date: Day,
  on pool: pgo.Connection,
) -> Result(List(PlannedMeal), DbError) {
  let query_input = [
    pgo.date(#(start_date.year, start_date.month, start_date.date)),
    pgo.date(#(end_date.year, end_date.month, end_date.date)),
  ]

  "
    SELECT id, user_id, recipe_id, meal_date, meal_type, servings
    FROM planned_meals
    WHERE meal_date BETWEEN $1 AND $2
  "
  |> db.execute(pool, query_input, planned_meal_decoder.new())
  |> result.map(fn(returned) { returned.rows })
  |> result.then(list.try_map(_, planned_meal_decoder.from_db_to_domain))
}
