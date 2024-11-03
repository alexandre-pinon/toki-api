import application/context.{type AuthContext}
import application/dto/ingredient_dto
import application/dto/instruction_dto
import application/dto/recipe_details_dto.{
  type RecipeDetailsCreateInput, type RecipeDetailsCreateRequest,
}
import application/dto/recipe_dto
import domain/entities/recipe_details.{type RecipeDetails}
import gleam/list
import gleam/pgo
import gleam/result
import infrastructure/repositories/ingredient_repository
import infrastructure/repositories/instruction_repository
import infrastructure/repositories/recipe_repository
import valid.{type NonEmptyList}
import youid/uuid.{type Uuid}

pub type UpsertRecipeUseCasePort =
  RecipeDetailsCreateRequest

pub type UpsertRecipeUseCaseResult =
  RecipeDetails

pub type UpsertRecipeUseCaseErrors {
  ValidationFailed(NonEmptyList(String))
  TransactionFailed(pgo.TransactionError)
}

pub fn execute(
  port: UpsertRecipeUseCasePort,
  auth_ctx: AuthContext,
) -> Result(UpsertRecipeUseCaseResult, UpsertRecipeUseCaseErrors) {
  use validated_input <- result.try(validate_input(port))

  pgo.transaction(auth_ctx.ctx.pool, create_recipe_details(
    validated_input,
    auth_ctx.user_id,
    _,
  ))
  |> result.map_error(TransactionFailed)
}

fn create_recipe_details(
  input: RecipeDetailsCreateInput,
  user_id: Uuid,
  transaction: pgo.Connection,
) -> Result(RecipeDetails, String) {
  use recipe <- result.try(
    recipe_repository.upsert(
      recipe_dto.to_entity(input.recipe, user_id),
      transaction,
    )
    |> result.replace_error("upsert recipe failed"),
  )

  use ingredients <- result.try(
    ingredient_repository.bulk_upsert(
      list.map(input.ingredients, ingredient_dto.to_entity(_, recipe.id)),
      transaction,
    )
    |> result.replace_error("bulk upsert ingredient failed"),
  )

  use instructions <- result.try(
    instruction_repository.bulk_upsert(
      list.map(input.instructions, instruction_dto.to_entity(_, recipe.id)),
      transaction,
    )
    |> result.replace_error("bulk upsert instruction failed"),
  )

  Ok(recipe_details.RecipeDetails(recipe, ingredients, instructions))
}

fn validate_input(
  port: UpsertRecipeUseCasePort,
) -> Result(RecipeDetailsCreateInput, UpsertRecipeUseCaseErrors) {
  recipe_details_dto.validate_recipe_details_create_request(port)
  |> result.map_error(ValidationFailed)
}
