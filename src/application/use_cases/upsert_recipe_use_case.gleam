import application/context.{type AuthContext}
import application/dto/recipe_details_dto.{
  type RecipeDetailsCreateInput, type RecipeDetailsCreateRequest,
}
import application/dto/recipe_dto
import domain/entities/recipe_details.{type RecipeDetails}
import gleam/result
import infrastructure/errors.{type DbError}
import infrastructure/repositories/recipe_repository
import valid.{type NonEmptyList}

pub type UpsertRecipeUseCasePort =
  RecipeDetailsCreateRequest

pub type UpsertRecipeUseCaseResult =
  RecipeDetails

pub type UpsertRecipeUseCaseErrors {
  ValidationFailed(NonEmptyList(String))
  QueryFailed(DbError)
}

pub fn execute(
  port: UpsertRecipeUseCasePort,
  auth_ctx: AuthContext,
) -> Result(UpsertRecipeUseCaseResult, UpsertRecipeUseCaseErrors) {
  use validated_input <- result.try(validate_input(port))

  use recipe <- result.try(
    recipe_repository.upsert(
      recipe_dto.to_entity(validated_input.recipe, auth_ctx.user_id),
      auth_ctx.ctx.pool,
    )
    |> result.map_error(QueryFailed),
  )

  Ok(recipe_details.RecipeDetails(recipe, [], []))
}

fn validate_input(
  port: UpsertRecipeUseCasePort,
) -> Result(RecipeDetailsCreateInput, UpsertRecipeUseCaseErrors) {
  recipe_details_dto.validate_recipe_details_create_request(port)
  |> result.map_error(ValidationFailed)
}
