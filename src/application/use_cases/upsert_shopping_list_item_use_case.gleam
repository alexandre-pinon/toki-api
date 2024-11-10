import application/context.{type AuthContext}
import application/dto/ingredient_dto.{
  type IngredientUpsertInput, type IngredientUpsertRequest,
}
import domain/entities/shopping_list_item.{type ShoppingListItem}
import domain/value_objects/unit_type
import gleam/option.{None}
import gleam/result
import infrastructure/errors.{type DbError}
import infrastructure/repositories/shopping_list_item_repository
import valid.{type NonEmptyList}
import youid/uuid.{type Uuid}

pub type UpsertShoppingListItemUseCasePort {
  UpsertShoppingListItemUseCasePort(id: Uuid, data: IngredientUpsertRequest)
}

type UpsertShoppingListItemUseCaseResult =
  ShoppingListItem

pub type UpsertShoppingListItemUseCaseErrors {
  ValidationFailed(NonEmptyList(String))
  QueryFailed(DbError)
}

pub fn execute(
  port: UpsertShoppingListItemUseCasePort,
  auth_ctx: AuthContext,
) -> Result(
  UpsertShoppingListItemUseCaseResult,
  UpsertShoppingListItemUseCaseErrors,
) {
  use validated_input <- result.try(validate_input(port))

  shopping_list_item.ShoppingListItem(
    id: port.id,
    user_id: auth_ctx.user_id,
    planned_meal_id: None,
    name: validated_input.name,
    unit: validated_input.unit,
    unit_family: validated_input.unit |> option.map(unit_type.to_family),
    quantity: validated_input.quantity,
    meal_date: None,
    checked: False,
  )
  |> shopping_list_item_repository.upsert(auth_ctx.ctx.pool)
  |> result.map_error(QueryFailed)
}

fn validate_input(
  port: UpsertShoppingListItemUseCasePort,
) -> Result(IngredientUpsertInput, UpsertShoppingListItemUseCaseErrors) {
  ingredient_dto.validate_ingredient_upsert_request(port.data)
  |> result.map_error(ValidationFailed)
}
