import youid/uuid.{type Uuid}

pub type Instruction {
  Instruction(id: Uuid, recipe_id: Uuid, step_number: Int, instruction: String)
}
