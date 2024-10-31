import domain/entities/ingredient.{type Ingredient}
import domain/entities/instruction.{type Instruction}
import domain/entities/recipe.{type Recipe}

pub type RecipeDetails {
  RecipeDetails(
    recipe: Recipe,
    ingredients: List(Ingredient),
    instructions: List(Instruction),
  )
}
