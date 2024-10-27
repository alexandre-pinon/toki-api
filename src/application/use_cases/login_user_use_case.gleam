import application/context.{type Context}
import application/dto/user_dto.{type LoginRequest}
import beecrypt
import birl
import birl/duration
import domain/entities/refresh_token.{type RefreshToken}
import domain/entities/user.{type User}
import env.{type TokenConfig}
import gjwt
import gjwt/claim
import gjwt/key
import gleam/bit_array
import gleam/bool
import gleam/crypto
import gleam/dynamic
import gleam/list
import gleam/option.{None, Some}
import gleam/pgo
import gleam/result
import gleam/string
import infrastructure/errors.{type DbError}
import infrastructure/repositories/refresh_token_repository
import infrastructure/repositories/user_repository
import wisp
import youid/uuid.{type Uuid}

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
  let maybe_user = user_repository.find_by_email(port.email, ctx.pool)

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
  use refresh_token <- result.try(
    pgo.transaction(ctx.pool, create_new_refresh_token(
      user.id,
      ctx.token_config,
      _,
    ))
    |> result.map_error(errors.TransactionFailed)
    |> result.map_error(QueryFailed),
  )

  let access_token = generate_access_token(user, ctx)

  Ok(LoginUserUseCaseResult(access_token, refresh_token))
}

fn create_new_refresh_token(
  user_id: Uuid,
  token_config: TokenConfig,
  transaction: pgo.Connection,
) -> Result(String, String) {
  use active_token_ids <- result.try(
    refresh_token_repository.find_all_active(user_id, transaction)
    |> result.map(list.map(_, fn(token: RefreshToken) { token.id }))
    |> result.replace_error("find all active tokens failed"),
  )

  generate_refresh_token(user_id, token_config)
  |> refresh_token_repository.create(transaction)
  |> result.then(fn(refresh_token) {
    use _ <- result.try(replace_active_refresh_tokens(
      active_token_ids,
      refresh_token.id,
      transaction,
    ))
    Ok(refresh_token.token)
  })
  |> result.replace_error("refresh token creation failed")
}

fn replace_active_refresh_tokens(
  active_token_ids: List(Uuid),
  refresh_token_id: Uuid,
  pool: pgo.Connection,
) -> Result(Nil, DbError) {
  active_token_ids
  |> list.try_map(refresh_token_repository.replace(_, refresh_token_id, pool))
  |> result.replace(Nil)
}

fn generate_refresh_token(
  user_id: Uuid,
  token_config: TokenConfig,
) -> RefreshToken {
  let env.TokenConfig(_, _, refresh_token_pepper, refresh_token_expires_in) =
    token_config

  let token =
    wisp.random_string(32)
    |> string.append(refresh_token_pepper)
    |> bit_array.from_string
    |> crypto.hash(crypto.Sha256, _)
    |> bit_array.base64_encode(True)

  let exp = birl.add(birl.now(), duration.seconds(refresh_token_expires_in))

  refresh_token.RefreshToken(
    id: uuid.v4(),
    user_id: user_id,
    token: token,
    expires_at: exp,
    revoked_at: None,
    replaced_at: None,
    replaced_by: None,
  )
}

fn generate_access_token(user: User, ctx: Context) -> String {
  let env.TokenConfig(jwt_secret_key, jwt_expires_in, ..) = ctx.token_config
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
