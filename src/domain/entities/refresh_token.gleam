import birl.{type Time}
import gleam/option.{type Option}
import youid/uuid.{type Uuid}

pub type RefreshToken {
  RefreshToken(
    id: Uuid,
    user_id: Uuid,
    token: String,
    expires_at: Time,
    revoked_at: Option(Time),
    replaced_at: Option(Time),
    replaced_by: Option(Uuid),
  )
}
