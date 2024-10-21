import domain/entities/user.{type User}
import gleam/dynamic
import gleam/io
import gleam/list
import gleam/option.{type Option, None, Some}
import gleam/pgo
import gleam/result
import gleam/string
import helpers
import infrastructure/errors.{type DbError, DecodingFailed, ExecutionFailed}
import infrastructure/postgres/db
import youid/uuid.{type Uuid}

pub fn find_all(pool: pgo.Connection) -> Result(List(User), DbError) {
  let user_decoder =
    dynamic.tuple4(
      dynamic.bit_array,
      dynamic.string,
      dynamic.string,
      dynamic.optional(dynamic.string),
    )

  "SELECT id, email, name, google_id FROM users;"
  |> db.execute(pool, [], user_decoder)
  |> result.map_error(ExecutionFailed)
  |> result.then(list.try_map(_, from_db_to_domain))
}

pub fn find_by_id(
  pool: pgo.Connection,
  id: Uuid,
) -> Result(Option(User), DbError) {
  let user_decoder =
    dynamic.tuple4(
      dynamic.bit_array,
      dynamic.string,
      dynamic.string,
      dynamic.optional(dynamic.string),
    )

  use query_result <- result.try(
    "SELECT id, email, name, google_id FROM users WHERE id = $1;"
    |> db.execute(pool, [pgo.text(uuid.to_string(id))], user_decoder)
    |> result.map_error(fn(e) {
      io.println_error(string.inspect(e))
      e
    })
    |> result.map_error(ExecutionFailed),
  )

  let maybe_user =
    list.first(query_result)
    |> option.from_result
    |> option.map(from_db_to_domain)

  case maybe_user {
    Some(Error(error)) -> Error(error)
    Some(Ok(user)) -> Ok(Some(user))
    None -> Ok(None)
  }
}

fn from_db_to_domain(
  row: #(BitArray, String, String, Option(String)),
) -> Result(User, DbError) {
  let #(id, email, name, google_id) = row

  helpers.map_bit_array_to_string(id)
  |> result.map(user.User(_, email, name, google_id))
  |> result.map_error(DecodingFailed)
}
