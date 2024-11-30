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

pub type MealRecipe {
  MealRecipe(title: String, image_url: Option(String))
}

pub type PlannedMealWithRecipe {
  PlannedMealWithRecipe(meal: PlannedMeal, recipe: MealRecipe)
}
