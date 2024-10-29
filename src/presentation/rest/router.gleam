import application/context.{type Context}
import gleam/http.{Delete, Get, Post, Put}
import presentation/rest/controllers/auth_controller
import presentation/rest/controllers/user_controller
import wisp.{type Request, type Response}

pub fn handle_request(req: Request, ctx: Context) -> Response {
  use <- wisp.log_request(req)

  case wisp.path_segments(req) {
    ["/"] -> wisp.ok()

    ["auth", "register"] -> handle_register(req, ctx)
    ["auth", "login"] -> handle_login(req, ctx)
    ["auth", "logout"] -> handle_logout(req, ctx)
    ["auth", "google"] -> handle_google_auth(req, ctx)

    ["users"] -> handle_users(req, ctx)
    ["users", id] -> handle_user(req, ctx, id)

    _ -> wisp.not_found()
  }
}

fn handle_register(req: Request, ctx: Context) -> Response {
  case req.method {
    Post -> auth_controller.register(req, ctx)
    _ -> wisp.method_not_allowed([Post])
  }
}

fn handle_login(req: Request, ctx: Context) -> Response {
  case req.method {
    Post -> auth_controller.login(req, ctx)
    _ -> wisp.method_not_allowed([Post])
  }
}

fn handle_logout(req: Request, ctx: Context) -> Response {
  case req.method {
    Post -> auth_controller.logout(req, ctx)
    _ -> wisp.method_not_allowed([Post])
  }
}

fn handle_google_auth(req: Request, ctx: Context) -> Response {
  case req.method {
    Post -> auth_controller.google_login(req, ctx)
    _ -> wisp.method_not_allowed([Post])
  }
}

fn handle_users(req: Request, ctx: Context) -> Response {
  case req.method {
    Get -> user_controller.list(ctx)
    Post -> user_controller.create(req, ctx)
    _ -> wisp.method_not_allowed([Get, Post])
  }
}

fn handle_user(req: Request, ctx: Context, id: String) -> Response {
  case req.method {
    Get -> user_controller.show(ctx, id)
    Put -> user_controller.update(req, ctx, id)
    Delete -> user_controller.delete(ctx, id)
    _ -> wisp.method_not_allowed([Get, Put, Delete])
  }
}
