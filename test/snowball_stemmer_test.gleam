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
  let after_step0 = fn(word: String) {
    word
    |> snowball_stemmer.init_word
    |> snowball_stemmer.step0
  }

  "horology"
  |> after_step0
  |> should.equal(SnowballWord("ygoloroh", 8, 3, 5))

  "dogs'"
  |> after_step0
  |> should.equal(SnowballWord("sgod", 4, -1, 1))

  "elephant's"
  |> after_step0
  |> should.equal(SnowballWord("tnahpele", 8, 4, 6))

  "blanket's'"
  |> after_step0
  |> should.equal(SnowballWord("teknalb", 7, 0, 3))
}

pub fn step1a_test() {
  let after_step1a = fn(word: String) {
    word
    |> snowball_stemmer.init_word
    |> snowball_stemmer.step0
    |> snowball_stemmer.step1a
  }

  "molasses"
  |> after_step1a
  |> should.equal(SnowballWord("ssalom", 6, 1, 3))

  "ties"
  |> after_step1a
  |> should.equal(SnowballWord("eit", 3, -1, -1))

  "cried"
  |> after_step1a
  |> should.equal(SnowballWord("irc", 3, -2, -2))

  "kiwis"
  |> after_step1a
  |> should.equal(SnowballWord("iwik", 4, -1, 1))

  "this"
  |> after_step1a
  |> should.equal(SnowballWord("siht", 4, 0, 0))

  "cutlass"
  |> after_step1a
  |> should.equal(SnowballWord("ssaltuc", 7, 1, 4))
}

pub fn step1b_test() {
  let after_step1b = fn(word: String) {
    word
    |> snowball_stemmer.init_word
    |> snowball_stemmer.step0
    |> snowball_stemmer.step1a
    |> snowball_stemmer.step1b
  }

  "needly"
  |> after_step1b
  |> should.equal(SnowballWord("yldeen", 6, 0, 2))

  "begoateed"
  |> after_step1b
  |> should.equal(SnowballWord("eetaogeb", 8, 2, 5))

  "acceed"
  |> after_step1b
  |> should.equal(SnowballWord("eecca", 5, -1, 3))

  "dying"
  |> after_step1b
  |> should.equal(SnowballWord("eid", 3, 0, 0))

  "herring"
  |> after_step1b
  |> should.equal(SnowballWord("gnirreh", 7, 1, 4))

  "tingly"
  |> after_step1b
  |> should.equal(SnowballWord("ylgnit", 6, 0, 3))

  "luxuriating"
  |> after_step1b
  |> should.equal(SnowballWord("etairuxul", 9, 4, 6))

  "hopping"
  |> after_step1b
  |> should.equal(SnowballWord("poh", 3, -3, 0))

  "egging"
  |> after_step1b
  |> should.equal(SnowballWord("gge", 3, -2, 1))

  "roping"
  |> after_step1b
  |> should.equal(SnowballWord("epor", 4, -1, 1))

  "calcifying"
  |> after_step1b
  |> should.equal(SnowballWord("yficlac", 7, 1, 4))
}

pub fn step1c_test() {
  let after_step1c = fn(word: String) {
    word
    |> snowball_stemmer.init_word
    |> snowball_stemmer.step0
    |> snowball_stemmer.step1a
    |> snowball_stemmer.step1b
    |> snowball_stemmer.step1c
  }

  "calcifying"
  |> after_step1c
  |> should.equal(SnowballWord("ificlac", 7, 1, 4))

  "cry"
  |> after_step1c
  |> should.equal(SnowballWord("irc", 3, 0, 0))

  "by"
  |> after_step1c
  |> should.equal(SnowballWord("yb", 2, 0, 0))

  "say"
  |> after_step1c
  |> should.equal(SnowballWord("Yas", 3, 0, 0))
}
