use proc_macro::{Delimiter, Group, Ident, LexError, Literal, Punct, Spacing, Span, TokenStream, TokenTree};
use std::convert::identity;

use url::Url;

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
