import gleeunit
import gleeunit/should
import snowball_stemmer.{SnowballWord}

pub fn main() -> Nil {
  gleeunit.main()
}

pub fn init_word_test() {
  "" |> snowball_stemmer.init_word |> should.equal(SnowballWord("", 0, 0, 0))

  "beautiful"
  |> snowball_stemmer.init_word
  |> should.equal(SnowballWord("lufituaeb", 9, 2, 4))

  "BEAUTY"
  |> snowball_stemmer.init_word
  |> should.equal(SnowballWord("ytuaeb", 6, 0, 1))

  "beau"
  |> snowball_stemmer.init_word
  |> should.equal(SnowballWord("uaeb", 4, 0, 0))

  "yamMeR"
  |> snowball_stemmer.init_word
  |> should.equal(SnowballWord("remmaY", 6, 0, 3))

  "'calyx"
  |> snowball_stemmer.init_word
  |> should.equal(SnowballWord("xylac", 5, 0, 2))

  "eucharIST"
  |> snowball_stemmer.init_word
  |> should.equal(SnowballWord("tsirahcue", 9, 3, 6))

  "'poetaster'"
  |> snowball_stemmer.init_word
  |> should.equal(SnowballWord("'retsateop", 10, 4, 6))
}

pub fn step0_test() {
  "horology"
  |> snowball_stemmer.init_word
  |> snowball_stemmer.step0
  |> should.equal(SnowballWord("ygoloroh", 8, 3, 5))

  "dogs'"
  |> snowball_stemmer.init_word
  |> snowball_stemmer.step0
  |> should.equal(SnowballWord("sgod", 4, -1, 1))

  "elephant's"
  |> snowball_stemmer.init_word
  |> snowball_stemmer.step0
  |> should.equal(SnowballWord("tnahpele", 8, 4, 6))

  "blanket's'"
  |> snowball_stemmer.init_word
  |> snowball_stemmer.step0
  |> should.equal(SnowballWord("teknalb", 7, 0, 3))
}

pub fn step1a_test() {
  "molasses"
  |> snowball_stemmer.init_word
  |> snowball_stemmer.step0
  |> snowball_stemmer.step1a
  |> should.equal(SnowballWord("ssalom", 6, 1, 3))

  "ties"
  |> snowball_stemmer.init_word
  |> snowball_stemmer.step0
  |> snowball_stemmer.step1a
  |> should.equal(SnowballWord("eit", 3, -1, -1))

  "cried"
  |> snowball_stemmer.init_word
  |> snowball_stemmer.step0
  |> snowball_stemmer.step1a
  |> should.equal(SnowballWord("irc", 3, -2, -2))

  "kiwis"
  |> snowball_stemmer.init_word
  |> snowball_stemmer.step0
  |> snowball_stemmer.step1a
  |> should.equal(SnowballWord("iwik", 4, -1, 1))

  "this"
  |> snowball_stemmer.init_word
  |> snowball_stemmer.step0
  |> snowball_stemmer.step1a
  |> should.equal(SnowballWord("siht", 4, 0, 0))

  "cutlass"
  |> snowball_stemmer.init_word
  |> snowball_stemmer.step0
  |> snowball_stemmer.step1a
  |> should.equal(SnowballWord("ssaltuc", 7, 1, 4))
}
