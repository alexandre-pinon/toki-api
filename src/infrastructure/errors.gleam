import gleam/dynamic.{type Dynamic}
import gleam/json
import gleam/pgo

pub type DbError {
  EntityNotFound
  DecodingFailed(reason: String)
  JsonDecodingFailed(json.DecodeError)
  ExecutionFailed(pgo.QueryError)
}

pub type HttpError {
  InvalidUrl(url: String)
  RequestFailed(reason: Dynamic)
  BodyDecodingFailed(json.DecodeError)
  WebsiteNotSupported(url: String)
}
