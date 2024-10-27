import domain/entities/user.{type User}
import gleam/dynamic.{type Decoder}
import gleam/option.{type Option}
import gleam/pgo
import gleam/result
import infrastructure/decoders/common_decoder
import infrastructure/errors.{type DbError}
import youid/uuid

pub type UserRow {
  UserRow(
    id: BitArray,
    email: String,
    name: String,
    google_id: Option(String),
    password_hash: Option(String),
  )
}

pub fn new() -> Decoder(UserRow) {
  dynamic.decode5(
    UserRow,
    dynamic.field("id", dynamic.bit_array),
    dynamic.field("email", dynamic.string),
    dynamic.field("name", dynamic.string),
    dynamic.field("google_id", dynamic.optional(dynamic.string)),
    dynamic.field("password_hash", dynamic.optional(dynamic.string)),
  )
}

pub fn from_domain_to_db(user: User) -> List(pgo.Value) {
  [
    pgo.text(uuid.to_string(user.id)),
    pgo.text(user.email),
    pgo.text(user.name),
    pgo.nullable(pgo.text, user.google_id),
    pgo.nullable(pgo.text, user.password_hash),
  ]
}

pub fn from_db_to_domain(user_row: UserRow) -> Result(User, DbError) {
  let UserRow(id, email, name, google_id, password_hash) = user_row

  use id <- result.try(common_decoder.from_db_uuid_to_domain_uuid(id))

  Ok(user.User(id, email, name, google_id, password_hash))
}
