import filepath
import gleam/dict
import gleam/io
import gleam/list
import gleam/string
import gleeunit/should
import simplifile
import snowball_stemmer

const data_dir = "test/data"

pub fn test_full_list() {
  let test_cases = load_test_data()

  test_cases
  |> dict.keys
  |> list.map(fn(word) {
    io.println(word)
    let assert Ok(expected) = dict.get(test_cases, word)
    word |> snowball_stemmer.stem |> should.equal(expected)
  })

  Nil
}

fn load_test_data() -> dict.Dict(String, String) {
  let assert Ok(in) = simplifile.read(filepath.join(data_dir, "in.txt"))
  let assert Ok(out) = simplifile.read(filepath.join(data_dir, "out.txt"))

  let in = string.split(in, "\n")
  let out = string.split(out, "\n")

  list.zip(in, out) |> dict.from_list
}
