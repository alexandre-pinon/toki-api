import env
import gleam/pgo
import youid/uuid.{type Uuid}

pub type Context {
  Context(app_name: String, pool: pgo.Connection, token_config: env.TokenConfig)
}

pub type AuthContext {
  AuthContext(user_id: Uuid, ctx: Context)
}
