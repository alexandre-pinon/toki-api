import domain/entities/instruction.{type Instruction}
import gleam/list
import gleam/pgo
import gleam/result
import gleam/string
import infrastructure/decoders/instruction_decoder
import infrastructure/errors.{type DbError}
import infrastructure/postgres/db

pub fn bulk_upsert(
  instructions: List(Instruction),
  on pool: pgo.Connection,
) -> Result(List(Instruction), DbError) {
  let query_input =
    instructions
    |> list.flat_map(instruction_decoder.from_domain_to_db)

  use query_result <- result.try(
    "INSERT INTO instructions (id, recipe_id, step_number, instruction, created_at, updated_at) VALUES"
    |> string.append(db.generate_values_clause(instructions, 4))
    |> string.append(
      "
        ON CONFLICT (step_number, recipe_id) DO UPDATE SET
          instruction = EXCLUDED.instruction,
          updated_at = NOW()
        RETURNING id, recipe_id, step_number, instruction
      ",
    )
    |> db.execute(pool, query_input, instruction_decoder.new()),
  )

  query_result.rows
  |> list.try_map(instruction_decoder.from_db_to_domain)
}
