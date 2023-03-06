mod os;
mod replace;

use regex::bytes::Regex;
use std::borrow::Cow;
use std::env;
use std::fs;

fn main() {
    let mut args = env::args();
    let arg0 = args.next().unwrap();
    let path = match args.next() {
        Some(v) => v,
        None => {
            println!("{} [COMMAND] [ARGS]...", arg0);
            return;
        }
    };

    let binary = fs::read(&path).unwrap_or_else(|_| panic!("Failed to read {}", path));
    println!("Patching: {}", path);

    let cow_bin = Cow::Borrowed(&binary);
    let mod_bin = replace::by_whitespace(
        &cow_bin,
        Regex::new(r#"window\.cdc_[a-zA-Z0-9]{22}_(Array|Promise|Symbol) = window\.(Array|Promise|Symbol);"#).unwrap()
    );
    let mod_bin = replace::by_whitespace(
        &mod_bin,
        Regex::new(r#"window\.cdc_[a-zA-Z0-9]{22}_(Array|Promise|Symbol) \|\|"#).unwrap(),
    );
    let mod_bin = replace::cache_name(
        &mod_bin,
        Regex::new(r#"'\$cdc_[a-zA-Z0-9]{22}_';"#).unwrap(),
    );
    os::bufexec(&mod_bin, env::args().skip(1))
}
