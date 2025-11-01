# snowball_stemmer

[![Package Version](https://img.shields.io/hexpm/v/snowball_stemmer)](https://hex.pm/packages/snowball_stemmer)
[![Hex Docs](https://img.shields.io/badge/hex-docs-ffaff3)](https://hexdocs.pm/snowball_stemmer/)

```sh
gleam add snowball_stemmer@1
```
```gleam
import snowball_stemmer

pub fn main() -> Nil {
  assert "repeatedly" |> snowball_stemmer.stem == "repeat"
}
```

Further documentation can be found at <https://hexdocs.pm/snowball_stemmer>.

## Development

```sh
gleam run   # Run the project
gleam test  # Run the tests
```
