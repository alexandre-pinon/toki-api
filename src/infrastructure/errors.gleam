import gleam/pgo

pub type DbError {
  DecodingFailed(DecoderError)
  ExecutionFailed(pgo.QueryError)
}

pub type DecoderError {
  InvalidUUID
}
