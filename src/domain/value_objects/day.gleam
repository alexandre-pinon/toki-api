import birl.{type Day, type Time, type Weekday}

pub fn to_time(day: Day) -> Time {
  #(#(day.year, day.month, day.date), #(0, 0, 0))
  |> birl.from_erlang_universal_datetime
}

pub fn to_week_day(day: Day) -> Weekday {
  day |> to_time |> birl.weekday
}
