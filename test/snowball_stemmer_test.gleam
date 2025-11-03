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

pub fn step2_test() {
  "fractional"
  |> after_step2
  |> should.equal(SnowballWord("noitcarf", 8, 0, 4))

  "nervousness"
  |> after_step2
  |> should.equal(SnowballWord("suovren", 7, 0, 4))

  "national"
  |> after_step2
  |> should.equal(SnowballWord("lanoitan", 8, 2, 5))

  "bogies"
  |> after_step2
  |> should.equal(SnowballWord("igob", 4, -2, 1))

  "analogies"
  |> after_step2
  |> should.equal(SnowballWord("golana", 6, 2, 4))

  "gladly"
  |> after_step2
  |> should.equal(SnowballWord("dalg", 4, -2, 0))

  "monopoly"
  |> after_step2
  |> should.equal(SnowballWord("iloponom", 8, 3, 5))
}

pub fn step3_test() {
  "replication"
  |> after_step3
  |> should.equal(SnowballWord("cilper", 6, 0, 3))

  "emptiness"
  |> after_step3
  |> should.equal(SnowballWord("itpme", 5, -1, 3))

  "derivative"
  |> after_step3
  |> should.equal(SnowballWord("vired", 5, 0, 2))

  "palliative"
  |> after_step3
  |> should.equal(SnowballWord("evitaillap", 10, 3, 7))
}

pub fn step4_test() {
  "fractionalize"
  |> after_step4
  |> should.equal(SnowballWord("noitcarf", 8, 0, 4))

  "fractionalise"
  |> after_step4
  |> should.equal(SnowballWord("esilanoitcarf", 13, 5, 9))

  "implementation"
  |> after_step4
  |> should.equal(SnowballWord("tnemelpmi", 9, 3, 7))

  "atonement"
  |> after_step4
  |> should.equal(SnowballWord("nota", 4, 0, 2))

  "cation"
  |> after_step4
  |> should.equal(SnowballWord("noitac", 6, 0, 3))

  "aversion"
  |> after_step4
  |> should.equal(SnowballWord("sreva", 5, 1, 3))

  "pygmalion"
  |> after_step4
  |> should.equal(SnowballWord("noilamgyp", 9, 3, 6))
}

pub fn step5_test() {
  "atone"
  |> after_step5
  |> should.equal(SnowballWord("nota", 4, 0, 2))

  "grouse"
  |> after_step5
  |> should.equal(SnowballWord("suorg", 5, -1, 0))

  "take"
  |> after_step5
  |> should.equal(SnowballWord("ekat", 4, 0, 1))

  "apalling"
  |> after_step5
  |> should.equal(SnowballWord("lapa", 4, 0, 2))

  "falling"
  |> after_step5
  |> should.equal(SnowballWord("llaf", 4, -2, 1))

  "acetyl"
  |> after_step5
  |> should.equal(SnowballWord("lyteca", 6, 2, 4))
}

fn after_step0(word: String) {
  word
  |> snowball_stemmer.init_word
  |> snowball_stemmer.step0
}

fn after_step1a(word: String) {
  word
  |> after_step0
  |> snowball_stemmer.step1a
}

fn after_step1b(word: String) {
  word
  |> after_step1a
  |> snowball_stemmer.step1b
}

fn after_step1c(word: String) {
  word
  |> after_step1b
  |> snowball_stemmer.step1c
}

fn after_step2(word: String) {
  word
  |> after_step1c
  |> snowball_stemmer.step2
}

fn after_step3(word: String) {
  word
  |> after_step2
  |> snowball_stemmer.step3
}

fn after_step4(word: String) {
  word
  |> after_step3
  |> snowball_stemmer.step4
}

fn after_step5(word: String) {
  word
  |> after_step4
  |> snowball_stemmer.step5
}
