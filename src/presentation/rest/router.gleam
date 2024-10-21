import application/context.{type Context}
import birl
import common/errors.{log_error}
import gleam/bit_array
import gleam/dynamic
import gleam/io
import gleam/json
import gleam/option
import gleam/pgo
import gleam/result
import gleam/string
import wisp.{type Request, type Response}
import youid/uuid.{type Uuid}

pub fn handle_request(req: Request, context: Context) -> Response {
  case req.path {
    "/" -> wisp.ok()
    "/users" -> {
      let query =
        "SELECT id, email, name, google_id, created_at::timestamp(0), updated_at::timestamp(0) FROM users;"
      let decoder =
        dynamic.tuple6(
          dynamic.bit_array,
          dynamic.string,
          dynamic.string,
          dynamic.optional(dynamic.string),
          dynamic.tuple2(
            dynamic.tuple3(dynamic.int, dynamic.int, dynamic.int),
            dynamic.tuple3(dynamic.int, dynamic.int, dynamic.int),
          ),
          dynamic.optional(dynamic.tuple2(
            dynamic.tuple3(dynamic.int, dynamic.int, dynamic.int),
            dynamic.tuple3(dynamic.int, dynamic.int, dynamic.int),
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
            #("id", json.string(decode_bit_array(row.0))),
            #("email", json.string(row.1)),
            #("name", json.string(row.2)),
            #("google_id", json.nullable(row.3, json.string)),
            #(
              "created_at",
              json.string(
                birl.from_erlang_universal_datetime(row.4) |> birl.to_iso8601,
              ),
            ),
            #(
              "updated_at",
              json.nullable(
                row.5
                  |> option.map(birl.from_erlang_universal_datetime)
                  |> option.map(birl.to_iso8601),
                json.string,
              ),
            ),
          ])
        })

      wisp.json_response(json.to_string_builder(json), 200)
    }
    _ -> wisp.not_found()
  }
}

fn decode_bit_array(ba: BitArray) -> String {
  ba
  |> uuid.from_bit_array
  |> result.map(uuid.to_string)
  |> result.map(string.lowercase)
  |> result.lazy_unwrap(fn() { panic })
}
