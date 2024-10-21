import domain/entities/user.{type User}
import gleam/dynamic
import gleam/list
import gleam/option.{type Option}
import gleam/pgo
import gleam/result
import helpers
import infrastructure/errors.{type DbError, DecodingFailed, ExecutionFailed}
import infrastructure/postgres/db

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

fn from_db_to_domain(
  row: #(BitArray, String, String, Option(String)),
) -> Result(User, DbError) {
  let #(id, email, name, google_id) = row

  helpers.map_bit_array_to_string(id)
  |> result.map(user.User(_, email, name, google_id))
  |> result.map_error(DecodingFailed)
}
