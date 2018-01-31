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
