import application/context.{type AuthContext}
import application/dto/planned_meal_dto.{
  type PlannedMealUpsertInput, type PlannedMealUpsertRequest,
}
import domain/entities/planned_meal.{type PlannedMeal}
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
}

pub fn execute(
  port: UpsertPlannedMealUseCasePort,
  auth_ctx: AuthContext,
) -> Result(UpsertPlannedMealUseCaseResult, UpsertPlannedMealUseCaseErrors) {
  use validated_input <- result.try(validate_input(port))

  planned_meal_repository.upsert(
    planned_meal.PlannedMeal(
      ..planned_meal_dto.to_entity(validated_input, auth_ctx.user_id),
      id: port.id,
    ),
    auth_ctx.ctx.pool,
  )
  |> result.map_error(QueryFailed)
}

fn validate_input(
  port: UpsertPlannedMealUseCasePort,
) -> Result(PlannedMealUpsertInput, UpsertPlannedMealUseCaseErrors) {
  planned_meal_dto.validate_planned_meal_upsert_request(port.data)
  |> result.map_error(ValidationFailed)
}
