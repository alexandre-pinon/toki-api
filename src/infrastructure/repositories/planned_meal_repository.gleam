import birl.{type Day}
import domain/entities/planned_meal.{type PlannedMeal}
import gleam/dynamic
import gleam/list
import gleam/pgo
import gleam/result
import infrastructure/decoders/planned_meal_decoder
import infrastructure/errors.{type DbError, EntityNotFound}
import infrastructure/postgres/db
import youid/uuid.{type Uuid}

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

pub fn upsert(
  planned_meal: PlannedMeal,
  on pool: pgo.Connection,
) -> Result(PlannedMeal, DbError) {
  let query_input = planned_meal_decoder.from_domain_to_db(planned_meal)

  use query_result <- result.try(
    "
      INSERT INTO planned_meals (id, user_id, recipe_id, meal_date, meal_type, servings, created_at, updated_at)
      VALUES ($1, $2, $3, $4, $5, $6, DEFAULT, NOW())
      ON CONFLICT (id) DO UPDATE SET
        meal_date = EXCLUDED.meal_date,
        meal_type = EXCLUDED.meal_type,
        servings = EXCLUDED.servings,
        updated_at = NOW()
      RETURNING id, user_id, recipe_id, meal_date, meal_type, servings
    "
    |> db.execute(pool, query_input, planned_meal_decoder.new()),
  )

  list.first(query_result.rows)
  |> result.replace_error(EntityNotFound)
  |> result.then(planned_meal_decoder.from_db_to_domain)
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

  "DELETE FROM planned_meals WHERE id = $1 AND user_id = $2"
  |> db.execute(pool, query_input, dynamic.dynamic)
  |> result.map(fn(returned) { returned.count > 0 })
}