import application/context.{type AuthContext, type Context}
import gjwt
import gjwt/claim
import gjwt/key.{type Key}
import gleam/list
import gleam/option.{type Option, None, Some}
import gleam/pair
import gleam/result
import gleam/string
import wisp.{type Request, type Response}
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

pub fn require_auth(
  req: Request,
  ctx: Context,
  next: fn(AuthContext) -> Response,
) -> Response {
  case find_auth_jwt(req) {
    Some(jwt) -> {
      let key = key.from_string(ctx.token_config.jwt_secret_key, "HS256")
      case gjwt.verify(jwt, key) {
        True -> parse_auth_context(jwt, key, ctx, next)
        False -> wisp.response(401)
      }
    }
    None -> wisp.response(401)
  }
}

fn find_auth_jwt(req: Request) -> Option(String) {
  req.headers
  |> list.find(fn(header) { pair.first(header) == "authorization" })
  |> result.map(pair.second)
  |> result.map(string.split(_, "Bearer "))
  |> result.then(list.last)
  |> option.from_result
}

fn parse_auth_context(
  jwt: String,
  key: Key,
  ctx: Context,
  next: fn(AuthContext) -> Response,
) -> Response {
  let parsed_result =
    gjwt.from_jwt(jwt, key)
    |> result.then(fn(verified_jwt) {
      claim.get_subject({ verified_jwt.1 }.claims) |> result.replace_error(Nil)
    })
    |> result.then(uuid.from_string)

  case parsed_result {
    Ok(user_id) -> next(context.AuthContext(user_id, ctx))
    Error(_) -> wisp.response(401)
  }
}
