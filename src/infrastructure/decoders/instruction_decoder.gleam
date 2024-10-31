import domain/entities/instruction.{type Instruction}
import gleam/dynamic.{type Decoder}
import gleam/pgo
import gleam/result
import infrastructure/decoders/common_decoder
import infrastructure/errors.{type DbError}
import youid/uuid

pub type InstructionRow {
  InstructionRow(
    id: BitArray,
    recipe_id: BitArray,
    step_number: Int,
    instruction: String,
  )
}

pub type InstructionJsonRow {
  InstructionJsonRow(
    id: String,
    recipe_id: String,
    step_number: Int,
    instruction: String,
  )
}

pub fn new() -> Decoder(InstructionRow) {
  dynamic.decode4(
    InstructionRow,
    dynamic.field("id", dynamic.bit_array),
    dynamic.field("recipe_id", dynamic.bit_array),
    dynamic.field("step_number", dynamic.int),
    dynamic.field("instruction", dynamic.string),
  )
}

pub fn from_json() -> Decoder(InstructionJsonRow) {
  dynamic.decode4(
    InstructionJsonRow,
    dynamic.field("id", dynamic.string),
    dynamic.field("recipe_id", dynamic.string),
    dynamic.field("step_number", dynamic.int),
    dynamic.field("instruction", dynamic.string),
  )
}

pub fn from_domain_to_db(instruction: Instruction) -> List(pgo.Value) {
  [
    pgo.text(uuid.to_string(instruction.id)),
    pgo.text(uuid.to_string(instruction.recipe_id)),
    pgo.int(instruction.step_number),
    pgo.text(instruction.instruction),
  ]
}

pub fn from_db_to_domain(
  instruction_row: InstructionRow,
) -> Result(Instruction, DbError) {
  let InstructionRow(id, recipe_id, step_number, instruction) = instruction_row

  use id <- result.try(common_decoder.from_db_uuid_to_domain_uuid(id))
  use recipe_id <- result.try(common_decoder.from_db_uuid_to_domain_uuid(
    recipe_id,
  ))

  Ok(instruction.Instruction(id, recipe_id, step_number, instruction))
}

pub fn from_json_db_to_domain(
  instruction_json_row: InstructionJsonRow,
) -> Result(Instruction, DbError) {
  let InstructionJsonRow(id, recipe_id, step_number, instruction) =
    instruction_json_row

  use id <- result.try(common_decoder.from_json_db_uuid_to_domain_uuid(id))
  use recipe_id <- result.try(common_decoder.from_json_db_uuid_to_domain_uuid(
    recipe_id,
  ))

  Ok(instruction.Instruction(id, recipe_id, step_number, instruction))
}
