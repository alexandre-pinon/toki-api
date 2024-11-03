import application/context.{type Context}
import application/dto/auth_dto.{
  type LoginRequest, GoogleLoginRequest, GoogleRegisterRequest,
  PasswordLoginRequest,
}
import application/dto/user_dto.{UserUpdateRequest}
import application/use_cases/regenerate_auth_tokens_use_case.{
  type RegenerateAuthTokensUseCaseErrors, RegenerateAuthTokensUseCaseResult,
}
import application/use_cases/register_user_use_case.{
  type RegisterUserUseCaseErrors,
}
import application/use_cases/update_user_use_case.{
  type UpdateUserUseCaseErrors, UpdateUserUseCasePort,
}
import beecrypt
import domain/entities/user.{type User}
import gleam/option.{type Option, None, Some}
import gleam/result
import infrastructure/errors.{type DbError}
import infrastructure/repositories/user_repository

pub type LoginUserUseCasePort =
  LoginRequest

pub type LoginUserUseCaseResult {
  LoginUserUseCaseResult(access_token: String, refresh_token: String)
}

pub type LoginUserUseCaseErrors {
  QueryFailed(DbError)
  InvalidCredentials
  GoogleRegisterFailed(RegisterUserUseCaseErrors)
  GoogleUpdateUserFailed(UpdateUserUseCaseErrors)
  AuthTokenRegenerationFailed(RegenerateAuthTokensUseCaseErrors)
}

pub fn execute(
  port: LoginUserUseCasePort,
  ctx: Context,
) -> Result(LoginUserUseCaseResult, LoginUserUseCaseErrors) {
  case port {
    PasswordLoginRequest(email, password) ->
      login_user_with_password(email, password, ctx)
    GoogleLoginRequest(email, name, google_id) ->
      login_user_with_google(email, name, google_id, ctx)
  }
}

fn login_user_with_password(
  email: String,
  password: String,
  ctx: Context,
) -> Result(LoginUserUseCaseResult, LoginUserUseCaseErrors) {
  let maybe_user = user_repository.find_by_email(email, ctx.pool)

  use user <- result.try(case maybe_user {
    Ok(Some(user)) -> Ok(user)
    Ok(None) -> Error(InvalidCredentials)
    Error(db_error) -> Error(QueryFailed(db_error))
  })

  use are_credentials_valid <- result.try(validate_user_credentials(
    user,
    password,
  ))

  case are_credentials_valid {
    True -> regenerate_auth_tokens(user, ctx)
    False -> Error(InvalidCredentials)
  }
}

fn login_user_with_google(
  email: String,
  maybe_name: Option(String),
  google_id: String,
  ctx: Context,
) -> Result(LoginUserUseCaseResult, LoginUserUseCaseErrors) {
  let maybe_user = user_repository.find_by_email(email, ctx.pool)

  use user <- result.try(case maybe_user {
    Ok(Some(user)) ->
      update_user_use_case.execute(
        UpdateUserUseCasePort(
          user.id,
          UserUpdateRequest(Some(email), maybe_name, Some(google_id)),
        ),
        ctx,
      )
      |> result.map_error(GoogleUpdateUserFailed)
    Ok(None) ->
      register_user_use_case.execute(
        GoogleRegisterRequest(
          email,
          option.unwrap(maybe_name, email),
          google_id,
        ),
        ctx,
      )
      |> result.map_error(GoogleRegisterFailed)
    Error(db_error) -> Error(QueryFailed(db_error))
  })

  regenerate_auth_tokens(user, ctx)
}

fn validate_user_credentials(
  user: User,
  password: String,
) -> Result(Bool, LoginUserUseCaseErrors) {
  user.password_hash
  |> option.map(beecrypt.verify(password, _))
  |> option.to_result(InvalidCredentials)
}

fn regenerate_auth_tokens(
  user: User,
  ctx: Context,
) -> Result(LoginUserUseCaseResult, LoginUserUseCaseErrors) {
  use RegenerateAuthTokensUseCaseResult(access_token, refresh_token) <- result.try(
    regenerate_auth_tokens_use_case.execute(user, ctx)
    |> result.map_error(AuthTokenRegenerationFailed),
  )

  Ok(LoginUserUseCaseResult(access_token, refresh_token))
}
