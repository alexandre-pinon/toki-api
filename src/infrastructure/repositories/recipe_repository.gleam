import domain/entities/recipe.{type Recipe}
import gleam/list
import gleam/pgo
import gleam/result
import infrastructure/decoders/recipe_decoder
import infrastructure/errors.{type DbError}
import infrastructure/postgres/db
import youid/uuid.{type Uuid}

pub fn find_all(
  for user_id: Uuid,
  on pool: pgo.Connection,
) -> Result(List(Recipe), DbError) {
  let user_id = pgo.text(uuid.to_string(user_id))

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
    WHERE user_id = $1
  "
  |> db.execute(pool, [user_id], recipe_decoder.new())
  |> result.map(fn(returned) { returned.rows })
  |> result.then(list.try_map(_, recipe_decoder.from_db_to_domain))
}
