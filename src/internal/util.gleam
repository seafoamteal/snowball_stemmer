import gleam/list
import gleam/string
import splitter

pub type SnowballWord {
  SnowballWord(drow: String, length: Int, r2: Int, r1: Int)
}

pub fn init_word(word: String) -> SnowballWord {
  let word = word |> remove_initial_apostrophe |> mark_consonant_y
  let length = string.length(word)
  let #(r1, r2) = get_r1r2(word)
  let r1 = string.length(r1)
  let r2 = string.length(r2)
  SnowballWord(string.reverse(word), length, length - r1 + 1, length - r2 + 1)
}

/// Gets the R1 and R2 region of a word
/// 
///  R1 is the region after the first non-vowel following a vowel, or the
/// end of the word if there is no such non-vowel.
///
/// TODO: Rewrite this function to return the start indices of R1 and R2
/// instead
pub fn get_r1r2(word: String) -> #(String, String) {
  let vowel_splitter = splitter.new(vowels)
  let consonant_splitter = splitter.new(consonants)

  let #(_, word) = splitter.split_after(vowel_splitter, word)
  case word {
    "" -> #("", "")
    _ -> {
      let #(_, r1) = splitter.split_after(consonant_splitter, word)

      let #(_, word) = splitter.split_after(vowel_splitter, r1)
      case word {
        "" -> #(r1, "")
        _ -> {
          let #(_, r2) = splitter.split_after(consonant_splitter, word)
          #(r1, r2)
        }
      }
    }
  }
}

pub fn remove_initial_apostrophe(word: String) -> String {
  case word {
    "'" <> rest -> rest
    _ -> word
  }
}

pub fn mark_consonant_y(word: String) -> String {
  case string.pop_grapheme(word) {
    Error(_) -> ""
    Ok(#(first, _)) -> {
      let first = case first {
        "y" -> "Y"
        _ -> first
      }

      first
      <> {
        let letters = string.to_graphemes(word)

        fn(a, b) {
          let a_is_vowel = list.contains(vowels, a)
          case a, b {
            _, "y" if a_is_vowel -> "Y"
            _, b -> b
          }
        }
        |> list.map2(letters, list.drop(letters, 1), _)
        |> list.fold("", fn(a, b) { a <> b })
      }
    }
  }
}

pub const vowels = ["a", "e", "i", "o", "u", "y"]

pub const consonants = [
  "b",
  "c",
  "d",
  "f",
  "g",
  "h",
  "j",
  "k",
  "l",
  "m",
  "n",
  "p",
  "q",
  "r",
  "s",
  "t",
  "v",
  "w",
  "x",
  "z",
]

pub const doubles = [
  "bb",
  "dd",
  "ff",
  "gg",
  "mm",
  "nn",
  "pp",
  "rr",
  "tt",
]

pub const li_ending = [
  "c",
  "d",
  "e",
  "g",
  "h",
  "k",
  "m",
  "n",
  "r",
  "t",
]
