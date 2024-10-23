import gleam/string
import wisp

pub fn log_error(error: e) -> e {
  string.inspect(error) |> wisp.log_error
  error
}
