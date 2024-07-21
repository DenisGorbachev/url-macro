<!-- DO NOT EDIT -->
<!-- This file is automatically generated by README.ts. -->
<!-- Edit README.ts if you want to make changes. -->

# Compile-time URL validation

[![Build](https://github.com/DenisGorbachev/url-macro/actions/workflows/ci.yml/badge.svg)](https://github.com/DenisGorbachev/url-macro)
[![Documentation](https://docs.rs/url-macro/badge.svg)](https://docs.rs/url-macro)

This crate provides a [url!][__link0] macro for compile-time URL validation.

## Examples

```rust
// This compiles correctly
let valid = url!("https://www.rust-lang.org/");
```

```rust
// This triggers a compiler error
let invalid = url!("foo");
```

   [__cargo_doc2readme_dependencies_info]: ggGkYW0BYXSEGyMws-dKI-LpG9swkVXG-rikGwSuJGhB0NVbG974QPrPJF6XYXKEG4AA8JRKwJB9G9olxhSTKUcIG1sf0boPKowfG1HA4Nxt7NpkYWSBg2l1cmwtbWFjcm9lMC4xLjVpdXJsX21hY3Jv
 [__link0]: https://docs.rs/url-macro/latest/url_macro/?search=url


## Installation

```shell
cargo add url-macro url
```

**Important:** add the `url` crate too.

## Gratitude

Like the project? [Say thanks!](https://github.com/DenisGorbachev/url-macro/discussions/new?category=gratitude) ❤️

## License

[Apache License 2.0](LICENSE-APACHE) or [MIT License](LICENSE-MIT) at your option.

Unless you explicitly state otherwise, any contribution intentionally submitted for inclusion in this crate by you, as defined in the Apache-2.0 license, shall be dual licensed as above, without any additional terms or conditions.
