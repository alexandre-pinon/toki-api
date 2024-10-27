import birl
import birl/duration
import domain/entities/refresh_token.{type RefreshToken}
import gleam/dynamic
import gleam/list
import gleam/pgo
import gleam/result
import infrastructure/decoders/refresh_token_decoder
import infrastructure/errors.{type DbError, EntityNotFound}
import infrastructure/postgres/db
import youid/uuid.{type Uuid}

pub fn find_all_active(
  user_id: Uuid,
  on pool: pgo.Connection,
) -> Result(List(RefreshToken), DbError) {
  let user_id = pgo.text(uuid.to_string(user_id))

  "
    SELECT id, user_id, token, expires_at, revoked_at, replaced_at, replaced_by FROM refresh_tokens
    WHERE user_id = $1
    AND revoked_at IS NULL
    AND expires_at > NOW()
  "
  |> db.execute(pool, [user_id], refresh_token_decoder.new())
  |> result.map(fn(returned) { returned.rows })
  |> result.then(list.try_map(_, refresh_token_decoder.from_db_to_domain))
}

pub fn create(
  refresh_token: RefreshToken,
  on pool: pgo.Connection,
) -> Result(RefreshToken, DbError) {
  let query_input = refresh_token_decoder.from_domain_to_db(refresh_token)

  use query_result <- result.try(
    "
      INSERT INTO refresh_tokens (id, user_id, token, expires_at, revoked_at, replaced_at, replaced_by, created_at, updated_at)
      VALUES ($1, $2, $3, $4, $5, $6, $7, DEFAULT, NOW())
      RETURNING id, user_id, token, expires_at, revoked_at, replaced_at, replaced_by
    "
    |> db.execute(pool, query_input, refresh_token_decoder.new()),
  )

  list.first(query_result.rows)
  |> result.replace_error(EntityNotFound)
  |> result.then(refresh_token_decoder.from_db_to_domain)
}

pub fn replace(
  token old_id: Uuid,
  by new_id: Uuid,
  on pool: pgo.Connection,
) -> Result(Nil, DbError) {
  let replaced_at = birl.now()
  let expires_at = birl.add(replaced_at, duration.minutes(1))
  let query_input = [
    pgo.timestamp(birl.to_erlang_universal_datetime(expires_at)),
    pgo.timestamp(birl.to_erlang_universal_datetime(replaced_at)),
    pgo.text(uuid.to_string(new_id)),
    pgo.text(uuid.to_string(old_id)),
  ]

  "
    UPDATE refresh_tokens
    SET expires_at = $1,
        replaced_at = $2,
        replaced_by = $3,
        updated_at = NOW()
    WHERE id = $4
  "
  |> db.execute(pool, query_input, dynamic.dynamic)
  |> result.replace(Nil)
}
