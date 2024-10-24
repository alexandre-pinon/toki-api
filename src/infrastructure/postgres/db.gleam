import app_logger
import env.{type DbConfig}
import gleam/dynamic
import gleam/option.{Some}
import gleam/pgo
import gleam/result
import gleam/string
import infrastructure/errors.{type DbError, ExecutionFailed}
import wisp

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
    ),
  )
}

pub fn disconnect(db: pgo.Connection) -> Nil {
  pgo.disconnect(db)
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
