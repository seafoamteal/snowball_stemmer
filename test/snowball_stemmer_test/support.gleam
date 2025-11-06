import filepath
import gleam/io
import gleam/list
import gleam/string
import gleamy/bench
import porter_stemmer
import simplifile
import snowball_stemmer.{type Stemmer}

const data_dir = "test/data"

pub fn test_full_list() -> Result(Int, #(String, String, String)) {
  let test_cases = load_test_data()
  let stemmer = snowball_stemmer.new()

  test_loop(stemmer, 0, test_cases)
}

fn test_loop(
  stemmer: Stemmer,
  acc: Int,
  pairs: List(#(String, String)),
) -> Result(Int, #(String, String, String)) {
  case pairs {
    [] -> Ok(acc)
    [pair, ..rest] -> {
      let stem = snowball_stemmer.stem(stemmer, pair.0)
      case stem == pair.1 {
        False -> Error(#(pair.0, pair.1, stem))
        True -> test_loop(stemmer, acc + 1, rest)
      }
    }
  }
}

pub fn bench() -> Nil {
  let test_cases = load_test_data() |> list.map(fn(pair) { pair.0 })
  bench.run(
    [bench.Input("all words", test_cases)],
    [
      bench.SetupFunction("snowball", fn(_) {
        let stemmer = snowball_stemmer.new()

        fn(words) { words |> list.map(snowball_stemmer.stem(stemmer, _)) }
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

fn load_test_data() -> List(#(String, String)) {
  let assert Ok(in) = simplifile.read(filepath.join(data_dir, "in.txt"))
  let assert Ok(out) = simplifile.read(filepath.join(data_dir, "out.txt"))

  let in = string.split(in, "\n")
  let out = string.split(out, "\n")

  list.zip(in, out)
}
