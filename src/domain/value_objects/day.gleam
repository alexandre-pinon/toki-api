import birl.{
  type Day, type Time, type Weekday, Fri, Mon, Sat, Sun, Thu, Tue, Wed,
}
import gleam/int
import gleam/string

pub fn to_time(day: Day) -> Time {
  #(#(day.year, day.month, day.date), #(0, 0, 0))
  |> birl.from_erlang_universal_datetime
}

pub fn to_week_day(day: Day) -> Weekday {
  day |> to_time |> birl.weekday
}

pub fn weekday_from_int(weekday: Int) -> Result(Weekday, Nil) {
  case weekday {
    1 -> Ok(Mon)
    2 -> Ok(Tue)
    3 -> Ok(Wed)
    4 -> Ok(Thu)
    5 -> Ok(Fri)
    6 -> Ok(Sat)
    7 -> Ok(Sun)
    _ -> Error(Nil)
  }
}

pub fn to_json_string(day: Day) -> String {
  int.to_string(day.year)
  <> "-"
  <> day.month
  |> int.to_string
  |> string.pad_left(2, "0")
  <> "-"
  <> day.date
  |> int.to_string
  |> string.pad_left(2, "0")
}
