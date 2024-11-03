import domain/entities/ingredient.{type Ingredient}
import gleam/list
import gleam/pgo
import gleam/result
import gleam/string
import infrastructure/decoders/ingredient_decoder
import infrastructure/errors.{type DbError}
import infrastructure/postgres/db

pub fn bulk_upsert(
  ingredients: List(Ingredient),
  on pool: pgo.Connection,
) -> Result(List(Ingredient), DbError) {
  let query_input =
    ingredients
    |> list.flat_map(ingredient_decoder.from_domain_to_db)

  use query_result <- result.try(
    "INSERT INTO ingredients (id, recipe_id, name, quantity, unit, created_at, updated_at) VALUES"
    |> string.append(db.generate_values_clause(ingredients, 5))
    |> string.append(
      "
        ON CONFLICT (id) DO UPDATE SET
          name = EXCLUDED.name,
          quantity = EXCLUDED.quantity,
          unit = EXCLUDED.unit,
          updated_at = NOW()
        RETURNING id, recipe_id, name, quantity, unit
      ",
    )
    |> db.execute(pool, query_input, ingredient_decoder.new()),
  )

  query_result.rows
  |> list.try_map(ingredient_decoder.from_db_to_domain)
}
