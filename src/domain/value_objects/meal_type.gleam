pub type MealType {
  Breakfast
  Lunch
  Dinner
  Snack
}

pub fn to_string(meal_type: MealType) -> String {
  case meal_type {
    Breakfast -> "breakfast"
    Lunch -> "lunch"
    Dinner -> "dinner"
    Snack -> "snack"
  }
}

pub fn from_string(meal_type: String) -> Result(MealType, Nil) {
  case meal_type {
    "breakfast" -> Ok(Breakfast)
    "lunch" -> Ok(Lunch)
    "dinner" -> Ok(Dinner)
    "snack" -> Ok(Snack)
    _ -> Error(Nil)
  }
}
