import domain/value_objects/db_time.{type DbTime}
import gleam/dynamic.{type Decoder}
import gleam/result
import infrastructure/errors.{type DbError, DecodingFailed}
import youid/uuid.{type Uuid}

pub fn new_db_time_decoder() -> Decoder(DbTime) {
  dynamic.tuple2(
    dynamic.tuple3(dynamic.int, dynamic.int, dynamic.int),
    dynamic.tuple3(dynamic.int, dynamic.int, dynamic.int),
  )
}

pub fn from_db_uuid_to_domain_uuid(db_uuid: BitArray) -> Result(Uuid, DbError) {
  uuid.from_bit_array(db_uuid)
  |> result.replace_error(DecodingFailed("couldn't deserialize id to uuid"))
}
