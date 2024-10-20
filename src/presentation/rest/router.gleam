import application/context.{type Context}
import gleam/bit_array
import gleam/dynamic
import gleam/io
import gleam/json
import gleam/option
import gleam/pgo
import gleam/result
import wisp.{type Request, type Response}

pub fn handle_request(req: Request, context: Context) -> Response {
  case req.path {
    "/" -> wisp.ok()
    "/users" -> {
      let query = "SELECT * FROM users;"
      let decoder =
        dynamic.tuple6(
          dynamic.bit_array,
          dynamic.string,
          dynamic.string,
          dynamic.optional(dynamic.string),
          dynamic.tuple2(
            dynamic.tuple3(dynamic.int, dynamic.int, dynamic.int),
            dynamic.tuple3(dynamic.int, dynamic.int, dynamic.float),
          ),
          dynamic.optional(dynamic.tuple2(
            dynamic.tuple3(dynamic.int, dynamic.int, dynamic.int),
            dynamic.tuple3(dynamic.int, dynamic.int, dynamic.float),
          )),
        )
      let result = pgo.execute(query, context.db, [], decoder)
      io.debug(result)
      let rows = case result {
        Ok(result) -> result.rows
        Error(_) -> []
      }
      let json =
        json.array(rows, fn(row) {
          json.object([
            #("id", json.string(result.unwrap(bit_array.to_string(row.0), ""))),
            #("email", json.string(row.1)),
            #("name", json.string(row.2)),
            #("google_id", json.nullable(row.3, json.string)),
            // #("created_at", json.int({ row.4 }.0)),
          // #(
          //   "updated_at",
          //   json.nullable(option.map(row.5, fn(t) { t.0 }), json.int),
          // ),
          ])
        })

      wisp.json_response(json.to_string_builder(json), 200)
    }
    _ -> wisp.not_found()
  }
}
