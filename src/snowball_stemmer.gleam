import gleam/string
import splitter

pub opaque type Stemmer {
  Stemmer(
    vowel_splitter: splitter.Splitter,
    consonant_splitter: splitter.Splitter,
  )
}

@internal
pub type SnowballWord {
  SnowballWord(drow: String, length: Int, r2: Int, r1: Int)
}

/// Creates a new Stemmer object to be used with `stem`.
/// Can and _should_ be used across multiple calls to `stem` because
/// it is essentially a cache for the `splitter`s used in the stemming and
/// so improves performance by performing the expensive `splitter` creation
/// only once.
pub fn new() -> Stemmer {
  let vowel_splitter = splitter.new(["a", "e", "i", "o", "u", "y"])
  let consonant_splitter =
    splitter.new([
      "b", "c", "d", "f", "g", "h", "j", "k", "l", "m", "n", "p", "q", "r", "s",
      "t", "v", "w", "x", "Y", "z",
    ])
  Stemmer(vowel_splitter:, consonant_splitter:)
}

/// Returns a word stem according to the  Porter2 / Snowball English
/// word-stemming algorithm.
pub fn stem(stemmer: Stemmer, word: String) -> String {
  case string.byte_size(word) <= 2 {
    True -> word
    False ->
      case lowercase_and_mark_ys(remove_initial_apostrophe(word)) {
        // handle exceptional cases
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
        word -> snowball(stemmer, word)
      }
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

@internal
pub fn step0(word: SnowballWord) -> SnowballWord {
  let SnowballWord(drow, length, r2, r1) = word
  case drow {
    "'s'" <> mets -> SnowballWord(mets, length - 3, r2 - 3, r1 - 3)

    "s'" <> mets -> SnowballWord(mets, length - 2, r2 - 2, r1 - 2)

    "'" <> mets -> SnowballWord(mets, length - 1, r2 - 1, r1 - 1)

    _ -> word
  }
}

@internal
pub fn step1a(stemmer: Stemmer, word: SnowballWord) -> SnowballWord {
  let SnowballWord(drow, length, r2, r1) = word

  case drow {
    "sess" <> mets -> SnowballWord("ss" <> mets, length - 2, r2 - 2, r1 - 2)

    "dei" <> mets | "sei" <> mets ->
      case length > 4 {
        True -> SnowballWord("i" <> mets, length - 2, r2 - 2, r1 - 2)
        False -> SnowballWord("ei" <> mets, length - 1, r2 - 1, r1 - 1)
      }

    "su" <> _ | "ss" <> _ -> word

    "s" <> mets ->
      case string_contains_vowel_after_start(stemmer, mets) {
        False -> word
        True -> SnowballWord(mets, length - 1, r2 - 1, r1 - 1)
      }

    _ -> word
  }
}

@internal
pub fn step1b(stemmer: Stemmer, word: SnowballWord) -> SnowballWord {
  let SnowballWord(drow, length, r2, r1) = word
  let Stemmer(consonant_splitter:, ..) = stemmer

  case drow {
    "yldee" <> _ if r1 < 5 -> word
    "yldee" <> mets ->
      case mets {
        "corp" <> _ | "cxe" <> _ | "ccus" <> _ -> word
        _ -> SnowballWord("ee" <> mets, length - 3, r2 - 3, r1 - 3)
      }

    "dee" <> _ if r1 < 3 -> word
    "dee" <> mets ->
      case mets {
        "corp" <> _ | "cxe" <> _ | "ccus" <> _ -> word
        _ -> SnowballWord("ee" <> mets, length - 1, r2 - 1, r1 - 1)
      }

    "ylgni" <> mets -> step1b_helper(stemmer, word, mets, 5)
    "ylde" <> mets -> step1b_helper(stemmer, word, mets, 4)
    "de" <> mets -> step1b_helper(stemmer, word, mets, 2)

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
              let Stemmer(consonant_splitter:, ..) = stemmer
              let assert #("", _, rest) =
                splitter.split(consonant_splitter, mets)

              SnowballWord(
                rest,
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

@internal
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

@internal
pub fn step2(word: SnowballWord) -> SnowballWord {
  let SnowballWord(drow, length, r2, r1) = word

  case drow {
    "lanoita" <> _ if r1 < 7 -> word
    "lanoita" <> mets -> SnowballWord("eta" <> mets, length - 4, r2 - 4, r1 - 4)

    "lanoit" <> _ if r1 < 6 -> word
    "lanoit" <> mets -> SnowballWord("noit" <> mets, length - 2, r2 - 2, r1 - 2)

    "icne" <> _ if r1 < 4 -> word
    "icne" <> mets -> SnowballWord("ecne" <> mets, length, r2, r1)

    "icna" <> _ if r1 < 4 -> word
    "icna" <> mets -> SnowballWord("ecna" <> mets, length, r2, r1)

    "ilba" <> _ if r1 < 4 -> word
    "ilba" <> mets -> SnowballWord("elba" <> mets, length, r2, r1)

    "iltne" <> _ if r1 < 5 -> word
    "iltne" <> mets -> SnowballWord("tne" <> mets, length - 2, r2 - 2, r1 - 2)

    "rezi" <> _ if r1 < 4 -> word
    "rezi" <> mets -> SnowballWord("ezi" <> mets, length - 1, r1 - 1, r1 - 1)

    "noitazi" <> _ if r1 < 7 -> word
    "noitazi" <> mets -> SnowballWord("ezi" <> mets, length - 4, r2 - 4, r1 - 4)

    "noita" <> _ if r1 < 5 -> word
    "noita" <> mets -> SnowballWord("eta" <> mets, length - 2, r2 - 2, r1 - 2)

    "rota" <> _ if r1 < 4 -> word
    "rota" <> mets -> SnowballWord("eta" <> mets, length - 1, r2 - 1, r1 - 1)

    "msila" <> _ if r1 < 5 -> word
    "msila" <> mets -> SnowballWord("la" <> mets, length - 3, r2 - 3, r1 - 3)

    "itila" <> _ if r1 < 5 -> word
    "itila" <> mets -> SnowballWord("la" <> mets, length - 3, r2 - 3, r1 - 3)

    "illa" <> _ if r1 < 4 -> word
    "illa" <> mets -> SnowballWord("la" <> mets, length - 2, r2 - 2, r1 - 2)

    "ssenluf" <> _ if r1 < 7 -> word
    "ssenluf" <> mets -> SnowballWord("luf" <> mets, length - 4, r2 - 4, r1 - 4)

    "ilsuo" <> _ if r1 < 5 -> word
    "ilsuo" <> mets -> SnowballWord("suo" <> mets, length - 2, r2 - 2, r1 - 2)

    "ssensuo" <> _ if r1 < 7 -> word
    "ssensuo" <> mets -> SnowballWord("suo" <> mets, length - 4, r2 - 4, r1 - 4)

    "ssenevi" <> _ if r1 < 7 -> word
    "ssenevi" <> mets -> SnowballWord("evi" <> mets, length - 4, r2 - 4, r1 - 4)

    "itivi" <> _ if r1 < 5 -> word
    "itivi" <> mets -> SnowballWord("evi" <> mets, length - 2, r2 - 2, r1 - 2)

    "itilib" <> _ if r1 < 6 -> word
    "itilib" <> mets -> SnowballWord("elb" <> mets, length - 3, r2 - 3, r1 - 3)

    "ilb" <> _ if r1 < 3 -> word
    "ilb" <> mets -> SnowballWord("elb" <> mets, length, r2, r1)

    "tsigo" <> _ if r1 < 5 -> word
    "tsigo" <> mets -> SnowballWord("go" <> mets, length - 3, r2 - 3, r1 - 3)

    "igo" <> _ if r1 < 3 -> word
    "igo" <> mets ->
      case mets {
        "l" <> _ -> SnowballWord("go" <> mets, length - 1, r2 - 1, r1 - 1)
        _ -> word
      }

    "illuf" <> _ if r1 < 5 -> word
    "illuf" <> mets -> SnowballWord("luf" <> mets, length - 2, r2 - 2, r1 - 2)

    "ilssel" <> _ if r1 < 6 -> word
    "ilssel" <> mets -> SnowballWord("ssel" <> mets, length - 2, r2 - 2, r1 - 2)

    "il" <> _ if r1 < 2 -> word
    "il" <> mets ->
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

    _ -> word
  }
}

@internal
pub fn step3(word: SnowballWord) -> SnowballWord {
  let SnowballWord(drow, length, r2, r1) = word

  case drow {
    "lanoita" <> _ if r1 < 7 -> word
    "lanoita" <> mets -> SnowballWord("eta" <> mets, length - 4, r2 - 4, r1 - 4)

    "lanoit" <> _ if r1 < 6 -> word
    "lanoit" <> mets -> SnowballWord("noit" <> mets, length - 2, r2 - 2, r1 - 2)

    "ezila" <> _ if r1 < 5 -> word
    "ezila" <> mets -> SnowballWord("la" <> mets, length - 3, r2 - 3, r1 - 3)

    "etaci" <> _ if r1 < 5 -> word
    "etaci" <> mets -> SnowballWord("ci" <> mets, length - 3, r2 - 3, r1 - 3)

    "itici" <> _ if r1 < 5 -> word
    "itici" <> mets -> SnowballWord("ci" <> mets, length - 3, r2 - 3, r1 - 3)

    "laci" <> _ if r1 < 4 -> word
    "laci" <> mets -> SnowballWord("ci" <> mets, length - 2, r2 - 2, r1 - 2)

    "luf" <> _ if r1 < 3 -> word
    "luf" <> mets -> SnowballWord(mets, length - 3, r2 - 3, r1 - 3)

    "ssen" <> _ if r1 < 4 -> word
    "ssen" <> mets -> SnowballWord(mets, length - 4, r2 - 4, r1 - 4)

    "evita" <> _ if r2 < 5 -> word
    "evita" <> mets -> SnowballWord(mets, length - 5, r2 - 5, r1 - 5)

    _ -> word
  }
}

@internal
pub fn step4(word: SnowballWord) -> SnowballWord {
  let SnowballWord(drow, length, r2, r1) = word

  case drow {
    "tneme" <> _ if r2 < 5 -> word
    "tneme" <> mets -> SnowballWord(mets, length - 5, r2 - 5, r1 - 5)

    "tnem" <> _ if r2 < 4 -> word
    "tnem" <> mets -> SnowballWord(mets, length - 4, r2 - 4, r1 - 4)

    "tne" <> _ if r2 < 3 -> word
    "tne" <> mets -> SnowballWord(mets, length - 3, r2 - 3, r1 - 3)

    "ecna" <> _ if r2 < 4 -> word
    "ecna" <> mets -> SnowballWord(mets, length - 4, r2 - 4, r1 - 4)

    "ecne" <> _ if r2 < 4 -> word
    "ecne" <> mets -> SnowballWord(mets, length - 4, r2 - 4, r1 - 4)

    "elba" <> _ if r2 < 4 -> word
    "elba" <> mets -> SnowballWord(mets, length - 4, r2 - 4, r1 - 4)

    "elbi" <> _ if r2 < 4 -> word
    "elbi" <> mets -> SnowballWord(mets, length - 4, r2 - 4, r1 - 4)

    "ezi" <> _ if r2 < 3 -> word
    "ezi" <> mets -> SnowballWord(mets, length - 3, r2 - 3, r1 - 3)

    "evi" <> _ if r2 < 3 -> word
    "evi" <> mets -> SnowballWord(mets, length - 3, r2 - 3, r1 - 3)

    "suo" <> _ if r2 < 3 -> word
    "suo" <> mets -> SnowballWord(mets, length - 3, r2 - 3, r1 - 3)

    "iti" <> _ if r2 < 3 -> word
    "iti" <> mets -> SnowballWord(mets, length - 3, r2 - 3, r1 - 3)

    "eta" <> _ if r2 < 3 -> word
    "eta" <> mets -> SnowballWord(mets, length - 3, r2 - 3, r1 - 3)

    "msi" <> _ if r2 < 3 -> word
    "msi" <> mets -> SnowballWord(mets, length - 3, r2 - 3, r1 - 3)

    "tna" <> _ if r2 < 3 -> word
    "tna" <> mets -> SnowballWord(mets, length - 3, r2 - 3, r1 - 3)

    "la" <> _ if r2 < 2 -> word
    "la" <> mets -> SnowballWord(mets, length - 2, r2 - 2, r1 - 2)

    "re" <> _ if r2 < 2 -> word
    "re" <> mets -> SnowballWord(mets, length - 2, r2 - 2, r1 - 2)

    "ci" <> _ if r2 < 2 -> word
    "ci" <> mets -> SnowballWord(mets, length - 2, r2 - 2, r1 - 2)

    "noi" <> _ if r2 < 3 -> word
    "noi" <> mets ->
      case mets {
        "s" <> _ | "t" <> _ -> SnowballWord(mets, length - 3, r2 - 3, r1 - 3)
        _ -> word
      }

    _ -> word
  }
}

@internal
pub fn step5(stemmer: Stemmer, word: SnowballWord) -> SnowballWord {
  let SnowballWord(drow, length, r2, r1) = word
  case drow {
    "e" <> mets if r2 >= 1 -> SnowballWord(mets, length - 1, r2 - 1, r1 - 1)
    "e" <> mets ->
      case r1 >= 1 && !syllable_is_short(stemmer, mets) {
        True -> SnowballWord(mets, length - 1, r2 - 1, r1 - 1)
        False -> word
      }

    "l" <> _ if r2 < 1 -> word
    "l" <> mets ->
      case mets {
        "l" <> _ -> SnowballWord(mets, length - 1, r2 - 1, r1 - 1)
        _ -> word
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
  case r1 > 0 {
    True -> False
    False -> syllable_is_short(stemmer, word)
  }
}

fn syllable_is_short(stemmer: Stemmer, syl: String) -> Bool {
  case syl {
    "tsap" <> _ -> True
    _ -> {
      let Stemmer(vowel_splitter:, consonant_splitter:) = stemmer
      case splitter.split(consonant_splitter, syl) {
        #(_, "", "") -> False
        #("", "w", rest) | #("", "x", rest) | #("", "Y", rest) -> {
          case splitter.split(vowel_splitter, rest) {
            #("", _, "") -> True
            _ -> False
          }
        }

        #("", _, rest) ->
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

        _ -> False
      }
    }
  }
}

@internal
pub fn init_word(stemmer: Stemmer, word: String) -> SnowballWord {
  let length = string.byte_size(word)
  let #(r1, r2) = mark_regions(stemmer, word)
  let r1 = string.byte_size(r1)
  let r2 = string.byte_size(r2)
  SnowballWord(string.reverse(word), length, r2, r1)
}

@internal
pub fn remove_initial_apostrophe(word: String) -> String {
  case word {
    "'" <> rest -> rest
    _ -> word
  }
}

@internal
pub fn lowercase_and_mark_ys(word: String) -> String {
  mark_ys_loop(word, "", True)
}

fn mark_ys_loop(word: String, acc: String, last_vowel: Bool) -> String {
  case word {
    "" -> acc

    "y" <> rest | "Y" <> rest ->
      case last_vowel {
        True -> mark_ys_loop(rest, acc <> "Y", False)
        False -> mark_ys_loop(rest, acc <> "y", True)
      }

    "a" as first <> rest
    | "e" as first <> rest
    | "i" as first <> rest
    | "o" as first <> rest
    | "u" as first <> rest
    | "A" as first <> rest
    | "E" as first <> rest
    | "I" as first <> rest
    | "O" as first <> rest
    | "U" as first <> rest -> mark_ys_loop(rest, acc <> first, True)

    "b" as first <> rest
    | "c" as first <> rest
    | "d" as first <> rest
    | "f" as first <> rest
    | "g" as first <> rest
    | "h" as first <> rest
    | "j" as first <> rest
    | "k" as first <> rest
    | "l" as first <> rest
    | "m" as first <> rest
    | "n" as first <> rest
    | "p" as first <> rest
    | "q" as first <> rest
    | "r" as first <> rest
    | "s" as first <> rest
    | "t" as first <> rest
    | "v" as first <> rest
    | "w" as first <> rest
    | "x" as first <> rest
    | "z" as first <> rest
    | "B" as first <> rest
    | "C" as first <> rest
    | "D" as first <> rest
    | "F" as first <> rest
    | "G" as first <> rest
    | "H" as first <> rest
    | "J" as first <> rest
    | "K" as first <> rest
    | "L" as first <> rest
    | "M" as first <> rest
    | "N" as first <> rest
    | "P" as first <> rest
    | "Q" as first <> rest
    | "R" as first <> rest
    | "S" as first <> rest
    | "T" as first <> rest
    | "V" as first <> rest
    | "W" as first <> rest
    | "X" as first <> rest
    | "Z" as first <> rest -> mark_ys_loop(rest, acc <> first, False)

    _ ->
      case string.pop_grapheme(word) {
        // not an english word, so won't be stemmed correctly anyway
        Ok(#(first, rest)) -> mark_ys_loop(rest, acc <> first, False)
        Error(_) -> acc
      }
  }
}

/// Gets the R1 and R2 region of a word
///
///  R1 is the region after the first non-vowel following a vowel, or the
/// end of the word if there is no such non-vowel.
fn mark_regions(stemmer: Stemmer, word: String) -> #(String, String) {
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

fn get_r1(stemmer: Stemmer, word: String) -> String {
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
