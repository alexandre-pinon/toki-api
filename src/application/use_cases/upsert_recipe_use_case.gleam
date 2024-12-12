import application/context.{type AuthContext}
import application/dto/ingredient_dto.{type IngredientUpsertInput}
import application/dto/instruction_dto.{type InstructionUpsertInput}
import application/dto/recipe_details_dto.{
  type RecipeDetailsUpsertInput, type RecipeDetailsUpsertRequest,
}
import application/dto/recipe_dto.{type RecipeUpsertInput}
import domain/entities/ingredient.{type Ingredient}
import domain/entities/instruction.{type Instruction}
import domain/entities/recipe.{type Recipe}
import domain/entities/recipe_details.{type RecipeDetails}
import gleam/list
import gleam/option.{type Option, None, Some}
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

fn validate_input(
  port: UpsertRecipeUseCasePort,
) -> Result(RecipeDetailsUpsertInput, UpsertRecipeUseCaseErrors) {
  recipe_details_dto.validate_recipe_details_upsert_request(port.data)
  |> result.map_error(ValidationFailed)
}

fn upsert_recipe_details(
  recipe_id id: Uuid,
  with input: RecipeDetailsUpsertInput,
  for user_id: Uuid,
) -> Transactional(Result(RecipeDetails, String)) {
  fn(transaction: pgo.Connection) {
    use recipe <- result.try(upsert_recipe(
      id,
      input.recipe,
      user_id,
      transaction,
    ))
    use ingredients <- result.try(upsert_ingredients(
      recipe.id,
      input.ingredients,
      transaction,
    ))
    use instructions <- result.try(upsert_instructions(
      recipe.id,
      input.instructions,
      transaction,
    ))

    Ok(recipe_details.RecipeDetails(recipe, ingredients, instructions))
  }
}

fn upsert_recipe(
  id: Uuid,
  maybe_recipe: Option(RecipeUpsertInput),
  user_id: Uuid,
  transaction: pgo.Connection,
) -> Result(Recipe, String) {
  case maybe_recipe {
    Some(recipe) ->
      recipe_repository.upsert(
        recipe.Recipe(..recipe_dto.to_entity(recipe, user_id), id: id),
        transaction,
      )
      |> result.replace_error("upsert recipe failed")
    None ->
      recipe_repository.find_by_id(id, user_id, transaction)
      |> result.replace_error("find recipe by id failed")
      |> result.then(option.to_result(_, "recipe not found"))
  }
}

fn upsert_ingredients(
  recipe_id: Uuid,
  maybe_ingredients: Option(List(IngredientUpsertInput)),
  transaction: pgo.Connection,
) -> Result(List(Ingredient), String) {
  case maybe_ingredients {
    Some(ingredients) -> {
      use _ <- result.try(
        ingredient_repository.delete_recipe_ingredients(recipe_id, transaction)
        |> result.replace_error("delete recipe ingredients failed"),
      )

      ingredient_repository.bulk_create(
        list.map(ingredients, ingredient_dto.to_entity(_, recipe_id)),
        transaction,
      )
      |> result.replace_error("bulk insert ingredient failed")
    }
    None ->
      ingredient_repository.find_all_by_recipe_id(recipe_id, transaction)
      |> result.replace_error("find ingredients by recipe_id failed")
  }
}

fn upsert_instructions(
  recipe_id: Uuid,
  maybe_instructions: Option(List(InstructionUpsertInput)),
  transaction: pgo.Connection,
) -> Result(List(Instruction), String) {
  case maybe_instructions {
    Some(instructions) -> {
      use _ <- result.try(
        instruction_repository.delete_recipe_instructions(
          recipe_id,
          transaction,
        )
        |> result.replace_error("delete recipe instructions failed"),
      )
      instruction_repository.bulk_create(
        list.map(instructions, instruction_dto.to_entity(_, recipe_id)),
        transaction,
      )
      |> result.replace_error("bulk insert instruction failed")
    }
    None ->
      instruction_repository.find_all_by_recipe_id(recipe_id, transaction)
      |> result.replace_error("find instructions by recipe_id failed")
  }
}
