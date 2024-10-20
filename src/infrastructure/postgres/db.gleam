import env.{type DbConfig}
import gleam/option
import gleam/pgo

pub fn connect(db_config: DbConfig) -> pgo.Connection {
  pgo.connect(
    pgo.Config(
      ..pgo.default_config(),
      port: db_config.port,
      host: db_config.host,
      database: db_config.database,
      user: db_config.user,
      password: option.Some(db_config.password),
      pool_size: db_config.pool_size,
    ),
  )
}

pub fn disconnect(db: pgo.Connection) -> Nil {
  pgo.disconnect(db)
}
