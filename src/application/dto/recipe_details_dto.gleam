import application/dto/ingredient_dto.{
  type IngredientUpsertInput, type IngredientUpsertRequest,
}
import application/dto/instruction_dto.{
  type InstructionUpsertInput, type InstructionUpsertRequest,
}
import application/dto/recipe_dto.{
  type RecipeUpsertInput, type RecipeUpsertRequest,
}
import gleam/option.{type Option}
import valid.{type ValidatorResult}

pub type RecipeDetailsUpsertRequest {
  RecipeDetailsUpsertRequest(
    recipe: Option(RecipeUpsertRequest),
    ingredients: Option(List(IngredientUpsertRequest)),
    instructions: Option(List(InstructionUpsertRequest)),
  )
}

pub type RecipeDetailsUpsertInput {
  RecipeDetailsUpsertInput(
    recipe: Option(RecipeUpsertInput),
    ingredients: Option(List(IngredientUpsertInput)),
    instructions: Option(List(InstructionUpsertInput)),
  )
}

pub fn validate_recipe_details_upsert_request(
  input: RecipeDetailsUpsertRequest,
) -> ValidatorResult(RecipeDetailsUpsertInput, String) {
  valid.build3(RecipeDetailsUpsertInput)
  |> valid.check(
    input.recipe,
    valid.if_some(recipe_dto.validate_recipe_upsert_request),
  )
  |> valid.check(
    input.ingredients,
    valid.if_some(valid.list_every(
      ingredient_dto.validate_ingredient_upsert_request,
    )),
  )
  |> valid.check(
    input.instructions,
    valid.if_some(valid.list_every(
      instruction_dto.validate_instruction_upsert_request,
    )),
  )
}
