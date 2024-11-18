import domain/value_objects/unit_type.{type UnitType}
import gleam/option.{type Option}

pub type ScrapedRecipe {
  ScrapedRecipe(
    title: Option(String),
    prep_time: Option(Int),
    cook_time: Option(Int),
    servings: Option(Int),
    source_url: Option(String),
    image_url: Option(String),
    ingredients: List(ScrapedIngredient),
    instructions: List(ScrapedInstruction),
  )
}

pub type ScrapedIngredient {
  ScrapedIngredient(
    name: String,
    quantity: Option(Float),
    unit: Option(UnitType),
  )
}

pub type ScrapedInstruction {
  ScrapedInstruction(step_number: Int, instruction: String)
}
