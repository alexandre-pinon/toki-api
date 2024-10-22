import gleam/string
import wisp

pub fn log_error(error: e) -> e {
  wisp.log_error(string.inspect(error))
  error
}
