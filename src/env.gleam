import dot_env/env
import gleam/result

pub type Env {
  Env(
    app_name: String,
    port: Int,
    db_config: DbConfig,
    token_config: TokenConfig,
  )
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
  use app_name <- env.get_then("APP_NAME")
  use port <- result.try(env.get_int("PORT"))
  use db_config <- result.try(load_db_config())
  use token_config <- result.try(load_token_config())

  Ok(Env(app_name, port, db_config, token_config))
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
