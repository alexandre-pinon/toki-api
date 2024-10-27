import domain/entities/refresh_token.{type RefreshToken}
import gleam/list
import gleam/pgo
import gleam/result
import infrastructure/decoders/refresh_token_decoder
import infrastructure/errors.{type DbError, EntityNotFound}
import infrastructure/postgres/db

pub fn create(
  pool: pgo.Connection,
  refresh_token: RefreshToken,
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
