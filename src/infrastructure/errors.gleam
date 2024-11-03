import gleam/json
import gleam/pgo

pub type DbError {
  EntityNotFound
  DecodingFailed(reason: String)
  JsonDecodingFailed(json.DecodeError)
  ExecutionFailed(pgo.QueryError)
}
