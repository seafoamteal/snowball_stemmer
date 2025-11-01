import gleeunit
import gleeunit/should
import internal/util
import snowball_stemmer

pub fn main() -> Nil {
  gleeunit.main()
}

// pub fn stemmer_test() {
//   "repeatedly" |> snowball_stemmer.stem |> should.equal("repeat")
// }

pub fn get_r1r2_test() {
  "" |> util.get_r1r2 |> should.equal(#("", ""))
  "beautiful" |> util.get_r1r2 |> should.equal(#("iful", "ul"))
  "beauty" |> util.get_r1r2 |> should.equal(#("y", ""))
  "beau" |> util.get_r1r2 |> should.equal(#("", ""))
  "animadversion"
  |> util.get_r1r2
  |> should.equal(#("imadversion", "adversion"))
  "sprinkled" |> util.get_r1r2 |> should.equal(#("kled", ""))
  "eucharist" |> util.get_r1r2 |> should.equal(#("harist", "ist"))
}

pub fn mark_consonant_y_test() {
  "" |> util.mark_consonant_y |> should.equal("")
  "yammer" |> util.mark_consonant_y |> should.equal("Yammer")
  "calyx" |> util.mark_consonant_y |> should.equal("calyx")
  "naysayer" |> util.mark_consonant_y |> should.equal("naYsaYer")
}
