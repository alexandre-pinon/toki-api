import gleam/result
import non_empty_list
import valid.{type Validator}
import youid/uuid.{type Uuid}

pub fn curry8(constructor: fn(a, b, c, d, e, f, g, h) -> value) {
  fn(a) {
    fn(b) {
      fn(c) {
        fn(d) {
          fn(e) {
            fn(f) {
              fn(g) { fn(h) { { constructor(a, b, c, d, e, f, g, h) } } }
            }
          }
        }
      }
    }
  }
}

pub fn curry10(constructor: fn(a, b, c, d, e, f, g, h, i, j) -> value) {
  fn(a) {
    fn(b) {
      fn(c) {
        fn(d) {
          fn(e) {
            fn(f) {
              fn(g) {
                fn(h) {
                  fn(i) { fn(j) { constructor(a, b, c, d, e, f, g, h, i, j) } }
                }
              }
            }
          }
        }
      }
    }
  }
}

pub fn build8(constructor: fn(a, b, c, d, e, f, g, h) -> value) {
  Ok(curry8(constructor))
}

pub fn build10(constructor: fn(a, b, c, d, e, f, g, h, i, j) -> value) {
  Ok(curry10(constructor))
}

pub fn string_is_uuid(error: e) -> Validator(String, Uuid, e) {
  fn(value: String) {
    uuid.from_string(value)
    |> result.replace_error(non_empty_list.new(error, []))
  }
}

pub fn float_min(min: Float, error: e) -> Validator(Float, Float, e) {
  fn(value: Float) {
    case value <. min {
      True -> Error(non_empty_list.new(error, []))
      False -> Ok(value)
    }
  }
}
