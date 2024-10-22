import dot_env/env
import gleam/result

pub type Env {
  Env(port: Int, db_config: DbConfig)
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

pub fn load() -> Result(Env, String) {
  use port <- result.try(env.get_int("PORT"))
  use db_config <- result.try(load_db_config())

  Ok(Env(port, db_config))
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
