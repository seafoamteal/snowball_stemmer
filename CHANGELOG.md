# 2.0.0 (2026-05-31)

- Update to use `gleam_stdlib@1` and tighten version constraints

- Change the parameter order to `stem` so that the word to be stemmed is
passed first, instead of the `Stemmer` argument. The API is now more idiomatic,
since you can use `stem` in pipelines _without_ having to use a function
capture.

## Migration Guide

```gleam
// Before
"absolute" |> snowball_stemmer.stem(stemmer, _)
snowball_stemmer.stem(stemmer, "radiance")

// After
"absolute" |> snowball_stemmer.stem(stemmer)
snowball_stemmer.stem("radiance", stemmer)
```
