import application/context.{type Context}
import application/dto/user_dto.{type LoginRequest}
import beecrypt
import birl
import birl/duration
import domain/entities/refresh_token.{type RefreshToken}
import domain/entities/user.{type User}
import env.{TokenConfig}
import gjwt
import gjwt/claim
import gjwt/key
import gleam/bit_array
import gleam/bool
import gleam/crypto
import gleam/dynamic
import gleam/option.{None, Some}
import gleam/result
import gleam/string
import infrastructure/errors.{type DbError}
import infrastructure/repositories/refresh_token_repository
import infrastructure/repositories/user_repository
import wisp
import youid/uuid

pub type LoginUserUseCasePort =
  LoginRequest

pub type LoginUserUseCaseResult {
  LoginUserUseCaseResult(access_token: String, refresh_token: String)
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
        fn() { generate_user_tokens(user, ctx) },
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

fn generate_user_tokens(
  user: User,
  ctx: Context,
) -> Result(LoginUserUseCaseResult, LoginUserUseCaseErrors) {
  generate_refresh_token(user, ctx)
  |> refresh_token_repository.create(ctx.pool, _)
  |> result.map_error(QueryFailed)
  |> result.map(fn(refresh_token) { refresh_token.token })
  |> result.map(LoginUserUseCaseResult(generate_access_token(user, ctx), _))
}

fn generate_refresh_token(user: User, ctx: Context) -> RefreshToken {
  let TokenConfig(_, _, refresh_token_pepper, refresh_token_expires_in) =
    ctx.token_config

  let token =
    wisp.random_string(32)
    |> string.append(refresh_token_pepper)
    |> bit_array.from_string
    |> crypto.hash(crypto.Sha256, _)
    |> bit_array.base64_encode(True)

  let exp = birl.add(birl.now(), duration.seconds(refresh_token_expires_in))

  refresh_token.RefreshToken(
    id: uuid.v4(),
    user_id: user.id,
    token: token,
    expires_at: exp,
    revoked_at: None,
  )
}

fn generate_access_token(user: User, ctx: Context) -> String {
  let TokenConfig(jwt_secret_key, jwt_expires_in, ..) = ctx.token_config
  let now = birl.now()
  let sub = uuid.to_string(user.id) |> string.lowercase
  let exp = birl.add(now, duration.seconds(jwt_expires_in))

  gjwt.new()
  |> gjwt.add_claim(claim.issuer(ctx.app_name))
  |> gjwt.add_claim(claim.subject(sub))
  |> gjwt.add_claim(claim.expiration_time(exp))
  |> gjwt.add_claim(claim.issued_at(now))
  |> gjwt.add_claim(#("email", dynamic.from(user.email)))
  |> gjwt.sign_off(key.from_string(jwt_secret_key, "HS256"))
}
