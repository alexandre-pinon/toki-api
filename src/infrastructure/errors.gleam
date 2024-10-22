import gleam/pgo

pub type DbError {
  DecodingFailed(reason: String)
  ExecutionFailed(pgo.QueryError)
}
