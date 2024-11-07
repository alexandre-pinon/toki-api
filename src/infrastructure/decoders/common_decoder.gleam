import gleam/dynamic.{type DecodeError, type Decoder, type Dynamic}
import gleam/list
import gleam/option.{type Option, None, Some}
import gleam/result
import infrastructure/errors.{type DbError, DecodingFailed}
import youid/uuid.{type Uuid}

pub fn from_db_uuid_to_domain_uuid(db_uuid: BitArray) -> Result(Uuid, DbError) {
  uuid.from_bit_array(db_uuid)
  |> result.replace_error(DecodingFailed("couldn't deserialize db id to uuid"))
}

pub fn from_optional_db_uuid_to_optional_domain_uuid(
  db_uuid: Option(BitArray),
) -> Result(Option(Uuid), DbError) {
  case db_uuid {
    Some(db_uuid) -> from_db_uuid_to_domain_uuid(db_uuid) |> result.map(Some)
    None -> Ok(None)
  }
}

pub fn from_json_db_uuid_to_domain_uuid(
  json_db_uuid: String,
) -> Result(Uuid, DbError) {
  uuid.from_string(json_db_uuid)
  |> result.replace_error(DecodingFailed(
    "couldn't deserialize json db id to uuid",
  ))
}

pub fn parse_optional(
  value: Option(v),
  parse_fn: fn(v) -> Result(p, e),
  label: String,
) -> Result(Option(p), DbError) {
  case value {
    Some(value) ->
      parse_fn(value)
      |> result.map(Some)
      |> result.replace_error(DecodingFailed("couldn't deserialize " <> label))
    None -> Ok(None)
  }
}

pub fn decode10(
  constructor: fn(t1, t2, t3, t4, t5, t6, t7, t8, t9, t10) -> t,
  t1: Decoder(t1),
  t2: Decoder(t2),
  t3: Decoder(t3),
  t4: Decoder(t4),
  t5: Decoder(t5),
  t6: Decoder(t6),
  t7: Decoder(t7),
  t8: Decoder(t8),
  t9: Decoder(t9),
  t10: Decoder(t10),
) -> Decoder(t) {
  fn(x: Dynamic) {
    case t1(x), t2(x), t3(x), t4(x), t5(x), t6(x), t7(x), t8(x), t9(x), t10(x) {
      Ok(a), Ok(b), Ok(c), Ok(d), Ok(e), Ok(f), Ok(g), Ok(h), Ok(i), Ok(j) ->
        Ok(constructor(a, b, c, d, e, f, g, h, i, j))
      a, b, c, d, e, f, g, h, i, j ->
        Error(
          list.concat([
            all_errors(a),
            all_errors(b),
            all_errors(c),
            all_errors(d),
            all_errors(e),
            all_errors(f),
            all_errors(g),
            all_errors(h),
            all_errors(i),
            all_errors(j),
          ]),
        )
    }
  }
}

pub fn decode12(
  constructor: fn(t1, t2, t3, t4, t5, t6, t7, t8, t9, t10, t11, t12) -> t,
  t1: Decoder(t1),
  t2: Decoder(t2),
  t3: Decoder(t3),
  t4: Decoder(t4),
  t5: Decoder(t5),
  t6: Decoder(t6),
  t7: Decoder(t7),
  t8: Decoder(t8),
  t9: Decoder(t9),
  t10: Decoder(t10),
  t11: Decoder(t11),
  t12: Decoder(t12),
) -> Decoder(t) {
  fn(x: Dynamic) {
    case
      t1(x),
      t2(x),
      t3(x),
      t4(x),
      t5(x),
      t6(x),
      t7(x),
      t8(x),
      t9(x),
      t10(x),
      t11(x),
      t12(x)
    {
      Ok(a),
        Ok(b),
        Ok(c),
        Ok(d),
        Ok(e),
        Ok(f),
        Ok(g),
        Ok(h),
        Ok(i),
        Ok(j),
        Ok(k),
        Ok(l)
      -> Ok(constructor(a, b, c, d, e, f, g, h, i, j, k, l))
      a, b, c, d, e, f, g, h, i, j, k, l ->
        Error(
          list.concat([
            all_errors(a),
            all_errors(b),
            all_errors(c),
            all_errors(d),
            all_errors(e),
            all_errors(f),
            all_errors(g),
            all_errors(h),
            all_errors(i),
            all_errors(j),
            all_errors(k),
            all_errors(l),
          ]),
        )
    }
  }
}

fn all_errors(result: Result(a, List(DecodeError))) -> List(DecodeError) {
  case result {
    Ok(_) -> []
    Error(errors) -> errors
  }
}
