use rand::{distributions::Distribution, rngs::ThreadRng, seq::SliceRandom, thread_rng, Rng};
use regex::bytes::{Captures, Regex, Replacer};
use std::borrow::Cow;

struct Letters;

impl Distribution<u8> for Letters {
    fn sample<R: Rng + ?Sized>(&self, rng: &mut R) -> u8 {
        *b"ABCDEFGHIJKLMNOPQRSTUVWXYZ\
        abcdefghijklmnopqrstuvwxyz"
            .choose(rng)
            .unwrap()
    }
}

pub trait RegexCowBytesExt {
    fn replace_all_cow<'t, R: Replacer>(&self, bytes: Cow<'t, [u8]>, rep: R) -> Cow<'t, [u8]>;
}

impl RegexCowBytesExt for Regex {
    fn replace_all_cow<'t, R: Replacer>(&self, bytes: Cow<'t, [u8]>, rep: R) -> Cow<'t, [u8]> {
        match self.replace_all(&bytes, rep) {
            Cow::Owned(result) => Cow::Owned(result),
            Cow::Borrowed(_) => bytes,
        }
    }
}

pub fn cache_name(haystack: &[u8], pattern: Regex) -> Cow<[u8]> {
    let mut rng = thread_rng();
    pattern.replace_all_cow(Cow::Borrowed(haystack), |c: &Captures| {
        let rep_len = c[0].len() - 3;
        let ran_len = rng.gen_range(6..=rep_len);
        let letters = gen_byte_letters(&mut rng, ran_len);
        let cache_name = [
            b"'",
            &letters[..],
            b"';",
            &b"\n".repeat(rep_len - ran_len)[..],
        ]
        .concat();
        println!("Replaced {}", String::from_utf8_lossy(&c[0]),);
        cache_name
    })
}

pub fn by_whitespace(haystack: &[u8], pattern: Regex) -> Cow<[u8]> {
    pattern.replace_all_cow(Cow::Borrowed(haystack), |c: &Captures| {
        let repl = b"\n".repeat(c[0].len());
        println!("Replaced {} with newlines", String::from_utf8_lossy(&c[0]),);
        repl
    })
}

fn gen_byte_letters(rng: &mut ThreadRng, len: usize) -> Vec<u8> {
    rng.sample_iter(&Letters).take(len).collect()
}
