import application/context.{type AuthContext}
import application/dto/ingredient_dto
import application/dto/instruction_dto
import application/dto/recipe_details_dto.{
  type RecipeDetailsUpsertInput, type RecipeDetailsUpsertRequest,
}
import application/dto/recipe_dto
import domain/entities/recipe
import domain/entities/recipe_details.{type RecipeDetails}
import gleam/list
import gleam/pgo
import gleam/result
import infrastructure/postgres/db.{type Transactional}
import infrastructure/repositories/ingredient_repository
import infrastructure/repositories/instruction_repository
import infrastructure/repositories/recipe_repository
import valid.{type NonEmptyList}
import youid/uuid.{type Uuid}

pub type UpsertRecipeUseCasePort {
  UpsertRecipeUseCasePort(id: Uuid, data: RecipeDetailsUpsertRequest)
}

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

  pgo.transaction(
    auth_ctx.ctx.pool,
    upsert_recipe_details(
      recipe_id: port.id,
      with: validated_input,
      for: auth_ctx.user_id,
    ),
  )
  |> result.map_error(TransactionFailed)
}

fn upsert_recipe_details(
  recipe_id id: Uuid,
  with input: RecipeDetailsUpsertInput,
  for user_id: Uuid,
) -> Transactional(Result(RecipeDetails, String)) {
  fn(transaction: pgo.Connection) {
    use recipe <- result.try(
      recipe_repository.upsert(
        recipe.Recipe(..recipe_dto.to_entity(input.recipe, user_id), id: id),
        transaction,
      )
      |> result.replace_error("upsert recipe failed"),
    )

    use _ <- result.try(
      ingredient_repository.delete_recipe_ingredients(recipe.id, transaction)
      |> result.replace_error("delete recipe ingredients failed"),
    )
    use ingredients <- result.try(
      ingredient_repository.bulk_insert(
        list.map(input.ingredients, ingredient_dto.to_entity(_, recipe.id)),
        transaction,
      )
      |> result.replace_error("bulk insert ingredient failed"),
    )

    use _ <- result.try(
      instruction_repository.delete_recipe_instructions(recipe.id, transaction)
      |> result.replace_error("delete recipe instructions failed"),
    )
    use instructions <- result.try(
      instruction_repository.bulk_insert(
        list.map(input.instructions, instruction_dto.to_entity(_, recipe.id)),
        transaction,
      )
      |> result.replace_error("bulk insert instruction failed"),
    )

    Ok(recipe_details.RecipeDetails(recipe, ingredients, instructions))
  }
}

fn validate_input(
  port: UpsertRecipeUseCasePort,
) -> Result(RecipeDetailsUpsertInput, UpsertRecipeUseCaseErrors) {
  recipe_details_dto.validate_recipe_details_upsert_request(port.data)
  |> result.map_error(ValidationFailed)
}
