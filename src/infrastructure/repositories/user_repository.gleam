import application/dto/user_dto.{type UserUpdateInput}
import domain/entities/user.{type User}
import gleam/list
import gleam/option.{type Option, None, Some}
import gleam/pgo
import gleam/result
import infrastructure/decoders/user_decoder
import infrastructure/errors.{type DbError, EntityNotFound}
import infrastructure/postgres/db
import youid/uuid.{type Uuid}

pub fn find_all(on pool: pgo.Connection) -> Result(List(User), DbError) {
  "SELECT id, email, name, google_id, password_hash FROM users"
  |> db.execute(pool, [], user_decoder.new())
  |> result.map(fn(returned) { returned.rows })
  |> result.then(list.try_map(_, user_decoder.from_db_to_domain))
}

pub fn find_by_id(
  id: Uuid,
  on pool: pgo.Connection,
) -> Result(Option(User), DbError) {
  let user_id = pgo.text(uuid.to_string(id))

  use query_result <- result.try(
    "SELECT id, email, name, google_id, password_hash FROM users WHERE id = $1"
    |> db.execute(pool, [user_id], user_decoder.new()),
  )

  let maybe_user =
    list.first(query_result.rows)
    |> option.from_result
    |> option.map(user_decoder.from_db_to_domain)

  case maybe_user {
    Some(Error(error)) -> Error(error)
    Some(Ok(user)) -> Ok(Some(user))
    None -> Ok(None)
  }
}

pub fn find_by_email(
  email: String,
  on pool: pgo.Connection,
) -> Result(Option(User), DbError) {
  use query_result <- result.try(
    "SELECT id, email, name, google_id, password_hash FROM users WHERE email = $1"
    |> db.execute(pool, [pgo.text(email)], user_decoder.new()),
  )

  let maybe_user =
    list.first(query_result.rows)
    |> option.from_result
    |> option.map(user_decoder.from_db_to_domain)

  case maybe_user {
    Some(Error(error)) -> Error(error)
    Some(Ok(user)) -> Ok(Some(user))
    None -> Ok(None)
  }
}

pub fn create(user: User, on pool: pgo.Connection) -> Result(User, DbError) {
  let query_input = user_decoder.from_domain_to_db(user)

  use query_result <- result.try(
    "
      INSERT INTO users (id, email, name, google_id, password_hash, created_at, updated_at)
      VALUES ($1, $2, $3, $4, $5, DEFAULT, NOW())
      RETURNING id, email, name, google_id, password_hash
    "
    |> db.execute(pool, query_input, user_decoder.new()),
  )

  list.first(query_result.rows)
  |> result.replace_error(EntityNotFound)
  |> result.then(user_decoder.from_db_to_domain)
}

pub fn update(
  id: Uuid,
  input: UserUpdateInput,
  on pool: pgo.Connection,
) -> Result(User, DbError) {
  let query_input = [
    pgo.nullable(pgo.text, input.email),
    pgo.nullable(pgo.text, input.name),
    pgo.nullable(pgo.text, input.google_id),
    pgo.text(uuid.to_string(id)),
  ]

  use query_result <- result.try(
    "
      UPDATE users
      SET email = COALESCE($1, email),
          name = COALESCE($2, name),
          google_id = COALESCE($3, google_id),
          updated_at = NOW()
      WHERE id = $4
      RETURNING id, email, name, google_id, password_hash
    "
    |> db.execute(pool, query_input, user_decoder.new()),
  )

  list.first(query_result.rows)
  |> result.replace_error(EntityNotFound)
  |> result.then(user_decoder.from_db_to_domain)
}

pub fn delete(id: Uuid, on pool: pgo.Connection) -> Result(Bool, DbError) {
  let user_id = pgo.text(uuid.to_string(id))

  "DELETE FROM users WHERE id = $1"
  |> db.execute(pool, [user_id], user_decoder.new())
  |> result.map(fn(returned) { returned.count > 0 })
}
