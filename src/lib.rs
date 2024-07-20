//! This crate provides a [url!] macro for compile-time URL validation.

use proc_macro::{Delimiter, Group, Ident, LexError, Literal, Punct, Spacing, Span, TokenStream, TokenTree};
use std::convert::identity;

use url::Url;

/// A compile-time URL validation macro.
///
/// This macro takes a string literal representing a URL and validates it at compile-time.
/// If the URL is valid, it generates the code to create a `url::Url` object.
/// If the URL is invalid, it produces a compile-time error with a descriptive message.
///
/// # Usage
///
/// ```rust
/// use url_macro::url;
///
/// let valid_url = url!("https://www.example.com");
/// let another_valid_url = url!("http://localhost:8080/path?query=value");
///
/// // The following would cause a compile-time error:
/// // let invalid_url = url!("not a valid url");
/// ```
///
/// # Features
///
/// - Validates URLs at compile-time, preventing runtime errors from malformed URLs.
/// - Provides early error detection in the development process.
/// - Automatically converts valid URL strings into `url::Url` objects.
/// - Preserves the original span information for precise error reporting.
///
/// # Limitations
///
/// - The macro only accepts string literals. Variables or expressions that evaluate to strings
///   at runtime cannot be used with this macro.
///
/// # Dependencies
///
/// This macro relies on the `url` crate for URL parsing and validation. Ensure that your
/// project includes this dependency.
///
/// # Performance
///
/// Since the URL validation occurs at compile-time, there is no runtime performance cost
/// associated with using this macro beyond the cost of creating a `url::Url` object.
///
/// # Examples
///
/// Basic usage:
/// ```rust
/// use url_macro::url;
///
/// let github_url = url!("https://github.com");
/// assert_eq!(github_url.scheme(), "https");
/// assert_eq!(github_url.host_str(), Some("github.com"));
///
/// let complex_url = url!("https://user:pass@example.com:8080/path/to/resource?query=value#fragment");
/// assert_eq!(complex_url.username(), "user");
/// assert_eq!(complex_url.path(), "/path/to/resource");
/// ```
///
/// Compile-time error example:
///
/// ```compile_fail
/// use url_macro::url;
///
/// let invalid_url = url!("ftp://invalid url with spaces");
/// // This will produce a compile-time error
/// ```
///
/// # See Also
///
/// - The [`url`](https://docs.rs/url) crate documentation for more information on URL parsing and manipulation.
#[proc_macro]
pub fn url(input: TokenStream) -> TokenStream {
    url_result(input).unwrap_or_else(identity)
}

fn url_result(input: TokenStream) -> Result<TokenStream, TokenStream> {
    // Get the first token
    let token = input
        .into_iter()
        .next()
        .ok_or_else(|| to_compile_error_stream("Expected a string literal", Span::call_site()))?;

    // Ensure it's a string literal
    let literal = match token {
        TokenTree::Literal(lit) => Ok(lit),
        _ => Err(to_compile_error_stream("Expected a string literal", Span::call_site())),
    }?;

    let span = literal.span();

    // Extract the string value
    let url_str = literal.to_string();

    // Remove the surrounding quotes
    let url_str = url_str.trim_matches('"');

    // Parse the URL
    match Url::parse(url_str) {
        Ok(_) => {
            // If parsing succeeds, output the unwrap code
            let result = format!("::url::Url::parse({}).unwrap()", literal);
            result
                .parse()
                .map_err(|err: LexError| to_compile_error_stream(&err.to_string(), span))
        }
        Err(err) => Err(to_compile_error_stream(&err.to_string(), span)),
    }
}

fn to_compile_error_stream(message: &str, span: Span) -> TokenStream {
    TokenStream::from_iter([
        TokenTree::Punct({
            let mut punct = Punct::new(':', Spacing::Joint);
            punct.set_span(span);
            punct
        }),
        TokenTree::Punct({
            let mut punct = Punct::new(':', Spacing::Alone);
            punct.set_span(span);
            punct
        }),
        TokenTree::Ident(Ident::new("core", span)),
        TokenTree::Punct({
            let mut punct = Punct::new(':', Spacing::Joint);
            punct.set_span(span);
            punct
        }),
        TokenTree::Punct({
            let mut punct = Punct::new(':', Spacing::Alone);
            punct.set_span(span);
            punct
        }),
        TokenTree::Ident(Ident::new("compile_error", span)),
        TokenTree::Punct({
            let mut punct = Punct::new('!', Spacing::Alone);
            punct.set_span(span);
            punct
        }),
        TokenTree::Group({
            let mut group = Group::new(Delimiter::Brace, {
                TokenStream::from_iter([TokenTree::Literal({
                    let mut string = Literal::string(message);
                    string.set_span(span);
                    string
                })])
            });
            group.set_span(span);
            group
        }),
    ])
}
