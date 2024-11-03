import application/context.{type Context}
import application/dto/auth_dto.{type RefreshAccessTokenRequest}
import application/use_cases/regenerate_auth_tokens_use_case.{
  type RegenerateAuthTokensUseCaseErrors, RegenerateAuthTokensUseCaseResult,
}
import domain/entities/refresh_token.{type RefreshToken}
import domain/entities/user.{type User}
import gleam/option.{None, Some}
import gleam/pgo
import gleam/result
import infrastructure/errors.{type DbError, EntityNotFound}
import infrastructure/repositories/refresh_token_repository
import infrastructure/repositories/user_repository
import youid/uuid.{type Uuid}

pub type RefreshAccessTokenUseCasePort =
  RefreshAccessTokenRequest

pub type RefreshAccessTokenUseCaseResult {
  RefreshAccessTokenUseCaseResult(access_token: String, refresh_token: String)
}

pub type RefreshAccessTokenUseCaseErrors {
  QueryFailed(DbError)
  ActiveRefreshTokenNotFound
  AuthTokenRegenerationFailed(RegenerateAuthTokensUseCaseErrors)
}

pub fn execute(
  port: RefreshAccessTokenUseCasePort,
  ctx: Context,
) -> Result(RefreshAccessTokenUseCaseResult, RefreshAccessTokenUseCaseErrors) {
  use refresh_token <- result.try(get_active_refresh_token(port.token, ctx.pool))
  use user <- result.try(get_user(refresh_token.user_id, ctx.pool))

  use RegenerateAuthTokensUseCaseResult(access_token, refresh_token) <- result.try(
    regenerate_auth_tokens_use_case.execute(user, ctx)
    |> result.map_error(AuthTokenRegenerationFailed),
  )

  Ok(RefreshAccessTokenUseCaseResult(access_token, refresh_token))
}

fn get_active_refresh_token(
  token: String,
  pool: pgo.Connection,
) -> Result(RefreshToken, RefreshAccessTokenUseCaseErrors) {
  let maybe_token = refresh_token_repository.get_active_by_token(token, pool)

  case maybe_token {
    Ok(token) -> Ok(token)
    Error(EntityNotFound) -> Error(ActiveRefreshTokenNotFound)
    Error(db_error) -> Error(QueryFailed(db_error))
  }
}

fn get_user(
  user_id: Uuid,
  pool: pgo.Connection,
) -> Result(User, RefreshAccessTokenUseCaseErrors) {
  let maybe_user = user_repository.find_by_id(user_id, pool)

  case maybe_user {
    Ok(Some(user)) -> Ok(user)
    Ok(None) -> Error(ActiveRefreshTokenNotFound)
    Error(db_error) -> Error(QueryFailed(db_error))
  }
}
