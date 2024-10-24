import gleam/pgo

pub type DbError {
  EntityNotFound
  DecodingFailed(reason: String)
  ExecutionFailed(pgo.QueryError)
}
