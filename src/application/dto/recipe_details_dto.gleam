import application/dto/ingredient_dto.{
  type IngredientUpsertInput, type IngredientUpsertRequest,
}
import application/dto/instruction_dto.{
  type InstructionUpsertInput, type InstructionUpsertRequest,
}
import application/dto/recipe_dto.{
  type RecipeUpsertInput, type RecipeUpsertRequest,
}
import valid.{type ValidatorResult}

pub type RecipeDetailsUpsertRequest {
  RecipeDetailsUpsertRequest(
    recipe: RecipeUpsertRequest,
    ingredients: List(IngredientUpsertRequest),
    instructions: List(InstructionUpsertRequest),
  )
}

pub type RecipeDetailsUpsertInput {
  RecipeDetailsUpsertInput(
    recipe: RecipeUpsertInput,
    ingredients: List(IngredientUpsertInput),
    instructions: List(InstructionUpsertInput),
  )
}

pub fn validate_recipe_details_upsert_request(
  input: RecipeDetailsUpsertRequest,
) -> ValidatorResult(RecipeDetailsUpsertInput, String) {
  valid.build3(RecipeDetailsUpsertInput)
  |> valid.check(input.recipe, recipe_dto.validate_recipe_upsert_request)
  |> valid.check(
    input.ingredients,
    valid.list_every(ingredient_dto.validate_ingredient_upsert_request),
  )
  |> valid.check(
    input.instructions,
    valid.list_every(instruction_dto.validate_instruction_upsert_request),
  )
}
