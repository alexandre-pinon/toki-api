import application/context.{type Context}
import presentation/rest/controllers/users_controller
import wisp.{type Request, type Response}

pub fn handle_request(req: Request, ctx: Context) -> Response {
  case req.path {
    "/" -> wisp.ok()
    "/users" -> users_controller.list(ctx)
    _ -> wisp.not_found()
  }
}
