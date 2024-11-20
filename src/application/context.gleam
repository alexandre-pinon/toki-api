import env
import gleam/pgo
import youid/uuid.{type Uuid}

pub type Context {
  Context(
    gleam_env: env.GleamEnv,
    app_name: String,
    pool: pgo.Connection,
    token_config: env.TokenConfig,
    recipe_scraper_url: String,
  )
}

pub type AuthContext {
  AuthContext(user_id: Uuid, ctx: Context)
}
