import gleam/io
import gleam/string

pub type InitError {
  EnvError(msg: String)
  ServerStartError
}

pub fn log_error(error: e) -> e {
  io.println_error(string.inspect(error))
  error
}
