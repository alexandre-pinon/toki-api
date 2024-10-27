import env
import gleam/pgo

pub type Context {
  Context(app_name: String, pool: pgo.Connection, jwt_config: env.JwtConfig)
}
