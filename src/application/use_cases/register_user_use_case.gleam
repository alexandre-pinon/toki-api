import application/context.{type Context}
import application/dto/user_dto.{
  type RegisterInput, type RegisterRequest, GoogleRegisterInput,
  PasswordRegisterInput,
}
import beecrypt
import domain/entities/user.{type User}
import gleam/option.{None, Some}
import gleam/pgo.{ConstraintViolated}
import gleam/result
import infrastructure/errors.{type DbError, ExecutionFailed}
import infrastructure/repositories/user_repository
import valid.{type NonEmptyList}
import youid/uuid

pub type RegisterUserUseCasePort =
  RegisterRequest

type RegisterUserUseCaseResult =
  User

pub type RegisterUserUseCaseErrors {
  ValidationFailed(NonEmptyList(String))
  InsertFailed(DbError)
  EmailAlreadyExists
  PasswordHashFailed(reason: String)
}

pub fn execute(
  port: RegisterUserUseCasePort,
  ctx: Context,
) -> Result(RegisterUserUseCaseResult, RegisterUserUseCaseErrors) {
  use validated_input <- result.try(validate_input(port))

  let user = case validated_input {
    PasswordRegisterInput(email, name, password) -> {
      user.User(
        id: uuid.v4(),
        email: email,
        name: name,
        google_id: None,
        password_hash: Some(beecrypt.hash(password)),
      )
    }
    GoogleRegisterInput(email, name, google_id) ->
      user.User(
        id: uuid.v4(),
        email: email,
        name: name,
        google_id: Some(google_id),
        password_hash: None,
      )
  }

  case user_repository.create(user, ctx.pool) {
    Ok(user) -> Ok(user)
    Error(ExecutionFailed(ConstraintViolated(_, "users_email_key", _))) ->
      Error(EmailAlreadyExists)
    Error(error) -> Error(InsertFailed(error))
  }
}

fn validate_input(
  port: RegisterUserUseCasePort,
) -> Result(RegisterInput, RegisterUserUseCaseErrors) {
  user_dto.validate_register_request(port)
  |> result.map_error(ValidationFailed)
}
