import application/context.{type Context}
import domain/entities/ingredient.{type Ingredient}
import domain/entities/planned_meal.{type PlannedMeal}
import domain/entities/shopping_list_item
import domain/value_objects/unit_type
import gleam/int
import gleam/list
import gleam/option.{Some}
import gleam/result
import infrastructure/errors.{type DbError}
import infrastructure/repositories/recipe_repository
import infrastructure/repositories/shopping_list_item_repository
import youid/uuid

pub type UpsertMealShoppingListItemsUseCasePort {
  UpsertMealShoppingListItemsUseCasePort(planned_meal: PlannedMeal)
}

type UpsertMealShoppingListItemsUseCaseResult =
  PlannedMeal

pub type UpsertMealShoppingListItemsUseCaseErrors {
  QueryFailed(DbError)
  RecipeNotFound
}

pub fn execute(
  port: UpsertMealShoppingListItemsUseCasePort,
  ctx: Context,
) -> Result(
  UpsertMealShoppingListItemsUseCaseResult,
  UpsertMealShoppingListItemsUseCaseErrors,
) {
  use _ <- result.try(
    shopping_list_item_repository.delete_meal_items(
      port.planned_meal.id,
      port.planned_meal.user_id,
      ctx.pool,
    )
    |> result.map_error(QueryFailed),
  )

  use recipe_details <- result.try(
    recipe_repository.find_by_id_with_details(
      port.planned_meal.recipe_id,
      port.planned_meal.user_id,
      ctx.pool,
    )
    |> result.map_error(QueryFailed)
    |> result.then(option.to_result(_, RecipeNotFound)),
  )

  let quantity_coeff =
    int.to_float(port.planned_meal.servings)
    /. int.to_float(recipe_details.recipe.servings)
  let to_adjusted_quantity = fn(quantity: Float) { quantity *. quantity_coeff }

  let to_shopping_list_item = fn(ingredient: Ingredient) {
    shopping_list_item.ShoppingListItem(
      id: uuid.v4(),
      user_id: port.planned_meal.user_id,
      planned_meal_id: Some(port.planned_meal.id),
      name: ingredient.name,
      unit: ingredient.unit,
      unit_family: ingredient.unit |> option.map(unit_type.to_family),
      quantity: ingredient.quantity |> option.map(to_adjusted_quantity),
      meal_date: Some(port.planned_meal.meal_date),
      checked: False,
    )
  }

  recipe_details.ingredients
  |> list.map(to_shopping_list_item)
  |> shopping_list_item_repository.bulk_create(ctx.pool)
  |> result.map_error(QueryFailed)
  |> result.replace(port.planned_meal)
}
