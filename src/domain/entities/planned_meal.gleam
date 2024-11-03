import birl.{type Day}
import domain/value_objects/meal_type.{type MealType}
import gleam/option.{type Option}
import youid/uuid.{type Uuid}

pub type PlannedMeal {
  PlannedMeal(
    id: Uuid,
    user_id: Uuid,
    recipe_id: Option(Uuid),
    meal_date: Day,
    meal_type: MealType,
    servings: Int,
  )
}
