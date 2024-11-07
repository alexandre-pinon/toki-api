pub type UnitTypeFamily {
  Weight
  Volume
  Other
}

pub fn to_string(unit_type_family: UnitTypeFamily) -> String {
  case unit_type_family {
    Weight -> "weight"
    Volume -> "volume"
    Other -> "other"
  }
}

pub fn from_string(unit_type_family: String) -> Result(UnitTypeFamily, Nil) {
  case unit_type_family {
    "weight" -> Ok(Weight)
    "volume" -> Ok(Volume)
    "other" -> Ok(Other)
    _ -> Error(Nil)
  }
}
