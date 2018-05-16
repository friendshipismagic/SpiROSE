// Copyright (C) 2017-2018 Alexis Bauvin, Vincent Charbonniéras, Clément Decoodt,
// Alexandre Janniaux, Adrien Marcenat
//
// Permission is hereby granted, free of charge, to any person obtaining a copy of
// this software and associated documentation files (the "Software"), to deal in
// the Software without restriction, including without limitation the rights to
// use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of
// the Software, and to permit persons to whom the Software is furnished to do so,
// subject to the following conditions:
//
// The above copyright notice and this permission notice shall be included in all
// copies or substantial portions of the Software.
//
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS
// FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR
// COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER
// IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN
// CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.

use errors;

/// Parse a string possibly ending in {k, K, m, M}.
/// Not all invalid strings are rejected.
pub fn parse(s: &str) -> errors::Result<u32> {
    let mut r: u32 = 0;
    for c in s.chars() {
        match c {
            'k' | 'K' => r *= 1_000,
            'm' | 'M' => r *= 1_000_000,
            '_' => (),
            c => {
                r = r * 10
                    + c.to_digit(10)
                        .ok_or_else(|| format!("unknown character {}", c))?
            }
        }
    }
    Ok(r)
}

/// Return a string ending with a M or k prefix if appropriate.
pub fn display(n: u32) -> String {
    if n % 1_000_000 == 0 {
        format!("{} M", n / 1_000_000)
    } else if n % 1_000 == 0 {
        format!("{} k", n / 1_000)
    } else {
        format!("{} ", n)
    }
}

#[cfg(test)]
mod tests {

    use super::*;

    #[test]
    fn parsing() {
        assert_eq!(parse("123456").unwrap(), 123456);
        assert_eq!(parse("123_456").unwrap(), 123456);
        assert_eq!(parse("123k").unwrap(), 123_000);
        assert_eq!(parse("123K").unwrap(), 123_000);
        assert_eq!(parse("123m").unwrap(), 123_000_000);
        assert_eq!(parse("123M").unwrap(), 123_000_000);
        assert!(parse("123x").is_err());
    }

    #[test]
    fn formatting() {
        assert_eq!(display(123_456), "123456 ");
        assert_eq!(display(123_000), "123 k");
        assert_eq!(display(123_000_000), "123 M");
    }

}
