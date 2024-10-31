import domain/entities/recipe.{type Recipe}
import gleam/list
import gleam/pgo
import gleam/result
import infrastructure/decoders/recipe_decoder
import infrastructure/errors.{type DbError}
import infrastructure/postgres/db

pub fn find_all(on pool: pgo.Connection) -> Result(List(Recipe), DbError) {
  "
    SELECT id,
           user_id,
           title,
           prep_time,
           cook_time,
           servings,
           source_url,
           image_url,
           cuisine_type
    FROM recipes
  "
  |> db.execute(pool, [], recipe_decoder.new())
  |> result.map(fn(returned) { returned.rows })
  |> result.then(list.try_map(_, recipe_decoder.from_db_to_domain))
}
