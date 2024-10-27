import application/context.{type Context}
import application/dto/user_dto.{type LoginRequest}
import beecrypt
import domain/entities/user.{type User}
import gleam/option.{None, Some}
import infrastructure/errors.{type DbError}
import infrastructure/repositories/user_repository

pub type LoginUserUseCasePort =
  LoginRequest

type LoginUserUseCaseResult =
  Bool

pub type LoginUserUseCaseErrors {
  QueryFailed(DbError)
  InvalidCredentials
}

pub fn execute(
  port: LoginUserUseCasePort,
  ctx: Context,
) -> Result(LoginUserUseCaseResult, LoginUserUseCaseErrors) {
  let maybe_user = user_repository.find_by_email(ctx.pool, port.email)

  case maybe_user {
    Ok(Some(user)) -> validate_user_credentials(user, port.password)
    Ok(None) -> Error(InvalidCredentials)
    Error(db_error) -> Error(QueryFailed(db_error))
  }
}

fn validate_user_credentials(
  user: User,
  password: String,
) -> Result(LoginUserUseCaseResult, LoginUserUseCaseErrors) {
  user.password_hash
  |> option.map(beecrypt.verify(password, _))
  |> option.to_result(InvalidCredentials)
}
