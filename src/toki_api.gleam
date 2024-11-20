import app_logger
import application/context.{Context}
import dot_env
import env.{ApiConfig, Dev, Prod}
import gleam/erlang.{type EnsureAllStartedError}
import gleam/erlang/atom
import gleam/erlang/process
import gleam/int
import gleam/pgo
import gleam/result
import gleam/string
import infrastructure/postgres/db
import mist
import presentation/rest/router
import wisp.{DebugLevel}
import wisp/wisp_mist

pub fn main() -> Nil {
  dot_env.load_default()
  wisp.configure_logger()
  // TODO: change log level dynamically in dev/prod
  wisp.set_logger_level(DebugLevel)

  case start_server() {
    Ok(Nil) -> {
      wisp.log_info("Server started successfully")
    }
    Error(error) -> {
      wisp.log_critical("Failed to start server: " <> string.inspect(error))
    }
  }

  process.sleep_forever()
}

type InitError {
  EnvError(msg: String)
  ServerStartError
  DbConnectionError(pgo.QueryError)
  SslError(EnsureAllStartedError)
}

fn start_server() -> Result(Nil, InitError) {
  use env <- result.try(env.load() |> result.map_error(EnvError))
  let ApiConfig(port, host, app_name) = env.api_config

  wisp.log_info("Starting " <> app_name <> " on port: " <> int.to_string(port))

  use _ <- result.try(case env.gleam_env {
    Dev -> Ok(Nil)
    Prod -> start_ssl()
  })

  let pool = db.connect(env.gleam_env, env.db_config)
  use _ <- result.try(
    db.check_connection(pool) |> result.map_error(DbConnectionError),
  )

  let ctx =
    Context(
      gleam_env: env.gleam_env,
      app_name: app_name,
      pool: pool,
      token_config: env.token_config,
      recipe_scraper_url: env.recipe_scraper_url,
      identity_token: env.identity_token,
    )
  let handler = router.handle_request(_, ctx)

  //TODO: use env for secret key
  wisp_mist.handler(handler, "SECRET_KEY_BASE")
  |> mist.new
  |> mist.port(port)
  |> mist.bind(host)
  |> mist.start_http
  |> result.map_error(app_logger.log_error)
  |> result.replace_error(ServerStartError)
  |> result.replace(Nil)
}

fn start_ssl() -> Result(Nil, InitError) {
  let ssl_started = atom.create_from_string("ssl") |> erlang.ensure_all_started

  case ssl_started {
    Ok(_) -> Ok(Nil)
    Error(error) -> Error(SslError(error))
  }
}
