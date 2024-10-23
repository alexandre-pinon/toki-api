import domain/entities/user.{type User}
import gleam/list
import gleam/option.{type Option, None, Some}
import gleam/pgo
import gleam/result
import infrastructure/decoders/user_decoder
import infrastructure/errors.{type DbError}
import infrastructure/postgres/db
import youid/uuid.{type Uuid}

pub fn find_all(pool: pgo.Connection) -> Result(List(User), DbError) {
  "SELECT id, email, name, google_id FROM users;"
  |> db.execute(pool, [], user_decoder.new())
  |> result.then(list.try_map(_, user_decoder.from_db_to_domain))
}

pub fn find_by_id(
  pool: pgo.Connection,
  id: Uuid,
) -> Result(Option(User), DbError) {
  let user_id = pgo.text(uuid.to_string(id))

  use query_result <- result.try(
    "SELECT id, email, name, google_id FROM users WHERE id = $1;"
    |> db.execute(pool, [user_id], user_decoder.new()),
  )

  let maybe_user =
    list.first(query_result)
    |> option.from_result
    |> option.map(user_decoder.from_db_to_domain)

  case maybe_user {
    Some(Error(error)) -> Error(error)
    Some(Ok(user)) -> Ok(Some(user))
    None -> Ok(None)
  }
}
