import env
import gleam/pgo

pub type Context {
  Context(app_name: String, pool: pgo.Connection, token_config: env.TokenConfig)
}
