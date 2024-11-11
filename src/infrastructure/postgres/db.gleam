import app_logger
import env.{type DbConfig}
import gleam/dynamic
import gleam/int
import gleam/list
import gleam/option.{Some}
import gleam/pgo
import gleam/result
import gleam/string
import infrastructure/errors.{type DbError, ExecutionFailed}
import wisp

pub type Transactional(a) =
  fn(pgo.Connection) -> a

pub fn connect(db_config: DbConfig) -> pgo.Connection {
  pgo.connect(
    pgo.Config(
      ..pgo.default_config(),
      port: db_config.port,
      host: db_config.host,
      database: db_config.database,
      user: db_config.user,
      password: Some(db_config.password),
      pool_size: db_config.pool_size,
      trace: True,
      rows_as_map: True,
    ),
  )
}

pub fn disconnect(db: pgo.Connection) -> Nil {
  pgo.disconnect(db)
}

pub fn check_connection(pool: pgo.Connection) -> Result(Nil, pgo.QueryError) {
  case pgo.execute("SELECT 1;", pool, [], dynamic.dynamic) {
    Ok(_) -> {
      wisp.log_info("✅ Database connection successful")
      Ok(Nil)
    }
    Error(error) -> {
      wisp.log_critical("❌ Database connection failed")
      Error(error)
    }
  }
}

pub fn execute(
  query sql: String,
  on pool: pgo.Connection,
  with arguments: List(pgo.Value),
  expecting decoder: dynamic.Decoder(t),
) -> Result(pgo.Returned(t), DbError) {
  wisp.log_debug(
    "Executing query: "
    <> sql
    <> "\n"
    <> "With arguments"
    <> string.inspect(arguments),
  )

  sql
  |> pgo.execute(pool, arguments, decoder)
  |> result.map_error(app_logger.log_error)
  |> result.map_error(ExecutionFailed)
}

pub fn generate_values_clause(rows: List(a), params_per_row: Int) -> String {
  list.range(0, list.length(rows) - 1)
  |> list.map(generate_row_placeholders(_, params_per_row))
  |> string.join(", ")
}

fn generate_row_placeholders(row_index: Int, params_per_row: Int) {
  let start = row_index * params_per_row + 1

  let all_values =
    list.range(start, start + params_per_row - 1)
    |> list.map(fn(i) { "$" <> int.to_string(i) })
    |> list.append(["DEFAULT", "NOW()"])
    |> string.join(", ")

  "(" <> all_values <> ")"
}
