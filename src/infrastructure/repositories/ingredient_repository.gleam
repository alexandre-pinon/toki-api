import domain/entities/ingredient.{type Ingredient}
import gleam/dynamic
import gleam/list
import gleam/pgo
import gleam/result
import gleam/string
import infrastructure/decoders/ingredient_decoder
import infrastructure/errors.{type DbError}
import infrastructure/postgres/db
import youid/uuid.{type Uuid}

pub fn find_all_by_recipe_id(
  recipe_id: Uuid,
  on pool: pgo.Connection,
) -> Result(List(Ingredient), DbError) {
  let query_input = [pgo.text(uuid.to_string(recipe_id))]

  "SELECT id, recipe_id, name, quantity, unit FROM ingredients WHERE recipe_id = $1"
  |> db.execute(pool, query_input, ingredient_decoder.new())
  |> result.map(fn(returned) { returned.rows })
  |> result.then(list.try_map(_, ingredient_decoder.from_db_to_domain))
}

pub fn bulk_create(
  ingredients: List(Ingredient),
  on pool: pgo.Connection,
) -> Result(List(Ingredient), DbError) {
  let query_input =
    ingredients
    |> list.flat_map(ingredient_decoder.from_domain_to_db)

  use query_result <- result.try(
    "INSERT INTO ingredients (id, recipe_id, name, quantity, unit, created_at, updated_at) VALUES"
    |> string.append(db.generate_values_clause(ingredients, 5))
    |> string.append("RETURNING id, recipe_id, name, quantity, unit")
    |> db.execute(pool, query_input, ingredient_decoder.new()),
  )

  query_result.rows
  |> list.try_map(ingredient_decoder.from_db_to_domain)
}

pub fn delete_recipe_ingredients(
  recipe_id: Uuid,
  on pool: pgo.Connection,
) -> Result(Bool, DbError) {
  "DELETE FROM ingredients WHERE recipe_id = $1"
  |> db.execute(pool, [pgo.text(uuid.to_string(recipe_id))], dynamic.dynamic)
  |> result.map(fn(returned) { returned.count > 0 })
}
