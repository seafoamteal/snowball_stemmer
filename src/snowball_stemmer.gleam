import gleam/bool
import gleam/string
import splitter

pub fn main() -> Nil {
  Nil
}

pub opaque type Stemmer {
  Stemmer(
    vowel_splitter: splitter.Splitter,
    consonant_splitter: splitter.Splitter,
  )
}

/// Creates a new Stemmer object to be used with `stem`.
/// Can and _should_ be used across multiple calls to `stem` because
/// it is essentially a cache for the `splitter`s used in the stemming and
/// so improves performance by performing the expensive `splitter` creation
/// only once.
pub fn new() -> Stemmer {
  let vowel_splitter = splitter.new(vowels)
  let consonant_splitter = splitter.new(consonants)
  Stemmer(vowel_splitter:, consonant_splitter:)
}

/// Returns a word stem according to the  Porter2 / Snowball English
/// word-stemming algorithm.
pub fn stem(stemmer: Stemmer, word: String) -> String {
  use <- bool.guard(string.byte_size(word) <= 2, word)

  let word = word |> remove_initial_apostrophe |> lowercase_and_mark_ys

  case word {
    "skis" -> "ski"
    "skies" -> "sky"
    "idly" -> "idl"
    "gently" -> "gentl"
    "ugly" -> "ugli"
    "early" -> "earli"
    "only" -> "onli"
    "singly" -> "singl"
    "sky" -> "sky"
    "news" -> "news"
    "howe" -> "howe"
    "atlas" -> "atlas"
    "cosmos" -> "cosmos"
    "bias" -> "bias"
    "andes" -> "andes"

    _ -> snowball(stemmer, word)
  }
}

fn snowball(stemmer: Stemmer, word: String) -> String {
  word
  |> init_word(stemmer, _)
  |> step0
  |> step1a(stemmer, _)
  |> step1b(stemmer, _)
  |> step1c(stemmer, _)
  |> step2
  |> step3
  |> step4
  |> step5(stemmer, _)
  |> fn(sw) { sw.drow }
  |> string.lowercase
  |> string.reverse
}

pub type SnowballWord {
  SnowballWord(drow: String, length: Int, r2: Int, r1: Int)
}

pub fn step0(word: SnowballWord) -> SnowballWord {
  let SnowballWord(drow, length, r2, r1) = word
  case drow {
    "'s'" <> mets -> SnowballWord(mets, length - 3, r2 - 3, r1 - 3)

    "s'" <> mets -> SnowballWord(mets, length - 2, r2 - 2, r1 - 2)

    "'" <> mets -> SnowballWord(mets, length - 1, r2 - 1, r1 - 1)

    _ -> word
  }
}

pub fn step1a(stemmer: Stemmer, word: SnowballWord) -> SnowballWord {
  let SnowballWord(drow, length, r2, r1) = word

  case drow {
    "sess" <> mets -> SnowballWord("ss" <> mets, length - 2, r2 - 2, r1 - 2)

    "dei" <> mets | "sei" <> mets -> {
      case length > 4 {
        True -> SnowballWord("i" <> mets, length - 2, r2 - 2, r1 - 2)
        False -> SnowballWord("ei" <> mets, length - 1, r2 - 1, r1 - 1)
      }
    }

    "su" <> _ | "ss" <> _ -> word

    "s" <> mets -> {
      case string_contains_vowel_after_start(stemmer, mets) {
        False -> word
        True -> SnowballWord(mets, length - 1, r2 - 1, r1 - 1)
      }
    }

    _ -> word
  }
}

pub fn step1b(stemmer: Stemmer, word: SnowballWord) -> SnowballWord {
  let SnowballWord(drow, length, r2, r1) = word
  let Stemmer(consonant_splitter:, ..) = stemmer

  case drow {
    "yldee" <> mets -> {
      use <- bool.guard(r1 < 5, word)
      case mets {
        "corp" <> _ | "cxe" <> _ | "ccus" <> _ -> word
        _ -> SnowballWord("ee" <> mets, length - 3, r2 - 3, r1 - 3)
      }
    }

    "dee" <> mets -> {
      use <- bool.guard(r1 < 3, word)
      case mets {
        "corp" <> _ | "cxe" <> _ | "ccus" <> _ -> word
        _ -> SnowballWord("ee" <> mets, length - 1, r2 - 1, r1 - 1)
      }
    }

    "ylgni" <> mets -> {
      step1b_helper(stemmer, word, mets, 5)
    }

    "ylde" <> mets -> {
      step1b_helper(stemmer, word, mets, 4)
    }

    "de" <> mets -> {
      step1b_helper(stemmer, word, mets, 2)
    }

    "gni" <> mets -> {
      case mets {
        "nni" | "tuo" | "nnac" | "rreh" | "rrae" | "neve" -> word
        "y" <> prev -> {
          case splitter.split(consonant_splitter, prev) {
            #("", c, "") -> SnowballWord("ei" <> c, length - 2, 0, 0)
            _ -> step1b_helper(stemmer, word, mets, 3)
          }
        }
        _ -> step1b_helper(stemmer, word, mets, 3)
      }
    }

    _ -> word
  }
}

fn step1b_helper(
  stemmer: Stemmer,
  word: SnowballWord,
  mets: String,
  suffix_length: Int,
) {
  let SnowballWord(_, length, r2, r1) = word
  case string_contains_vowel(stemmer, mets) {
    True -> {
      case mets {
        "ta" <> _ | "lb" <> _ | "zi" <> _ -> {
          let length_reduction = suffix_length - 1
          SnowballWord(
            "e" <> mets,
            length - length_reduction,
            r2 - length_reduction,
            r1 - length_reduction,
          )
        }

        "bb" <> prev
        | "dd" <> prev
        | "ff" <> prev
        | "gg" <> prev
        | "mm" <> prev
        | "nn" <> prev
        | "pp" <> prev
        | "rr" <> prev
        | "tt" <> prev -> {
          case prev {
            "a" | "e" | "o" ->
              SnowballWord(
                mets,
                length - suffix_length,
                r2 - suffix_length,
                r1 - suffix_length,
              )

            _ -> {
              let length_reduction = suffix_length + 1
              SnowballWord(
                string.drop_start(mets, 1),
                length - length_reduction,
                r2 - length_reduction,
                r1 - length_reduction,
              )
            }
          }
        }

        _ -> {
          case word_is_short(stemmer, mets, r1 - suffix_length) {
            True -> {
              let length_reduction = suffix_length - 1
              SnowballWord(
                "e" <> mets,
                length - length_reduction,
                r2 - length_reduction,
                r1 - length_reduction,
              )
            }

            False ->
              SnowballWord(
                mets,
                length - suffix_length,
                r2 - suffix_length,
                r1 - suffix_length,
              )
          }
        }
      }
    }

    False -> word
  }
}

pub fn step1c(stemmer: Stemmer, word: SnowballWord) -> SnowballWord {
  let SnowballWord(drow, length, r2, r1) = word
  let Stemmer(consonant_splitter:, ..) = stemmer

  case drow {
    "y" <> mets | "Y" <> mets ->
      case splitter.split(consonant_splitter, mets) {
        #(_, "", "") -> word
        #("", _, _) ->
          case length > 2 {
            False -> word
            True -> SnowballWord("i" <> mets, length, r2, r1)
          }
        _ -> word
      }

    _ -> word
  }
}

pub fn step2(word: SnowballWord) -> SnowballWord {
  let SnowballWord(drow, length, r2, r1) = word

  case drow {
    "lanoita" <> mets -> {
      use <- bool.guard(r1 < 7, word)
      SnowballWord("eta" <> mets, length - 4, r2 - 4, r1 - 4)
    }

    "lanoit" <> mets -> {
      use <- bool.guard(r1 < 6, word)
      SnowballWord("noit" <> mets, length - 2, r2 - 2, r1 - 2)
    }

    "icne" <> mets -> {
      use <- bool.guard(r1 < 4, word)
      SnowballWord("ecne" <> mets, length, r2, r1)
    }

    "icna" <> mets -> {
      use <- bool.guard(r1 < 4, word)
      SnowballWord("ecna" <> mets, length, r2, r1)
    }

    "ilba" <> mets -> {
      use <- bool.guard(r1 < 4, word)
      SnowballWord("elba" <> mets, length, r2, r1)
    }

    "iltne" <> mets -> {
      use <- bool.guard(r1 < 5, word)
      SnowballWord("tne" <> mets, length - 2, r2 - 2, r1 - 2)
    }

    "rezi" <> mets -> {
      use <- bool.guard(r1 < 4, word)
      SnowballWord("ezi" <> mets, length - 1, r1 - 1, r1 - 1)
    }

    "noitazi" <> mets -> {
      use <- bool.guard(r1 < 7, word)
      SnowballWord("ezi" <> mets, length - 4, r2 - 4, r1 - 4)
    }

    "noita" <> mets -> {
      use <- bool.guard(r1 < 5, word)
      SnowballWord("eta" <> mets, length - 2, r2 - 2, r1 - 2)
    }

    "rota" <> mets -> {
      use <- bool.guard(r1 < 4, word)
      SnowballWord("eta" <> mets, length - 1, r2 - 1, r1 - 1)
    }

    "msila" <> mets -> {
      use <- bool.guard(r1 < 5, word)
      SnowballWord("la" <> mets, length - 3, r2 - 3, r1 - 3)
    }

    "itila" <> mets -> {
      use <- bool.guard(r1 < 5, word)
      SnowballWord("la" <> mets, length - 3, r2 - 3, r1 - 3)
    }

    "illa" <> mets -> {
      use <- bool.guard(r1 < 4, word)
      SnowballWord("la" <> mets, length - 2, r2 - 2, r1 - 2)
    }

    "ssenluf" <> mets -> {
      use <- bool.guard(r1 < 7, word)
      SnowballWord("luf" <> mets, length - 4, r2 - 4, r1 - 4)
    }

    "ilsuo" <> mets -> {
      use <- bool.guard(r1 < 5, word)
      SnowballWord("suo" <> mets, length - 2, r2 - 2, r1 - 2)
    }

    "ssensuo" <> mets -> {
      use <- bool.guard(r1 < 7, word)
      SnowballWord("suo" <> mets, length - 4, r2 - 4, r1 - 4)
    }

    "ssenevi" <> mets -> {
      use <- bool.guard(r1 < 7, word)
      SnowballWord("evi" <> mets, length - 4, r2 - 4, r1 - 4)
    }

    "itivi" <> mets -> {
      use <- bool.guard(r1 < 5, word)
      SnowballWord("evi" <> mets, length - 2, r2 - 2, r1 - 2)
    }

    "itilib" <> mets -> {
      use <- bool.guard(r1 < 6, word)
      SnowballWord("elb" <> mets, length - 3, r2 - 3, r1 - 3)
    }

    "ilb" <> mets -> {
      use <- bool.guard(r1 < 3, word)
      SnowballWord("elb" <> mets, length, r2, r1)
    }

    "tsigo" <> mets -> {
      use <- bool.guard(r1 < 5, word)
      SnowballWord("go" <> mets, length - 3, r2 - 3, r1 - 3)
    }

    "igo" <> mets -> {
      use <- bool.guard(r1 < 3, word)
      case mets {
        "l" <> _ -> SnowballWord("go" <> mets, length - 1, r2 - 1, r1 - 1)
        _ -> word
      }
    }

    "illuf" <> mets -> {
      use <- bool.guard(r1 < 5, word)
      SnowballWord("luf" <> mets, length - 2, r2 - 2, r1 - 2)
    }

    "ilssel" <> mets -> {
      use <- bool.guard(r1 < 6, word)
      SnowballWord("ssel" <> mets, length - 2, r2 - 2, r1 - 2)
    }

    "il" <> mets -> {
      use <- bool.guard(r1 < 2, word)
      case mets {
        "c" <> _
        | "d" <> _
        | "e" <> _
        | "g" <> _
        | "h" <> _
        | "k" <> _
        | "m" <> _
        | "n" <> _
        | "r" <> _
        | "t" <> _ -> SnowballWord(mets, length - 2, r2 - 2, r1 - 2)
        _ -> word
      }
    }

    _ -> word
  }
}

pub fn step3(word: SnowballWord) -> SnowballWord {
  let SnowballWord(drow, length, r2, r1) = word

  case drow {
    "lanoita" <> mets -> {
      use <- bool.guard(r1 < 7, word)
      SnowballWord("eta" <> mets, length - 4, r2 - 4, r1 - 4)
    }

    "lanoit" <> mets -> {
      use <- bool.guard(r1 < 6, word)
      SnowballWord("noit" <> mets, length - 2, r2 - 2, r1 - 2)
    }

    "ezila" <> mets -> {
      use <- bool.guard(r1 < 5, word)
      SnowballWord("la" <> mets, length - 3, r2 - 3, r1 - 3)
    }

    "etaci" <> mets -> {
      use <- bool.guard(r1 < 5, word)
      SnowballWord("ci" <> mets, length - 3, r2 - 3, r1 - 3)
    }

    "itici" <> mets -> {
      use <- bool.guard(r1 < 5, word)
      SnowballWord("ci" <> mets, length - 3, r2 - 3, r1 - 3)
    }

    "laci" <> mets -> {
      use <- bool.guard(r1 < 4, word)
      SnowballWord("ci" <> mets, length - 2, r2 - 2, r1 - 2)
    }

    "luf" <> mets -> {
      use <- bool.guard(r1 < 3, word)
      SnowballWord(mets, length - 3, r2 - 3, r1 - 3)
    }

    "ssen" <> mets -> {
      use <- bool.guard(r1 < 4, word)
      SnowballWord(mets, length - 4, r2 - 4, r1 - 4)
    }

    "evita" <> mets -> {
      use <- bool.guard(r2 < 5, word)
      SnowballWord(mets, length - 5, r2 - 5, r1 - 5)
    }

    _ -> word
  }
}

pub fn step4(word: SnowballWord) -> SnowballWord {
  let SnowballWord(drow, length, r2, r1) = word

  case drow {
    "tneme" <> mets -> {
      use <- bool.guard(r2 < 5, word)
      SnowballWord(mets, length - 5, r2 - 5, r1 - 5)
    }

    "tnem" <> mets -> {
      use <- bool.guard(r2 < 4, word)
      SnowballWord(mets, length - 4, r2 - 4, r1 - 4)
    }

    "tne" <> mets -> {
      use <- bool.guard(r2 < 3, word)
      SnowballWord(mets, length - 3, r2 - 3, r1 - 3)
    }

    "ecna" <> mets -> {
      use <- bool.guard(r2 < 4, word)
      SnowballWord(mets, length - 4, r2 - 4, r1 - 4)
    }

    "ecne" <> mets -> {
      use <- bool.guard(r2 < 4, word)
      SnowballWord(mets, length - 4, r2 - 4, r1 - 4)
    }

    "elba" <> mets -> {
      use <- bool.guard(r2 < 4, word)
      SnowballWord(mets, length - 4, r2 - 4, r1 - 4)
    }

    "elbi" <> mets -> {
      use <- bool.guard(r2 < 4, word)
      SnowballWord(mets, length - 4, r2 - 4, r1 - 4)
    }

    "ezi" <> mets -> {
      use <- bool.guard(r2 < 3, word)
      SnowballWord(mets, length - 3, r2 - 3, r1 - 3)
    }

    "evi" <> mets -> {
      use <- bool.guard(r2 < 3, word)
      SnowballWord(mets, length - 3, r2 - 3, r1 - 3)
    }

    "suo" <> mets -> {
      use <- bool.guard(r2 < 3, word)
      SnowballWord(mets, length - 3, r2 - 3, r1 - 3)
    }

    "iti" <> mets -> {
      use <- bool.guard(r2 < 3, word)
      SnowballWord(mets, length - 3, r2 - 3, r1 - 3)
    }

    "eta" <> mets -> {
      use <- bool.guard(r2 < 3, word)
      SnowballWord(mets, length - 3, r2 - 3, r1 - 3)
    }

    "msi" <> mets -> {
      use <- bool.guard(r2 < 3, word)
      SnowballWord(mets, length - 3, r2 - 3, r1 - 3)
    }

    "tna" <> mets -> {
      use <- bool.guard(r2 < 3, word)
      SnowballWord(mets, length - 3, r2 - 3, r1 - 3)
    }

    "la" <> mets -> {
      use <- bool.guard(r2 < 2, word)
      SnowballWord(mets, length - 2, r2 - 2, r1 - 2)
    }

    "re" <> mets -> {
      use <- bool.guard(r2 < 2, word)
      SnowballWord(mets, length - 2, r2 - 2, r1 - 2)
    }

    "ci" <> mets -> {
      use <- bool.guard(r2 < 2, word)
      SnowballWord(mets, length - 2, r2 - 2, r1 - 2)
    }

    "noi" <> mets -> {
      use <- bool.guard(r2 < 3, word)
      case mets {
        "s" <> _ | "t" <> _ -> SnowballWord(mets, length - 3, r2 - 3, r1 - 3)
        _ -> word
      }
    }

    _ -> word
  }
}

pub fn step5(stemmer: Stemmer, word: SnowballWord) -> SnowballWord {
  let SnowballWord(drow, length, r2, r1) = word
  case drow {
    "e" <> mets -> {
      case r2 >= 1 {
        True -> SnowballWord(mets, length - 1, r2 - 1, r1 - 1)
        False -> {
          case r1 >= 1 && !syllable_is_short(stemmer, mets) {
            True -> SnowballWord(mets, length - 1, r2 - 1, r1 - 1)
            False -> word
          }
        }
      }
    }

    "l" <> mets -> {
      case r2 >= 1 {
        False -> word
        True -> {
          case mets {
            "l" <> _ -> SnowballWord(mets, length - 1, r2 - 1, r1 - 1)
            _ -> word
          }
        }
      }
    }
    _ -> word
  }
}

fn string_contains_vowel(stemmer: Stemmer, str: String) -> Bool {
  let Stemmer(vowel_splitter:, ..) = stemmer
  case splitter.split(vowel_splitter, str) {
    #(_, "", "") -> False
    _ -> True
  }
}

fn string_contains_vowel_after_start(stemmer: Stemmer, str: String) -> Bool {
  let Stemmer(vowel_splitter:, ..) = stemmer
  case splitter.split(vowel_splitter, str) {
    #(_, "", "") -> False
    #("", _, rest) ->
      case splitter.split(vowel_splitter, rest) {
        #(_, "", "") -> False
        _ -> True
      }
    _ -> True
  }
}

fn word_is_short(stemmer: Stemmer, word: String, r1: Int) -> Bool {
  use <- bool.guard(r1 > 0, False)
  syllable_is_short(stemmer, word)
}

fn syllable_is_short(stemmer: Stemmer, syl: String) -> Bool {
  use <- bool.guard(string.slice(syl, 0, 4) == "tsap", True)
  let Stemmer(vowel_splitter:, consonant_splitter:) = stemmer

  case splitter.split(consonant_splitter, syl) {
    #(_, "", "") -> False
    #("", c, rest) -> {
      case c {
        "w" | "x" | "Y" -> {
          case splitter.split(vowel_splitter, rest) {
            #("", _, "") -> True
            _ -> False
          }
        }

        _ -> {
          case splitter.split(vowel_splitter, rest) {
            #(_, "", "") -> False
            #("", _, rest) ->
              case splitter.split(consonant_splitter, rest) {
                #("", "", "") -> True
                #(_, "", "") -> False
                #("", _, _) -> True
                _ -> False
              }
            _ -> False
          }
        }
      }
    }
    _ -> False
  }
}

pub fn init_word(stemmer: Stemmer, word: String) -> SnowballWord {
  let length = string.length(word)
  let #(r1, r2) = mark_regions(stemmer, word)
  let r1 = string.length(r1)
  let r2 = string.length(r2)
  SnowballWord(string.reverse(word), length, r2, r1)
}

pub fn remove_initial_apostrophe(word: String) -> String {
  case word {
    "'" <> rest -> rest
    _ -> word
  }
}

pub fn lowercase_and_mark_ys(word: String) -> String {
  mark_ys_loop(word, "", True)
}

fn mark_ys_loop(word: String, acc: String, last_vowel: Bool) -> String {
  case string.pop_grapheme(word) {
    Ok(#("y", rest)) | Ok(#("Y", rest)) -> {
      case last_vowel {
        True -> mark_ys_loop(rest, "Y" <> acc, False)
        False -> mark_ys_loop(rest, "y" <> acc, True)
      }
    }
    Ok(#("a", rest)) | Ok(#("A", rest)) -> mark_ys_loop(rest, "a" <> acc, True)
    Ok(#("e", rest)) | Ok(#("E", rest)) -> mark_ys_loop(rest, "e" <> acc, True)
    Ok(#("i", rest)) | Ok(#("I", rest)) -> mark_ys_loop(rest, "i" <> acc, True)
    Ok(#("o", rest)) | Ok(#("O", rest)) -> mark_ys_loop(rest, "o" <> acc, True)
    Ok(#("u", rest)) | Ok(#("U", rest)) -> mark_ys_loop(rest, "u" <> acc, True)

    Ok(#("b", rest)) | Ok(#("B", rest)) -> mark_ys_loop(rest, "b" <> acc, False)
    Ok(#("c", rest)) | Ok(#("C", rest)) -> mark_ys_loop(rest, "c" <> acc, False)
    Ok(#("d", rest)) | Ok(#("D", rest)) -> mark_ys_loop(rest, "d" <> acc, False)
    Ok(#("f", rest)) | Ok(#("F", rest)) -> mark_ys_loop(rest, "f" <> acc, False)
    Ok(#("g", rest)) | Ok(#("G", rest)) -> mark_ys_loop(rest, "g" <> acc, False)
    Ok(#("h", rest)) | Ok(#("H", rest)) -> mark_ys_loop(rest, "h" <> acc, False)
    Ok(#("j", rest)) | Ok(#("J", rest)) -> mark_ys_loop(rest, "j" <> acc, False)
    Ok(#("k", rest)) | Ok(#("K", rest)) -> mark_ys_loop(rest, "k" <> acc, False)
    Ok(#("l", rest)) | Ok(#("L", rest)) -> mark_ys_loop(rest, "l" <> acc, False)
    Ok(#("m", rest)) | Ok(#("M", rest)) -> mark_ys_loop(rest, "m" <> acc, False)
    Ok(#("n", rest)) | Ok(#("N", rest)) -> mark_ys_loop(rest, "n" <> acc, False)
    Ok(#("p", rest)) | Ok(#("P", rest)) -> mark_ys_loop(rest, "p" <> acc, False)
    Ok(#("q", rest)) | Ok(#("Q", rest)) -> mark_ys_loop(rest, "q" <> acc, False)
    Ok(#("r", rest)) | Ok(#("R", rest)) -> mark_ys_loop(rest, "r" <> acc, False)
    Ok(#("s", rest)) | Ok(#("S", rest)) -> mark_ys_loop(rest, "s" <> acc, False)
    Ok(#("t", rest)) | Ok(#("T", rest)) -> mark_ys_loop(rest, "t" <> acc, False)
    Ok(#("v", rest)) | Ok(#("V", rest)) -> mark_ys_loop(rest, "v" <> acc, False)
    Ok(#("w", rest)) | Ok(#("W", rest)) -> mark_ys_loop(rest, "w" <> acc, False)
    Ok(#("x", rest)) | Ok(#("X", rest)) -> mark_ys_loop(rest, "x" <> acc, False)
    Ok(#("z", rest)) | Ok(#("Z", rest)) -> mark_ys_loop(rest, "z" <> acc, False)

    // not an english word, so won't be stemmed correctly anyway
    Ok(#(c, rest)) -> mark_ys_loop(rest, c <> acc, False)
    Error(_) -> acc |> string.reverse
  }
}

/// Gets the R1 and R2 region of a word
/// 
///  R1 is the region after the first non-vowel following a vowel, or the
/// end of the word if there is no such non-vowel.
pub fn mark_regions(stemmer: Stemmer, word: String) -> #(String, String) {
  let Stemmer(vowel_splitter, consonant_splitter) = stemmer

  case get_r1(stemmer, word) {
    "" -> #("", "")
    r1 -> {
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

pub fn get_r1(stemmer: Stemmer, word: String) -> String {
  case word {
    "gener" <> rest -> rest
    "commun" <> rest -> rest
    "arsen" <> rest -> rest
    "past" <> rest -> rest
    "univers" <> rest -> rest
    "later" <> rest -> rest
    "emerg" <> rest -> rest
    "organ" <> rest -> rest
    "inter" <> rest -> rest
    _ -> {
      let Stemmer(vowel_splitter, consonant_splitter) = stemmer

      let #(_, word) = splitter.split_after(vowel_splitter, word)
      case word {
        "" -> ""
        _ -> {
          let #(_, r1) = splitter.split_after(consonant_splitter, word)
          r1
        }
      }
    }
  }
}

const vowels = ["a", "e", "i", "o", "u", "y"]

const consonants = [
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
  "Y",
  "z",
]
