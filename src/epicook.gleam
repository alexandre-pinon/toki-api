import application/context.{Context}
import common/errors.{type InitError, ServerStartError, log_error}
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
import wisp/wisp_mist

pub fn main() -> Nil {
  dot_env.load_default()

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

fn start_server() -> Result(Nil, InitError) {
  use env <- result.try(env.load())

  io.println("Starting Epicook API on port: " <> int.to_string(env.port))

  let db = db.connect(env.db_config)
  let context = Context(db)
  let handler = router.handle_request(_, context)

  wisp_mist.handler(handler, "SECRET_KEY_BASE")
  |> mist.new
  |> mist.port(env.port)
  |> mist.start_http
  |> result.map_error(log_error)
  |> result.replace_error(ServerStartError)
  |> result.replace(Nil)
}
