import birl
import domain/entities/refresh_token.{type RefreshToken}
import domain/value_objects/db_date.{type DbTimestamp}
import gleam/dynamic.{type Decoder}
import gleam/option.{type Option}
import gleam/pgo
import gleam/result
import infrastructure/decoders/common_decoder
import infrastructure/errors.{type DbError}
import youid/uuid

pub type RefreshTokenRow {
  RefreshTokenRow(
    id: BitArray,
    user_id: BitArray,
    token: String,
    expires_at: DbTimestamp,
    revoked_at: Option(DbTimestamp),
    replaced_at: Option(DbTimestamp),
    replaced_by: Option(BitArray),
  )
}

pub fn new() -> Decoder(RefreshTokenRow) {
  dynamic.decode7(
    RefreshTokenRow,
    dynamic.field("id", dynamic.bit_array),
    dynamic.field("user_id", dynamic.bit_array),
    dynamic.field("token", dynamic.string),
    dynamic.field("expires_at", pgo.decode_timestamp),
    dynamic.field("revoked_at", dynamic.optional(pgo.decode_timestamp)),
    dynamic.field("replaced_at", dynamic.optional(pgo.decode_timestamp)),
    dynamic.field("replaced_by", dynamic.optional(dynamic.bit_array)),
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
    pgo.nullable(
      pgo.timestamp,
      refresh_token.replaced_at |> option.map(birl.to_erlang_universal_datetime),
    ),
    pgo.nullable(
      pgo.text,
      refresh_token.replaced_by |> option.map(uuid.to_string),
    ),
  ]
}

pub fn from_db_to_domain(
  refresh_token_row: RefreshTokenRow,
) -> Result(RefreshToken, DbError) {
  let RefreshTokenRow(
    id,
    user_id,
    token,
    expires_at,
    revoked_at,
    replaced_at,
    replaced_by,
  ) = refresh_token_row

  use id <- result.try(common_decoder.from_db_uuid_to_domain_uuid(id))
  use user_id <- result.try(common_decoder.from_db_uuid_to_domain_uuid(user_id))
  let expires_at = birl.from_erlang_local_datetime(expires_at)
  let revoked_at = revoked_at |> option.map(birl.from_erlang_local_datetime)
  let replaced_at = replaced_at |> option.map(birl.from_erlang_local_datetime)
  use replaced_by <- result.try(
    common_decoder.from_optional_db_uuid_to_optional_domain_uuid(replaced_by),
  )

  Ok(refresh_token.RefreshToken(
    id,
    user_id,
    token,
    expires_at,
    revoked_at,
    replaced_at,
    replaced_by,
  ))
}
