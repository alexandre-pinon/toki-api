import gleam/dynamic.{type Dynamic}
import gleam/json
import gleam/pgo

pub type DbError {
  EntityNotFound
  DecodingFailed(reason: String)
  JsonDecodingFailed(json.DecodeError)
  ExecutionFailed(pgo.QueryError)
}

pub type RequestError {
  HttpError(reason: Dynamic)
  BodyDecodingFailed(json.DecodeError)
  WebsiteNotSupported(url: String)
}
