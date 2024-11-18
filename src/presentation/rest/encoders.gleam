import birl
import domain/entities/aggregated_shopping_list_item.{
  type AggregatedShoppingListItem,
}

import domain/entities/ingredient.{type Ingredient}
import domain/entities/instruction.{type Instruction}
import domain/entities/planned_meal.{type PlannedMeal}
import domain/entities/recipe.{type Recipe}
import domain/entities/recipe_details.{type RecipeDetails}
import domain/entities/scraped_recipe.{
  type ScrapedIngredient, type ScrapedInstruction, type ScrapedRecipe,
}
import domain/entities/shopping_list_item.{type ShoppingListItem}
import domain/entities/user.{type User}
import domain/value_objects/cuisine_type
import domain/value_objects/day
import domain/value_objects/meal_type
import domain/value_objects/unit_type
import domain/value_objects/unit_type_family
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

pub fn encode_scraped_recipe(scraped_recipe: ScrapedRecipe) -> Json {
  json.object([
    #("title", json.nullable(scraped_recipe.title, json.string)),
    #("prep_time", json.nullable(scraped_recipe.prep_time, json.int)),
    #("cook_time", json.nullable(scraped_recipe.cook_time, json.int)),
    #("servings", json.nullable(scraped_recipe.servings, json.int)),
    #("source_url", json.nullable(scraped_recipe.source_url, json.string)),
    #("image_url", json.nullable(scraped_recipe.image_url, json.string)),
    #(
      "ingredients",
      scraped_recipe.ingredients |> json.array(encode_scraped_ingredient),
    ),
    #(
      "instructions",
      scraped_recipe.instructions |> json.array(encode_scraped_instruction),
    ),
  ])
}

fn encode_scraped_ingredient(scraped_ingredient: ScrapedIngredient) -> Json {
  json.object([
    #("name", json.string(scraped_ingredient.name)),
    #("quantity", json.nullable(scraped_ingredient.quantity, json.float)),
    #(
      "unit",
      json.nullable(
        scraped_ingredient.unit |> option.map(unit_type.to_string),
        json.string,
      ),
    ),
  ])
}

fn encode_scraped_instruction(scraped_instruction: ScrapedInstruction) -> Json {
  json.object([
    #("step_number", json.int(scraped_instruction.step_number)),
    #("instruction", json.string(scraped_instruction.instruction)),
  ])
}

pub fn encode_planned_meal(planned_meal: PlannedMeal) -> Json {
  json.object([
    #("id", encode_uuid(planned_meal.id)),
    #("user_id", encode_uuid(planned_meal.user_id)),
    #("recipe_id", json.nullable(planned_meal.recipe_id, encode_uuid)),
    #("meal_date", json.string(day.to_json_string(planned_meal.meal_date))),
    #("meal_type", json.string(meal_type.to_string(planned_meal.meal_type))),
    #("servings", json.int(planned_meal.servings)),
  ])
}

pub fn encode_shopping_list_item(item: ShoppingListItem) -> Json {
  json.object([
    #("id", encode_uuid(item.id)),
    #("user_id", encode_uuid(item.user_id)),
    #("name", json.string(item.name)),
    #(
      "unit",
      json.nullable(item.unit |> option.map(unit_type.to_string), json.string),
    ),
    #(
      "unit_family",
      json.nullable(
        item.unit_family |> option.map(unit_type_family.to_string),
        json.string,
      ),
    ),
    #("quantity", json.nullable(item.quantity, json.float)),
    #("checked", json.bool(item.checked)),
  ])
}

pub fn encode_aggregated_shopping_list_item(
  item: AggregatedShoppingListItem,
) -> Json {
  json.object([
    #("ids", json.array(item.ids, encode_uuid)),
    #("user_id", encode_uuid(item.user_id)),
    #("name", json.string(item.name)),
    #(
      "unit",
      json.nullable(item.unit |> option.map(unit_type.to_string), json.string),
    ),
    #(
      "unit_family",
      json.nullable(
        item.unit_family |> option.map(unit_type_family.to_string),
        json.string,
      ),
    ),
    #("quantity", json.nullable(item.quantity, json.float)),
    #(
      "meal_date",
      json.nullable(
        item.meal_date |> option.map(day.to_json_string),
        json.string,
      ),
    ),
    #(
      "week_day",
      json.nullable(
        item.week_day |> option.map(birl.weekday_to_string),
        json.string,
      ),
    ),
    #("checked", json.bool(item.checked)),
  ])
}
