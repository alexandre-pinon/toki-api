import domain/entities/recipe.{type Recipe}
import domain/entities/recipe_details.{type RecipeDetails}
import gleam/dynamic
import gleam/list
import gleam/option.{type Option, None, Some}
import gleam/pgo
import gleam/result
import infrastructure/decoders/recipe_decoder
import infrastructure/decoders/recipe_details_decoder
import infrastructure/errors.{type DbError, EntityNotFound}
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
           cuisine_type,
           rating
    FROM recipes
    WHERE user_id = $1
  "
  |> db.execute(pool, [user_id], recipe_decoder.new())
  |> result.map(fn(returned) { returned.rows })
  |> result.then(list.try_map(_, recipe_decoder.from_db_to_domain))
}

pub fn find_by_id(
  id: Uuid,
  for user_id: Uuid,
  on pool: pgo.Connection,
) -> Result(Option(Recipe), DbError) {
  let query_input = [
    pgo.text(uuid.to_string(id)),
    pgo.text(uuid.to_string(user_id)),
  ]

  use query_result <- result.try(
    "
      SELECT 
        id,
        user_id,
        title,
        prep_time,
        cook_time,
        servings,
        source_url,
        image_url,
        cuisine_type,
        rating
      FROM recipes 
      WHERE r.id = $1
      AND r.user_id = $2
    "
    |> db.execute(pool, query_input, recipe_decoder.new()),
  )

  let maybe_recipe =
    list.first(query_result.rows)
    |> option.from_result
    |> option.map(recipe_decoder.from_db_to_domain)

  case maybe_recipe {
    Some(Error(error)) -> Error(error)
    Some(Ok(recipe)) -> Ok(Some(recipe))
    None -> Ok(None)
  }
}

pub fn find_by_id_with_details(
  id: Uuid,
  for user_id: Uuid,
  on pool: pgo.Connection,
) -> Result(Option(RecipeDetails), DbError) {
  let query_input = [
    pgo.text(uuid.to_string(id)),
    pgo.text(uuid.to_string(user_id)),
  ]

  use query_result <- result.try(
    "
      WITH recipe_ingredients AS (
        SELECT recipe_id, 
          COALESCE(
            json_agg(
              json_build_object(
                'id', id,
                'recipe_id', recipe_id,
                'name', name,
                'quantity', quantity,
                'unit', unit
              )
            ) FILTER (WHERE id IS NOT NULL),
            '[]'
          ) AS ingredients
        FROM ingredients
        WHERE recipe_id = $1
        GROUP BY recipe_id
      ),
      recipe_instructions AS (
        SELECT recipe_id,
          COALESCE(
            json_agg(
              json_build_object(
                'id', id,
                'recipe_id', recipe_id,
                'step_number', step_number,
                'instruction', instruction
              )
              ORDER BY step_number
            ) FILTER (WHERE id IS NOT NULL),
            '[]'
          ) AS instructions
        FROM instructions
        WHERE recipe_id = $1
        GROUP BY recipe_id
      )

      SELECT 
        r.id,
        r.user_id,
        r.title,
        r.prep_time,
        r.cook_time,
        r.servings,
        r.source_url,
        r.image_url,
        r.cuisine_type,
        r.rating,
        COALESCE(ring.ingredients, '[]') as ingredients,
        COALESCE(rins.instructions, '[]') as instructions
      FROM recipes r
      LEFT JOIN recipe_ingredients ring ON r.id = ring.recipe_id
      LEFT JOIN recipe_instructions rins ON r.id = rins.recipe_id
      WHERE r.id = $1
      AND r.user_id = $2
    "
    |> db.execute(pool, query_input, recipe_details_decoder.new()),
  )

  let maybe_recipe_details =
    list.first(query_result.rows)
    |> option.from_result
    |> option.map(recipe_details_decoder.from_db_to_domain)

  case maybe_recipe_details {
    Some(Error(error)) -> Error(error)
    Some(Ok(recipe_details)) -> Ok(Some(recipe_details))
    None -> Ok(None)
  }
}

pub fn upsert(
  recipe: Recipe,
  on pool: pgo.Connection,
) -> Result(Recipe, DbError) {
  let query_input = recipe_decoder.from_domain_to_db(recipe)

  use query_result <- result.try(
    "
      INSERT INTO recipes (id, user_id, title, prep_time, cook_time, servings, source_url, image_url, cuisine_type, rating, created_at, updated_at)
      VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9, $10, DEFAULT, NOW())
      ON CONFLICT (id) DO UPDATE SET
        title = EXCLUDED.title,
        prep_time = EXCLUDED.prep_time,
        cook_time = EXCLUDED.cook_time,
        servings = EXCLUDED.servings,
        source_url = EXCLUDED.source_url,
        image_url = EXCLUDED.image_url,
        cuisine_type = EXCLUDED.cuisine_type,
        updated_at = NOW()
      RETURNING id, user_id, title, prep_time, cook_time, servings, source_url, image_url, cuisine_type, rating
    "
    |> db.execute(pool, query_input, recipe_decoder.new()),
  )

  list.first(query_result.rows)
  |> result.replace_error(EntityNotFound)
  |> result.then(recipe_decoder.from_db_to_domain)
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

  "DELETE FROM recipes WHERE id = $1 AND user_id = $2"
  |> db.execute(pool, query_input, dynamic.dynamic)
  |> result.map(fn(returned) { returned.count > 0 })
}
