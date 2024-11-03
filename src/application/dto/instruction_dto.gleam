import domain/entities/instruction.{type Instruction}
import valid.{type ValidatorResult}
import youid/uuid.{type Uuid}

pub type InstructionCreateRequest {
  InstructionCreateRequest(step_number: Int, instruction: String)
}

pub type InstructionCreateInput {
  InstructionCreateInput(step_number: Int, instruction: String)
}

pub fn validate_instruction_create_request(
  input: InstructionCreateRequest,
) -> ValidatorResult(InstructionCreateInput, String) {
  valid.build2(InstructionCreateInput)
  |> valid.check(
    input.step_number,
    valid.int_min(1, "step_number inferior to 1"),
  )
  |> valid.check(
    input.instruction,
    valid.string_is_not_empty("empty instruction"),
  )
}

pub fn to_entity(
  input: InstructionCreateInput,
  for recipe_id: Uuid,
) -> Instruction {
  instruction.Instruction(
    id: uuid.v4(),
    recipe_id: recipe_id,
    step_number: input.step_number,
    instruction: input.instruction,
  )
}
