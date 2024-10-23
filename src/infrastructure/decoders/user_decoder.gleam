import domain/entities/user.{type User}
import gleam/dynamic.{type Decoder}
import gleam/option.{type Option}
import gleam/result
import infrastructure/errors.{type DbError, DecodingFailed}
import youid/uuid

type UserRow =
  #(BitArray, String, String, Option(String))

pub fn new() -> Decoder(UserRow) {
  dynamic.tuple4(
    dynamic.bit_array,
    dynamic.string,
    dynamic.string,
    dynamic.optional(dynamic.string),
  )
}

pub fn from_db_to_domain(user_row: UserRow) -> Result(User, DbError) {
  let #(id, email, name, google_id) = user_row

  uuid.from_bit_array(id)
  |> result.replace_error(DecodingFailed("couldn't deserialize id to uuid"))
  |> result.map(user.User(_, email, name, google_id))
}
