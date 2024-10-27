import dot_env/env
import gleam/result

pub type Env {
  Env(app_name: String, port: Int, db_config: DbConfig, jwt_config: JwtConfig)
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

pub type JwtConfig {
  JwtConfig(secret_key: String, expires_in: Int)
}

pub fn load() -> Result(Env, String) {
  use app_name <- env.get_then("APP_NAME")
  use port <- result.try(env.get_int("PORT"))
  use db_config <- result.try(load_db_config())
  use jwt_config <- result.try(loag_jwt_config())

  Ok(Env(app_name, port, db_config, jwt_config))
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

fn loag_jwt_config() -> Result(JwtConfig, String) {
  use secret_key <- env.get_then("JWT_SECRET_KEY")
  use expires_in <- result.try(env.get_int("JWT_EXPIRES_IN"))

  Ok(JwtConfig(secret_key, expires_in))
}
