import application/context.{type Context}
import application/dto/user_dto.{type LoginRequest}
import beecrypt
import birl
import birl/duration
import domain/entities/user.{type User}
import env.{JwtConfig}
import gjwt
import gjwt/claim
import gjwt/key
import gleam/bool
import gleam/dynamic
import gleam/option.{None, Some}
import gleam/result
import gleam/string
import infrastructure/errors.{type DbError}
import infrastructure/repositories/user_repository
import youid/uuid

pub type LoginUserUseCasePort =
  LoginRequest

pub type LoginUserUseCaseResult {
  LoginUserUseCaseResult(access_token: String)
}

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
    Ok(Some(user)) -> {
      use are_credentials_valid <- result.try(validate_user_credentials(
        user,
        port.password,
      ))

      bool.lazy_guard(
        are_credentials_valid,
        fn() { Ok(generate_access_token(user, ctx)) },
        fn() { Error(InvalidCredentials) },
      )
    }
    Ok(None) -> Error(InvalidCredentials)
    Error(db_error) -> Error(QueryFailed(db_error))
  }
}

fn validate_user_credentials(
  user: User,
  password: String,
) -> Result(Bool, LoginUserUseCaseErrors) {
  user.password_hash
  |> option.map(beecrypt.verify(password, _))
  |> option.to_result(InvalidCredentials)
}

fn generate_access_token(user: User, ctx: Context) -> LoginUserUseCaseResult {
  let JwtConfig(secret_key, expires_in) = ctx.jwt_config
  let sub = uuid.to_string(user.id) |> string.lowercase
  let exp = birl.add(birl.now(), duration.seconds(expires_in))

  gjwt.new()
  |> gjwt.add_claim(claim.issuer(ctx.app_name))
  |> gjwt.add_claim(claim.subject(sub))
  |> gjwt.add_claim(claim.expiration_time(exp))
  |> gjwt.add_claim(claim.issued_at(birl.now()))
  |> gjwt.add_claim(#("email", dynamic.from(user.email)))
  |> gjwt.sign_off(key.from_string(secret_key, "HS256"))
  |> LoginUserUseCaseResult
}
