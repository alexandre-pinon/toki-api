import application/context.{type Context}
import application/dto/user_dto.{type CreateUserInput, type CreateUserRequest}
import domain/entities/user.{type User}
import gleam/option.{type Option, None, Some}
import gleam/pgo.{ConstraintViolated}
import gleam/result
import infrastructure/errors.{type DbError, ExecutionFailed}
import infrastructure/repositories/user_repository
import valid.{type NonEmptyList}

pub type CreateUserUseCasePort =
  CreateUserRequest

type CreateUserUseCaseResult =
  Option(User)

pub type CreateUserUseCaseErrors {
  ValidationFailed(NonEmptyList(String))
  InsertFailed(DbError)
}

pub fn execute(
  port: CreateUserUseCasePort,
  ctx: Context,
) -> Result(CreateUserUseCaseResult, CreateUserUseCaseErrors) {
  use user_create_input <- result.try(validate_input(port))

  case user_repository.create(ctx.pool, user_create_input) {
    Ok(user) -> Ok(Some(user))
    Error(ExecutionFailed(ConstraintViolated(_, "users_email_key", _))) ->
      Ok(None)
    Error(error) -> Error(InsertFailed(error))
  }
}

fn validate_input(
  port: CreateUserUseCasePort,
) -> Result(CreateUserInput, CreateUserUseCaseErrors) {
  user_dto.validate_create_user_request(port)
  |> result.map_error(ValidationFailed)
}
