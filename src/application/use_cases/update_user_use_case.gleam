import application/context.{type Context}
import application/dto/user_dto.{type UserUpdateInput, type UserUpdateRequest}
import domain/entities/user.{type User}
import gleam/pgo.{ConstraintViolated}
import gleam/result
import infrastructure/errors.{type DbError, EntityNotFound, ExecutionFailed}
import infrastructure/repositories/user_repository
import valid.{type NonEmptyList}
import youid/uuid.{type Uuid}

pub type UpdateUserUseCasePort {
  UpdateUserUseCasePort(id: Uuid, update: UserUpdateRequest)
}

type UpdateUserUseCaseResult =
  User

pub type UpdateUserUseCaseErrors {
  ValidationFailed(NonEmptyList(String))
  InsertFailed(DbError)
  EmailAlreadyExists
  UserNotFound
}

pub fn execute(
  port: UpdateUserUseCasePort,
  ctx: Context,
) -> Result(UpdateUserUseCaseResult, UpdateUserUseCaseErrors) {
  use user_update_input <- result.try(validate_input(port))

  case user_repository.update(port.id, user_update_input, ctx.pool) {
    Ok(user) -> Ok(user)
    Error(ExecutionFailed(ConstraintViolated(_, "users_email_key", _))) ->
      Error(EmailAlreadyExists)
    Error(EntityNotFound) -> Error(UserNotFound)
    Error(error) -> Error(InsertFailed(error))
  }
}

fn validate_input(
  port: UpdateUserUseCasePort,
) -> Result(UserUpdateInput, UpdateUserUseCaseErrors) {
  user_dto.validate_user_update_request(port.update)
  |> result.map_error(ValidationFailed)
}
