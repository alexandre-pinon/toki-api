import application/context.{type Context}
import application/dto/user_application_dto.{type CreateUserInput}
import domain/entities/user.{type User}
import gleam/option.{type Option, None, Some}
import gleam/pgo.{ConstraintViolated}
import infrastructure/errors.{type DbError, ExecutionFailed}
import infrastructure/repositories/user_repository

pub type CreateUserUseCasePort =
  CreateUserInput

type CreateUserUseCaseResult =
  Option(User)

pub type CreateUserUseCaseErrors {
  InsertFailed(DbError)
}

pub fn execute(
  port: CreateUserUseCasePort,
  ctx: Context,
) -> Result(CreateUserUseCaseResult, CreateUserUseCaseErrors) {
  case user_repository.create(ctx.pool, port) {
    Ok(user) -> Ok(Some(user))
    Error(ExecutionFailed(ConstraintViolated(_, "users_email_key", _))) ->
      Ok(None)
    Error(error) -> Error(InsertFailed(error))
  }
}
