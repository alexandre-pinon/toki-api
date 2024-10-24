import application/context.{type Context}
import application/dto/user_dto.{type UserUpdateInput, type UserUpdateRequest}
import domain/entities/user.{type User}
import gleam/option.{type Option, None, Some}
import gleam/pgo.{ConstraintViolated}
import gleam/result
import infrastructure/errors.{type DbError, ExecutionFailed}
import infrastructure/repositories/user_repository
import valid.{type NonEmptyList}
import youid/uuid.{type Uuid}

pub type UpdateUserUseCasePort {
  UpdateUserUseCasePort(id: Uuid, update: UserUpdateRequest)
}

type UpdateUserUseCaseResult =
  Option(User)

pub type UpdateUserUseCaseErrors {
  ValidationFailed(NonEmptyList(String))
  InsertFailed(DbError)
}

pub fn execute(
  port: UpdateUserUseCasePort,
  ctx: Context,
) -> Result(UpdateUserUseCaseResult, UpdateUserUseCaseErrors) {
  use user_update_input <- result.try(validate_input(port))

  case user_repository.update(ctx.pool, port.id, user_update_input) {
    Ok(user) -> Ok(Some(user))
    Error(ExecutionFailed(ConstraintViolated(_, "users_email_key", _))) ->
      Ok(None)
    Error(error) -> Error(InsertFailed(error))
  }
}

fn validate_input(
  port: UpdateUserUseCasePort,
) -> Result(UserUpdateInput, UpdateUserUseCaseErrors) {
  user_dto.validate_user_update_request(port.update)
  |> result.map_error(ValidationFailed)
}
