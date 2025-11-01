import gleam/io
import splitter

pub fn main() -> Nil {
  io.println("Hello from snowball_stemmer!")
}

/// Returns a word stem according to the  Porter2 / Snowball English
/// word-stemming algorithm.
pub fn stem(word: String) -> String {
  todo
}
