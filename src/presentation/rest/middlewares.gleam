import wisp.{type Response}
import youid/uuid.{type Uuid}

pub fn require_uuid(id: String, next: fn(Uuid) -> Response) -> Response {
  case uuid.from_string(id) {
    Ok(valid_uuid) -> next(valid_uuid)
    Error(Nil) -> {
      wisp.log_error("Invalid uuid: " <> id)
      wisp.bad_request()
    }
  }
}
