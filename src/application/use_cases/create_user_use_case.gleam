import application/context.{type Context}
import application/dto/user_dto.{type UserCreateInput, type UserCreateRequest}
import domain/entities/user.{type User}
import gleam/pgo.{ConstraintViolated}
import gleam/result
import infrastructure/errors.{type DbError, ExecutionFailed}
import infrastructure/repositories/user_repository
import valid.{type NonEmptyList}

pub type CreateUserUseCasePort =
  UserCreateRequest

type CreateUserUseCaseResult =
  User

pub type CreateUserUseCaseErrors {
  ValidationFailed(NonEmptyList(String))
  InsertFailed(DbError)
  EmailAlreadyExists
}

pub fn execute(
  port: CreateUserUseCasePort,
  ctx: Context,
) -> Result(CreateUserUseCaseResult, CreateUserUseCaseErrors) {
  use user_create_input <- result.try(validate_input(port))

  case user_repository.create(ctx.pool, user_create_input) {
    Ok(user) -> Ok(user)
    Error(ExecutionFailed(ConstraintViolated(_, "users_email_key", _))) ->
      Error(EmailAlreadyExists)
    Error(error) -> Error(InsertFailed(error))
  }
}

fn validate_input(
  port: CreateUserUseCasePort,
) -> Result(UserCreateInput, CreateUserUseCaseErrors) {
  user_dto.validate_user_create_request(port)
  |> result.map_error(ValidationFailed)
}
