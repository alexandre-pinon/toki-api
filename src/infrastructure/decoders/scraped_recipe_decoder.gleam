import birl/duration
import domain/entities/scraped_recipe.{
  type ScrapedIngredient, type ScrapedInstruction, type ScrapedRecipe,
}
import domain/value_objects/unit_type
import gleam/dynamic.{type Decoder}
import gleam/list
import gleam/option.{type Option}

pub type ScrapedRecipeRaw {
  ScrapedRecipeRaw(
    title: Option(String),
    prep_time: Option(String),
    cook_time: Option(String),
    servings: Option(Int),
    source_url: Option(String),
    image_url: Option(String),
    ingredients: List(ScrapedIngredientRaw),
    instructions: List(ScrapedInstructionRaw),
  )
}

pub type ScrapedIngredientRaw {
  ScrapedIngredientRaw(
    name: String,
    quantity: Option(Float),
    unit: Option(String),
  )
}

pub type ScrapedInstructionRaw {
  ScrapedInstructionRaw(step_number: Int, instruction: String)
}

pub fn new() -> Decoder(ScrapedRecipeRaw) {
  dynamic.decode8(
    ScrapedRecipeRaw,
    dynamic.field("title", dynamic.optional(dynamic.string)),
    dynamic.field("prep_time", dynamic.optional(dynamic.string)),
    dynamic.field("cook_time", dynamic.optional(dynamic.string)),
    dynamic.field("servings", dynamic.optional(dynamic.int)),
    dynamic.field("source_url", dynamic.optional(dynamic.string)),
    dynamic.field("image_url", dynamic.optional(dynamic.string)),
    dynamic.field(
      "ingredients",
      dynamic.list(dynamic.decode3(
        ScrapedIngredientRaw,
        dynamic.field("name", dynamic.string),
        dynamic.field("quantity", dynamic.optional(dynamic.float)),
        dynamic.field("unit", dynamic.optional(dynamic.string)),
      )),
    ),
    dynamic.field(
      "instructions",
      dynamic.list(dynamic.decode2(
        ScrapedInstructionRaw,
        dynamic.field("step_number", dynamic.int),
        dynamic.field("instruction", dynamic.string),
      )),
    ),
  )
}

pub fn from_raw_to_domain(scraped_recipe_raw: ScrapedRecipeRaw) -> ScrapedRecipe {
  let prep_time =
    from_optional_duration_string_to_minutes(scraped_recipe_raw.prep_time)
  let cook_time =
    from_optional_duration_string_to_minutes(scraped_recipe_raw.cook_time)
  let ingredients =
    scraped_recipe_raw.ingredients
    |> list.map(from_scraped_ingredient_raw_to_domain)
  let instructions =
    scraped_recipe_raw.instructions
    |> list.map(from_scraped_instruction_raw_to_domain)

  scraped_recipe.ScrapedRecipe(
    title: scraped_recipe_raw.title,
    prep_time: prep_time,
    cook_time: cook_time,
    servings: scraped_recipe_raw.servings,
    source_url: scraped_recipe_raw.source_url,
    image_url: scraped_recipe_raw.image_url,
    ingredients: ingredients,
    instructions: instructions,
  )
}

fn from_scraped_ingredient_raw_to_domain(
  scraped_ingredient_raw: ScrapedIngredientRaw,
) -> ScrapedIngredient {
  scraped_recipe.ScrapedIngredient(
    name: scraped_ingredient_raw.name,
    quantity: scraped_ingredient_raw.quantity,
    unit: scraped_ingredient_raw.unit |> option.map(unit_type.from_string),
  )
}

fn from_scraped_instruction_raw_to_domain(
  scraped_instruction_raw: ScrapedInstructionRaw,
) -> ScrapedInstruction {
  scraped_recipe.ScrapedInstruction(
    step_number: scraped_instruction_raw.step_number,
    instruction: scraped_instruction_raw.instruction,
  )
}

fn from_optional_duration_string_to_minutes(
  maybe_duration: Option(String),
) -> Option(Int) {
  maybe_duration
  |> option.map(duration.parse(_))
  |> option.map(option.from_result)
  |> option.flatten
  |> option.map(duration.blur_to(_, duration.Minute))
}
