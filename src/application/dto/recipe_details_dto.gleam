import application/dto/ingredient_dto.{
  type IngredientCreateInput, type IngredientCreateRequest,
}
import application/dto/instruction_dto.{
  type InstructionCreateInput, type InstructionCreateRequest,
}
import application/dto/recipe_dto.{
  type RecipeCreateInput, type RecipeCreateRequest,
}
import valid.{type ValidatorResult}

pub type RecipeDetailsCreateRequest {
  RecipeDetailsCreateRequest(
    recipe: RecipeCreateRequest,
    ingredients: List(IngredientCreateRequest),
    instructions: List(InstructionCreateRequest),
  )
}

pub type RecipeDetailsCreateInput {
  RecipeDetailsCreateInput(
    recipe: RecipeCreateInput,
    ingredients: List(IngredientCreateInput),
    instructions: List(InstructionCreateInput),
  )
}

pub fn validate_recipe_details_create_request(
  input: RecipeDetailsCreateRequest,
) -> ValidatorResult(RecipeDetailsCreateInput, String) {
  valid.build3(RecipeDetailsCreateInput)
  |> valid.check(input.recipe, recipe_dto.validate_recipe_create_request)
  |> valid.check(
    input.ingredients,
    valid.list_every(ingredient_dto.validate_ingredient_create_request),
  )
  |> valid.check(
    input.instructions,
    valid.list_every(instruction_dto.validate_instruction_create_request),
  )
}
