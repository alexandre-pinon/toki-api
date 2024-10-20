import common/errors.{type InitError, EnvError}
import dot_env/env
import gleam/result

pub type Env {
  Env(port: Int)
}

pub fn load() -> Result(Env, InitError) {
  use port <- result.try(env.get_int("PORT") |> result.map_error(EnvError))

  Ok(Env(port))
}
