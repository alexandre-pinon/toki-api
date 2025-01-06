import app_logger
import application/context.{type AuthContext}
import application/dto/planned_meal_dto.{
  type PlannedMealUpsertInput, type PlannedMealUpsertRequest,
}
import application/use_cases/upsert_meal_shopping_list_item_use_case.{
  UpsertMealShoppingListItemsUseCasePort,
}
import birl.{type Day}
import domain/entities/planned_meal.{type PlannedMeal}
import domain/value_objects/meal_type.{type MealType}
import gleam/bool
import gleam/option.{None, Some}
import gleam/pgo
import gleam/result
import infrastructure/errors.{type DbError}
import infrastructure/repositories/planned_meal_repository
import valid.{type NonEmptyList}
import youid/uuid.{type Uuid}

pub type UpsertPlannedMealUseCasePort {
  UpsertPlannedMealUseCasePort(id: Uuid, data: PlannedMealUpsertRequest)
}

type UpsertPlannedMealUseCaseResult =
  PlannedMeal

pub type UpsertPlannedMealUseCaseErrors {
  ValidationFailed(NonEmptyList(String))
  QueryFailed(DbError)
  TransactionFailed(pgo.TransactionError)
  MealAlreadyExists(meal_date: Day, meal_type: MealType)
}

pub fn execute(
  port: UpsertPlannedMealUseCasePort,
  auth_ctx: AuthContext,
) -> Result(UpsertPlannedMealUseCaseResult, UpsertPlannedMealUseCaseErrors) {
  use validated_input <- result.try(validate_input(port))

  use maybe_existing_meal <- result.try(
    planned_meal_repository.find_by_id(
      port.id,
      auth_ctx.user_id,
      auth_ctx.ctx.pool,
    )
    |> result.map_error(QueryFailed),
  )
  use maybe_conflicting_meal <- result.try(
    planned_meal_repository.find_by_type_and_date(
      validated_input.meal_type,
      validated_input.meal_date,
      auth_ctx.user_id,
      auth_ctx.ctx.pool,
    )
    |> result.map_error(QueryFailed),
  )

  case maybe_existing_meal, maybe_conflicting_meal {
    Some(existing_meal), Some(conflicting_meal) ->
      pgo.transaction(auth_ctx.ctx.pool, fn(transaction) {
        use _ <- result.try(swap_existing_and_conflicting_meal(
          existing_meal,
          conflicting_meal,
          transaction,
        ))

        upsert_planned_meal(
          planned_meal_id: port.id,
          with: validated_input,
          given: auth_ctx,
          using: transaction,
        )
      })
      |> result.map_error(TransactionFailed)
    None, Some(conflicting_meal) ->
      Error(MealAlreadyExists(
        conflicting_meal.meal_date,
        conflicting_meal.meal_type,
      ))
    _, _ ->
      pgo.transaction(auth_ctx.ctx.pool, fn(transaction) {
        upsert_planned_meal(
          planned_meal_id: port.id,
          with: validated_input,
          given: auth_ctx,
          using: transaction,
        )
      })
      |> result.map_error(TransactionFailed)
  }
}

fn validate_input(
  port: UpsertPlannedMealUseCasePort,
) -> Result(PlannedMealUpsertInput, UpsertPlannedMealUseCaseErrors) {
  planned_meal_dto.validate_planned_meal_upsert_request(port.data)
  |> result.map_error(ValidationFailed)
}

fn swap_existing_and_conflicting_meal(
  existing_meal: PlannedMeal,
  conflicting_meal: PlannedMeal,
  transaction: pgo.Connection,
) -> Result(Nil, String) {
  // no meal to swap, skip
  use <- bool.guard(existing_meal.id == conflicting_meal.id, Ok(Nil))

  planned_meal_repository.upsert(
    planned_meal.PlannedMeal(
      ..conflicting_meal,
      meal_type: existing_meal.meal_type,
      meal_date: existing_meal.meal_date,
    ),
    transaction,
  )
  |> result.replace(Nil)
  |> result.replace_error("swap existing meal with conflicting meal failed")
}

fn upsert_planned_meal(
  planned_meal_id id: Uuid,
  with input: PlannedMealUpsertInput,
  given auth_ctx: AuthContext,
  using transaction: pgo.Connection,
) -> Result(PlannedMeal, String) {
  use planned_meal <- result.try(
    planned_meal_repository.upsert(
      planned_meal.PlannedMeal(
        ..planned_meal_dto.to_entity(input, auth_ctx.user_id),
        id: id,
      ),
      transaction,
    )
    |> result.replace_error("upsert planned meal failed"),
  )

  upsert_meal_shopping_list_item_use_case.execute(
    UpsertMealShoppingListItemsUseCasePort(planned_meal),
    context.Context(..auth_ctx.ctx, pool: transaction),
  )
  |> result.map_error(app_logger.log_error)
  |> result.replace_error("upsert meal shopping list items failed")
}
