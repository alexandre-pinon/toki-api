import wisp.{type Request, type Response}

pub fn handle_request(req: Request) -> Response {
  case req.path {
    "/" -> wisp.ok()
    _ -> wisp.not_found()
  }
}
