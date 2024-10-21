import gleam/pgo

pub type Context {
  Context(pool: pgo.Connection)
}
