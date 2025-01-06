import domain/value_objects/unit_type_family.{type UnitTypeFamily}

pub type UnitType {
  Ml
  Cl
  Dl
  L
  G
  Kg
  Tsp
  Tbsp
  Cup
  Piece
  Pinch
  Bunch
  Clove
  Can
  Package
  Slice
  ToTaste
  Unit
}

pub fn to_string(unit_type: UnitType) -> String {
  case unit_type {
    Ml -> "ml"
    Cl -> "cl"
    Dl -> "dl"
    L -> "l"
    G -> "g"
    Kg -> "kg"
    Tsp -> "tsp"
    Tbsp -> "tbsp"
    Cup -> "cup"
    Piece -> "piece"
    Pinch -> "pinch"
    Bunch -> "bunch"
    Clove -> "clove"
    Can -> "can"
    Package -> "package"
    Slice -> "slice"
    ToTaste -> "to taste"
    Unit -> "unit"
  }
}

pub fn from_string(unit_type: String) -> UnitType {
  case unit_type {
    "ml" -> Ml
    "cl" -> Cl
    "dl" -> Dl
    "l" -> L
    "g" -> G
    "kg" -> Kg
    "cuillère à café" | "tsp" -> Tsp
    "cuillère à soupe" | "tbsp" -> Tbsp
    "tasse" | "cup" -> Cup
    "pièce" | "piece" -> Piece
    "pincée" | "pinch" -> Pinch
    "botte" | "bunch" -> Bunch
    "gousse" | "clove" -> Clove
    "bocal" | "boîte" | "can" -> Can
    "sachet" | "paquet" | "package" -> Package
    "tranche" | "slice" -> Slice
    "selon le goût" | "to taste" -> ToTaste
    _ -> Unit
  }
}

pub fn to_family(unit_type: UnitType) -> UnitTypeFamily {
  case unit_type {
    Ml | Cl | Dl | L -> unit_type_family.Volume
    G | Kg -> unit_type_family.Weight
    _ -> unit_type_family.Other
  }
}
