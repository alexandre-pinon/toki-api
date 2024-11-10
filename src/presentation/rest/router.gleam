import application/context.{type Context}
import gleam/http.{Delete, Get, Post, Put}
import presentation/rest/controllers/auth_controller
import presentation/rest/controllers/planned_meal_controller
import presentation/rest/controllers/recipe_controller
import presentation/rest/controllers/shopping_list_item_controller
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
    ["auth", "refresh"] -> handle_refresh(req, ctx)

    ["users"] -> handle_users(req, ctx)
    ["users", "me"] -> handle_user_profile(req, ctx)

    ["recipes"] -> handle_recipes(req, ctx)
    ["recipes", id] -> handle_recipe(req, ctx, id)

    ["planned-meals"] -> handle_planned_meals(req, ctx)
    ["planned-meals", id] -> handle_planned_meal(req, ctx, id)

    ["shopping-list-item"] -> handle_shopping_list_items(req, ctx)
    ["shopping-list-item", id] -> handle_shopping_list_item(req, ctx, id)
    ["shopping-list-item", id, "check"] ->
      handle_shopping_list_item_check(req, ctx, id)
    ["shopping-list-item", id, "uncheck"] ->
      handle_shopping_list_item_uncheck(req, ctx, id)

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

fn handle_refresh(req: Request, ctx: Context) -> Response {
  case req.method {
    Post -> auth_controller.refresh_access_token(req, ctx)
    _ -> wisp.method_not_allowed([Post])
  }
}

fn handle_users(req: Request, ctx: Context) -> Response {
  case req.method {
    Get -> user_controller.list(ctx)
    _ -> wisp.method_not_allowed([Get, Post])
  }
}

fn handle_user_profile(req: Request, ctx: Context) -> Response {
  case req.method {
    Get -> user_controller.get_profile(req, ctx)
    Put -> user_controller.update_profile(req, ctx)
    _ -> wisp.method_not_allowed([Get, Put])
  }
}

fn handle_recipes(req: Request, ctx: Context) -> Response {
  case req.method {
    Get -> recipe_controller.list(req, ctx)
    Post -> recipe_controller.create(req, ctx)
    _ -> wisp.method_not_allowed([Get, Post])
  }
}

fn handle_recipe(req: Request, ctx: Context, id: String) -> Response {
  case req.method {
    Get -> recipe_controller.show(req, ctx, id)
    Put -> recipe_controller.update(req, ctx, id)
    Delete -> recipe_controller.delete(req, ctx, id)
    _ -> wisp.method_not_allowed([Get, Put, Delete])
  }
}

fn handle_planned_meals(req: Request, ctx: Context) -> Response {
  case req.method {
    Get -> planned_meal_controller.list(req, ctx)
    Post -> planned_meal_controller.create(req, ctx)
    _ -> wisp.method_not_allowed([Get, Post])
  }
}

fn handle_planned_meal(req: Request, ctx: Context, id: String) -> Response {
  case req.method {
    Put -> planned_meal_controller.update(req, ctx, id)
    Delete -> planned_meal_controller.delete(req, ctx, id)
    _ -> wisp.method_not_allowed([Put, Delete])
  }
}

fn handle_shopping_list_items(req: Request, ctx: Context) -> Response {
  case req.method {
    Get -> shopping_list_item_controller.list(req, ctx)
    Post -> shopping_list_item_controller.create(req, ctx)
    _ -> wisp.method_not_allowed([Get, Post])
  }
}

fn handle_shopping_list_item(req: Request, ctx: Context, id: String) -> Response {
  case req.method {
    Put -> shopping_list_item_controller.update(req, ctx, id)
    Delete -> shopping_list_item_controller.delete(req, ctx, id)
    _ -> wisp.method_not_allowed([Put, Delete])
  }
}

fn handle_shopping_list_item_check(
  req: Request,
  ctx: Context,
  id: String,
) -> Response {
  case req.method {
    Put -> shopping_list_item_controller.check(req, ctx, id)
    _ -> wisp.method_not_allowed([Put])
  }
}

fn handle_shopping_list_item_uncheck(
  req: Request,
  ctx: Context,
  id: String,
) -> Response {
  case req.method {
    Put -> shopping_list_item_controller.uncheck(req, ctx, id)
    _ -> wisp.method_not_allowed([Put])
  }
}
