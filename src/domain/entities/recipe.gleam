import domain/value_objects/cuisine_type.{type CuisineType}
import gleam/option.{type Option}
import youid/uuid.{type Uuid}

pub type Recipe {
  Recipe(
    id: Uuid,
    user_id: Uuid,
    title: String,
    prep_time: Option(Int),
    cook_time: Option(Int),
    servings: Option(Int),
    source_url: Option(String),
    image_url: Option(String),
    cuisine_type: Option(CuisineType),
  )
}
