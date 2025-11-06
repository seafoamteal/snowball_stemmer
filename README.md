# snowball_stemmer

[![Package Version](https://img.shields.io/hexpm/v/snowball_stemmer)](https://hex.pm/packages/snowball_stemmer)
[![Hex Docs](https://img.shields.io/badge/hex-docs-ffaff3)](https://hexdocs.pm/snowball_stemmer/)

```sh
gleam add snowball_stemmer@1
```
```gleam
import snowball_stemmer

pub fn main() {
  let stemmer = snowball_stemmer.new()
  assert "repeatedly" |> snowball_stemmer.stem(stemmer, _) == "repeat"
}
```

[The Snowball Project](https://snowballstem.org) is a
>  small string processing language for creating stemming algorithms for use
in Information Retrieval, plus a collection of stemming algorithms
implemented using it. 

This package implements the English Snowball stemmer, also known as the
Porter2 stemming algorithm in pure Gleam.

Further documentation can be found at <https://hexdocs.pm/snowball_stemmer>.

## Development

```sh
gleam test  # Run unit tests
gleam test -- full # Stem all ~40k test words from the Snowball project
gleam test -- bench # Benchmark snowball_stemmer against `porter_stemmer`
```
