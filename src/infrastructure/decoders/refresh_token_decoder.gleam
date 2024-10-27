import birl
import domain/entities/refresh_token.{type RefreshToken}
import domain/value_objects/db_time.{type DbTime}
import gleam/dynamic.{type Decoder}
import gleam/option.{type Option}
import gleam/pgo
import gleam/result
import infrastructure/decoders/common_decoder
import infrastructure/errors.{type DbError}
import youid/uuid

type RefreshTokenRow =
  #(BitArray, BitArray, String, DbTime, Option(DbTime))

pub fn new() -> Decoder(RefreshTokenRow) {
  dynamic.tuple5(
    dynamic.bit_array,
    dynamic.bit_array,
    dynamic.string,
    common_decoder.new_db_time_decoder(),
    dynamic.optional(common_decoder.new_db_time_decoder()),
  )
}

pub fn from_domain_to_db(refresh_token: RefreshToken) -> List(pgo.Value) {
  [
    pgo.text(uuid.to_string(refresh_token.id)),
    pgo.text(uuid.to_string(refresh_token.user_id)),
    pgo.text(refresh_token.token),
    pgo.timestamp(birl.to_erlang_universal_datetime(refresh_token.expires_at)),
    pgo.nullable(
      pgo.timestamp,
      refresh_token.revoked_at |> option.map(birl.to_erlang_universal_datetime),
    ),
  ]
}

pub fn from_db_to_domain(
  refresh_token_row: RefreshTokenRow,
) -> Result(RefreshToken, DbError) {
  let #(id, user_id, token, expires_at, revoked_at) = refresh_token_row

  use id <- result.try(common_decoder.from_db_uuid_to_domain_uuid(id))
  use user_id <- result.try(common_decoder.from_db_uuid_to_domain_uuid(user_id))
  let expires_at = birl.from_erlang_local_datetime(expires_at)
  let revoked_at = revoked_at |> option.map(birl.from_erlang_local_datetime)

  Ok(refresh_token.RefreshToken(id, user_id, token, expires_at, revoked_at))
}
