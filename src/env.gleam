import dot_env/env
import gleam/option.{type Option}
import gleam/result

pub type Env {
  Env(
    gleam_env: GleamEnv,
    api_config: ApiConfig,
    db_config: DbConfig,
    token_config: TokenConfig,
    recipe_scraper_url: String,
    identity_token: Option(String),
  )
}

pub type GleamEnv {
  Dev
  Prod
}

pub type ApiConfig {
  ApiConfig(port: Int, host: String, name: String)
}

pub type DbConfig {
  DbConfig(
    port: Int,
    host: String,
    database: String,
    user: String,
    password: String,
    pool_size: Int,
  )
}

pub type TokenConfig {
  TokenConfig(
    jwt_secret_key: String,
    jwt_expires_in: Int,
    refresh_token_pepper: String,
    refresh_token_expires_in: Int,
  )
}

pub fn load() -> Result(Env, String) {
  use gleam_env <- result.try(load_gleam_env())
  use api_config <- result.try(load_api_config())
  use db_config <- result.try(load_db_config())
  use token_config <- result.try(load_token_config())
  use recipe_scraper_url <- env.get_then("RECIPE_SCRAPER_URL")
  let identity_token =
    env.get_string("SERVICE_ACCOUNT_IDENTITY_TOKEN") |> option.from_result

  Ok(Env(
    gleam_env,
    api_config,
    db_config,
    token_config,
    recipe_scraper_url,
    identity_token,
  ))
}

fn load_gleam_env() -> Result(GleamEnv, String) {
  use gleam_env <- env.get_then("GLEAM_ENV")

  case gleam_env {
    "dev" -> Ok(Dev)
    "prod" -> Ok(Prod)
    _ -> Error("key GLEAM_ENV is not set or incorrect")
  }
}

fn load_api_config() -> Result(ApiConfig, String) {
  use port <- result.try(env.get_int("API_PORT"))
  use host <- env.get_then("API_HOST")
  use name <- env.get_then("API_NAME")

  Ok(ApiConfig(port, host, name))
}

fn load_db_config() -> Result(DbConfig, String) {
  use port <- result.try(env.get_int("DB_PORT"))
  use host <- env.get_then("DB_HOST")
  use database <- env.get_then("DB_NAME")
  use user <- env.get_then("DB_USER")
  use password <- env.get_then("DB_PASSWORD")

  let pool_size = env.get_int_or("DB_POOL_SIZE", 1)

  Ok(DbConfig(port, host, database, user, password, pool_size))
}

fn load_token_config() -> Result(TokenConfig, String) {
  use jwt_secret_key <- env.get_then("JWT_SECRET_KEY")
  use jwt_expires_in <- result.try(env.get_int("JWT_EXPIRES_IN"))
  use refresh_token_pepper <- env.get_then("REFRESH_TOKEN_PEPPER")
  use refresh_token_expires_in <- result.try(env.get_int(
    "REFRESH_TOKEN_EXPIRES_IN",
  ))

  Ok(TokenConfig(
    jwt_secret_key,
    jwt_expires_in,
    refresh_token_pepper,
    refresh_token_expires_in,
  ))
}
