import application/context.{type AuthContext}
import application/dto/planned_meal_dto.{
  type PlannedMealUpsertInput, type PlannedMealUpsertRequest,
}
import domain/entities/ingredient.{type Ingredient}
import domain/entities/planned_meal.{type PlannedMeal}
import domain/entities/shopping_list_item
import domain/value_objects/unit_type
import gleam/int
import gleam/list
import gleam/option.{None, Some}
import gleam/pgo
import gleam/result
import infrastructure/postgres/db.{type Transactional}
import infrastructure/repositories/planned_meal_repository
import infrastructure/repositories/recipe_repository
import infrastructure/repositories/shopping_list_item_repository
import valid.{type NonEmptyList}
import youid/uuid.{type Uuid}

pub type UpsertPlannedMealUseCasePort {
  UpsertPlannedMealUseCasePort(id: Uuid, data: PlannedMealUpsertRequest)
}

type UpsertPlannedMealUseCaseResult =
  PlannedMeal

pub type UpsertPlannedMealUseCaseErrors {
  ValidationFailed(NonEmptyList(String))
  TransactionFailed(pgo.TransactionError)
}

pub fn execute(
  port: UpsertPlannedMealUseCasePort,
  auth_ctx: AuthContext,
) -> Result(UpsertPlannedMealUseCaseResult, UpsertPlannedMealUseCaseErrors) {
  use validated_input <- result.try(validate_input(port))

  pgo.transaction(
    auth_ctx.ctx.pool,
    upsert_planned_meal(
      planned_meal_id: port.id,
      with: validated_input,
      for: auth_ctx.user_id,
    ),
  )
  |> result.map_error(TransactionFailed)
}

fn validate_input(
  port: UpsertPlannedMealUseCasePort,
) -> Result(PlannedMealUpsertInput, UpsertPlannedMealUseCaseErrors) {
  planned_meal_dto.validate_planned_meal_upsert_request(port.data)
  |> result.map_error(ValidationFailed)
}

fn upsert_planned_meal(
  planned_meal_id id: Uuid,
  with input: PlannedMealUpsertInput,
  for user_id: Uuid,
) -> Transactional(Result(PlannedMeal, String)) {
  fn(transaction: pgo.Connection) {
    use planned_meal <- result.try(
      planned_meal_repository.upsert(
        planned_meal.PlannedMeal(
          ..planned_meal_dto.to_entity(input, user_id),
          id: id,
        ),
        transaction,
      )
      |> result.replace_error("upsert planned meal failed"),
    )

    case planned_meal.recipe_id {
      Some(recipe_id) ->
        upsert_shopping_list_items(
          for: planned_meal,
          with: recipe_id,
          on: transaction,
        )
      None -> Ok(planned_meal)
    }
  }
}

fn upsert_shopping_list_items(
  for planned_meal: PlannedMeal,
  with recipe_id: Uuid,
  on transaction: pgo.Connection,
) -> Result(PlannedMeal, String) {
  use _ <- result.try(
    shopping_list_item_repository.delete_meal_items(
      planned_meal.id,
      planned_meal.user_id,
      transaction,
    )
    |> result.replace_error("delete meal shopping list items failed"),
  )

  use recipe_details <- result.try(
    recipe_repository.find_by_id(recipe_id, planned_meal.user_id, transaction)
    |> result.replace_error("find recipe failed")
    |> result.then(option.to_result(_, "recipe not found")),
  )

  let quantity_coeff =
    int.to_float(planned_meal.servings)
    /. int.to_float(recipe_details.recipe.servings)
  let to_adjusted_quantity = fn(quantity: Float) { quantity *. quantity_coeff }

  let to_shopping_list_item = fn(ingredient: Ingredient) {
    shopping_list_item.ShoppingListItem(
      id: uuid.v4(),
      user_id: planned_meal.user_id,
      planned_meal_id: Some(planned_meal.id),
      name: ingredient.name,
      unit: ingredient.unit,
      unit_family: ingredient.unit |> option.map(unit_type.to_family),
      quantity: ingredient.quantity |> option.map(to_adjusted_quantity),
      meal_date: Some(planned_meal.meal_date),
      checked: False,
    )
  }

  recipe_details.ingredients
  |> list.map(to_shopping_list_item)
  |> shopping_list_item_repository.bulk_insert(transaction)
  |> result.replace_error("bulk insert meal shopping list items failed")
  |> result.replace(planned_meal)
}
