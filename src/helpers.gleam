import gleam/result
import gleam/string
import infrastructure/errors.{type DecoderError, InvalidUUID}
import youid/uuid

pub fn map_bit_array_to_string(ba: BitArray) -> Result(String, DecoderError) {
  ba
  |> uuid.from_bit_array
  |> result.map(uuid.to_string)
  |> result.map(string.lowercase)
  |> result.replace_error(InvalidUUID)
}
