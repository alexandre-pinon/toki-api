import domain/entities/ingredient.{type Ingredient}
import domain/entities/instruction.{type Instruction}
import domain/entities/planned_meal.{type PlannedMeal}
import domain/entities/recipe.{type Recipe}
import domain/entities/recipe_details.{type RecipeDetails}
import domain/entities/user.{type User}
import domain/value_objects/cuisine_type
import domain/value_objects/meal_type
import domain/value_objects/unit_type
import gleam/int
import gleam/json.{type Json}
import gleam/option
import gleam/string
import youid/uuid.{type Uuid}

fn encode_uuid(id: Uuid) -> Json {
  json.string(uuid.to_string(id) |> string.lowercase)
}

pub fn encode_user(user: User) -> Json {
  json.object([
    #("id", encode_uuid(user.id)),
    #("email", json.string(user.email)),
    #("name", json.string(user.name)),
  ])
}

pub fn encode_auth_tokens(access_token: String, refresh_token: String) -> Json {
  json.object([
    #("access_token", json.string(access_token)),
    #("refresh_token", json.string(refresh_token)),
  ])
}

pub fn encode_recipe(recipe: Recipe) -> Json {
  json.object([
    #("id", encode_uuid(recipe.id)),
    #("user_id", encode_uuid(recipe.user_id)),
    #("title", json.string(recipe.title)),
    #("prep_time", json.nullable(recipe.prep_time, json.int)),
    #("cook_time", json.nullable(recipe.cook_time, json.int)),
    #("servings", json.int(recipe.servings)),
    #("source_url", json.nullable(recipe.source_url, json.string)),
    #("image_url", json.nullable(recipe.image_url, json.string)),
    #(
      "cuisine_type",
      json.nullable(
        recipe.cuisine_type |> option.map(cuisine_type.to_string),
        json.string,
      ),
    ),
    #("rating", json.nullable(recipe.rating, json.int)),
  ])
}

pub fn encode_ingredient(ingredient: Ingredient) -> Json {
  json.object([
    #("id", encode_uuid(ingredient.id)),
    #("recipe_id", encode_uuid(ingredient.recipe_id)),
    #("name", json.string(ingredient.name)),
    #("quantity", json.nullable(ingredient.quantity, json.float)),
    #(
      "unit",
      json.nullable(
        ingredient.unit |> option.map(unit_type.to_string),
        json.string,
      ),
    ),
  ])
}

pub fn encode_instruction(instruction: Instruction) -> Json {
  json.object([
    #("id", encode_uuid(instruction.id)),
    #("recipe_id", encode_uuid(instruction.recipe_id)),
    #("step_number", json.int(instruction.step_number)),
    #("instruction", json.string(instruction.instruction)),
  ])
}

pub fn encode_recipe_details(recipe_details: RecipeDetails) -> Json {
  json.object([
    #("recipe", encode_recipe(recipe_details.recipe)),
    #("ingredients", json.array(recipe_details.ingredients, encode_ingredient)),
    #(
      "instructions",
      json.array(recipe_details.instructions, encode_instruction),
    ),
  ])
}

pub fn encode_planned_meal(planned_meal: PlannedMeal) -> Json {
  json.object([
    #("id", encode_uuid(planned_meal.id)),
    #("user_id", encode_uuid(planned_meal.user_id)),
    #("recipe_id", json.nullable(planned_meal.recipe_id, encode_uuid)),
    #(
      "meal_date",
      json.string(
        int.to_string(planned_meal.meal_date.year)
        <> "-"
        <> planned_meal.meal_date.month
        |> int.to_string
        |> string.pad_left(2, "0")
        <> "-"
        <> planned_meal.meal_date.date
        |> int.to_string
        |> string.pad_left(2, "0"),
      ),
    ),
    #("meal_type", json.string(meal_type.to_string(planned_meal.meal_type))),
    #("servings", json.int(planned_meal.servings)),
  ])
}
