import application/context.{type Context}
import presentation/rest/controllers/users_controller
import wisp.{type Request, type Response}

pub fn handle_request(req: Request, ctx: Context) -> Response {
  case wisp.path_segments(req) {
    ["/"] -> wisp.ok()
    ["users"] -> users_controller.list(ctx)
    ["users", id] -> users_controller.show(ctx, id)

    _ -> wisp.not_found()
  }
}
