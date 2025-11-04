import filepath
import gleam/dict
import gleam/io
import gleam/list
import gleam/string
import gleamy/bench
import gleeunit/should
import porter_stemmer
import simplifile
import snowball_stemmer

const data_dir = "test/data"

pub fn test_full_list() {
  let test_cases = load_test_data()

  test_cases
  |> dict.keys
  |> list.map(fn(word) {
    let assert Ok(expected) = dict.get(test_cases, word)
    word |> snowball_stemmer.stem |> should.equal(expected)
  })

  Nil
}

pub fn bench() {
  let test_cases = load_test_data() |> dict.keys()

  bench.run(
    [bench.Input("all words", test_cases)],
    [
      bench.Function("snowball", fn(words) {
        words |> list.map(snowball_stemmer.stem)
      }),
      bench.Function("porter", fn(words) {
        words |> list.map(porter_stemmer.stem)
      }),
    ],
    [],
  )
  |> bench.table([bench.IPS, bench.Min, bench.P(99)])
  |> io.println()
}

fn load_test_data() -> dict.Dict(String, String) {
  let assert Ok(in) = simplifile.read(filepath.join(data_dir, "in.txt"))
  let assert Ok(out) = simplifile.read(filepath.join(data_dir, "out.txt"))

  let in = string.split(in, "\n")
  let out = string.split(out, "\n")

  list.zip(in, out) |> dict.from_list
}
