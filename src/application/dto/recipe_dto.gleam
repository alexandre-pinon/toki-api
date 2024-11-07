import application/dto/common_dto
import domain/entities/recipe.{type Recipe}
import domain/value_objects/cuisine_type.{type CuisineType}
import gleam/option.{type Option}
import valid.{type ValidatorResult}
import youid/uuid.{type Uuid}

pub type RecipeUpsertRequest {
  RecipeUpsertRequest(
    title: String,
    prep_time: Option(Int),
    cook_time: Option(Int),
    servings: Int,
    source_url: Option(String),
    image_url: Option(String),
    cuisine_type: Option(String),
    rating: Option(Int),
  )
}

pub type RecipeUpsertInput {
  RecipeUpsertInput(
    title: String,
    prep_time: Option(Int),
    cook_time: Option(Int),
    servings: Int,
    source_url: Option(String),
    image_url: Option(String),
    cuisine_type: Option(CuisineType),
    rating: Option(Int),
  )
}

pub fn validate_recipe_upsert_request(
  input: RecipeUpsertRequest,
) -> ValidatorResult(RecipeUpsertInput, String) {
  common_dto.build8(RecipeUpsertInput)
  |> valid.check(input.title, valid.string_is_not_empty("empty title"))
  |> valid.check(
    input.prep_time,
    valid.if_some(valid.int_min(0, "negative prep time")),
  )
  |> valid.check(
    input.cook_time,
    valid.if_some(valid.int_min(0, "negative cook time")),
  )
  |> valid.check(input.servings, valid.int_min(1, "servings inferior to 1"))
  |> valid.check(
    input.source_url,
    valid.if_some(valid.string_is_not_empty("empty source_url")),
  )
  |> valid.check(
    input.image_url,
    valid.if_some(valid.string_is_not_empty("empty image_url")),
  )
  |> valid.check(
    input.cuisine_type,
    valid.if_some(fn(input) { Ok(cuisine_type.from_string(input)) }),
  )
  |> valid.check(
    input.rating,
    valid.if_some(
      valid.int_min(1, "rating inferior to 1")
      |> valid.then(valid.int_max(5, "rating superior to 5")),
    ),
  )
}

pub fn to_entity(dto: RecipeUpsertInput, user_id: Uuid) -> Recipe {
  recipe.Recipe(
    id: uuid.v4(),
    user_id: user_id,
    title: dto.title,
    prep_time: dto.prep_time,
    cook_time: dto.cook_time,
    servings: dto.servings,
    source_url: dto.source_url,
    image_url: dto.image_url,
    cuisine_type: dto.cuisine_type,
    rating: dto.rating,
  )
}
