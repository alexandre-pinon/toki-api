import app_logger
import application/context.{Context}
import dot_env
import env
import gleam/erlang/process
import gleam/int
import gleam/io
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
      io.println("Server started successfully")
    }
    Error(error) -> {
      io.println_error("Failed to start server: " <> string.inspect(error))
    }
  }

  process.sleep_forever()
}

type InitError {
  EnvError(msg: String)
  ServerStartError
}

fn start_server() -> Result(Nil, InitError) {
  use env <- result.try(env.load() |> result.map_error(EnvError))

  io.println("Starting Epicook API on port: " <> int.to_string(env.port))

  let pool = db.connect(env.db_config)
  let ctx =
    Context(app_name: env.app_name, pool: pool, jwt_config: env.jwt_config)
  let handler = router.handle_request(_, ctx)

  wisp_mist.handler(handler, "SECRET_KEY_BASE")
  |> mist.new
  |> mist.port(env.port)
  |> mist.start_http
  |> result.map_error(app_logger.log_error)
  |> result.replace_error(ServerStartError)
  |> result.replace(Nil)
}
