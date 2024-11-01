import valid.{type ValidatorResult}

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
