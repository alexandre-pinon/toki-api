import birl.{type Day}
import domain/entities/planned_meal.{
  type PlannedMeal, type PlannedMealWithRecipe,
}
import domain/value_objects/meal_type.{type MealType}
import gleam/dynamic
import gleam/list
import gleam/option.{type Option, None, Some}
import gleam/pgo
import gleam/result
import infrastructure/decoders/planned_meal_decoder
import infrastructure/errors.{type DbError, EntityNotFound}
import infrastructure/postgres/db
import youid/uuid.{type Uuid}

pub fn find_all(
  for user_id: Uuid,
  from start_date: Day,
  to end_date: Day,
  on pool: pgo.Connection,
) -> Result(List(PlannedMealWithRecipe), DbError) {
  let query_input = [
    pgo.text(uuid.to_string(user_id)),
    pgo.date(#(start_date.year, start_date.month, start_date.date)),
    pgo.date(#(end_date.year, end_date.month, end_date.date)),
  ]

  "
    SELECT pm.id, pm.user_id, pm.recipe_id, pm.meal_date, pm.meal_type, pm.servings, r.title, r.image_url
    FROM planned_meals pm
    JOIN recipes r ON r.id = pm.recipe_id
    WHERE pm.user_id = $1
    AND pm.meal_date BETWEEN $2 AND $3
  "
  |> db.execute(pool, query_input, planned_meal_decoder.decode_with_recipe())
  |> result.map(fn(returned) { returned.rows })
  |> result.then(list.try_map(
    _,
    planned_meal_decoder.from_db_to_domain_with_recipe,
  ))
}

pub fn find_all_upcoming_by_recipe_id(
  by recipe_id: Uuid,
  for user_id: Uuid,
  on pool: pgo.Connection,
) -> Result(List(PlannedMeal), DbError) {
  let query_input = [
    pgo.text(uuid.to_string(recipe_id)),
    pgo.text(uuid.to_string(user_id)),
  ]

  "
    SELECT id, user_id, recipe_id, meal_date, meal_type, servings
    FROM planned_meals
    WHERE recipe_id = $1
    AND user_id = $2
    AND meal_date > NOW()
  "
  |> db.execute(pool, query_input, planned_meal_decoder.new())
  |> result.map(fn(returned) { returned.rows })
  |> result.then(list.try_map(_, planned_meal_decoder.from_db_to_domain))
}

pub fn find_by_id(
  id: Uuid,
  for user_id: Uuid,
  on pool: pgo.Connection,
) -> Result(Option(PlannedMeal), DbError) {
  let query_input = [
    pgo.text(uuid.to_string(id)),
    pgo.text(uuid.to_string(user_id)),
  ]

  use query_result <- result.try(
    "
      SELECT id, user_id, recipe_id, meal_date, meal_type, servings 
      FROM planned_meals
      WHERE id = $1
      AND user_id = $2
    "
    |> db.execute(pool, query_input, planned_meal_decoder.new()),
  )

  let maybe_user =
    list.first(query_result.rows)
    |> option.from_result
    |> option.map(planned_meal_decoder.from_db_to_domain)

  case maybe_user {
    Some(Error(error)) -> Error(error)
    Some(Ok(user)) -> Ok(Some(user))
    None -> Ok(None)
  }
}

pub fn find_by_type_and_date(
  meal_type: MealType,
  meal_date: Day,
  for user_id: Uuid,
  on pool: pgo.Connection,
) -> Result(Option(PlannedMeal), DbError) {
  let query_input = [
    pgo.text(meal_type.to_string(meal_type)),
    pgo.date(#(meal_date.year, meal_date.month, meal_date.date)),
    pgo.text(uuid.to_string(user_id)),
  ]

  use query_result <- result.try(
    "
      SELECT id, user_id, recipe_id, meal_date, meal_type, servings 
      FROM planned_meals
      WHERE meal_type = $1
      AND meal_date = $2
      AND user_id = $3
    "
    |> db.execute(pool, query_input, planned_meal_decoder.new()),
  )

  let maybe_user =
    list.first(query_result.rows)
    |> option.from_result
    |> option.map(planned_meal_decoder.from_db_to_domain)

  case maybe_user {
    Some(Error(error)) -> Error(error)
    Some(Ok(user)) -> Ok(Some(user))
    None -> Ok(None)
  }
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
        recipe_id = EXCLUDED.recipe_id,
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
