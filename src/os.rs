pub use self::_os::bufexec;

#[cfg(not(target_os = "linux"))]
mod _os {
    use std::fs;

    pub fn bufexec(buf: &[u8], args: impl Iterator<Item = String>) {
        fs::write("destination", buf).expect("");
        eprintln!("{:?}", args.collect::<Vec<String>>());
    }
}

#[cfg(target_os = "linux")]
mod _os {
    use memfd;
    use nix;
    use std::env;
    use std::ffi::CString;
    use std::io::Write;
    use std::os::unix::io::AsRawFd as _;

    // Exec a binary directly from memory without writing to the filesystem
    pub fn bufexec(buf: &[u8], args: impl Iterator<Item = String>) -> () {
        // Create destination fd in memory
        let opts = memfd::MemfdOptions::default().close_on_exec(true);
        let mfd = opts.create("chromedriver").unwrap();
        mfd.as_file().write_all(buf).unwrap();
        let cargs: Vec<CString> = args.map(|s| CString::new(s).unwrap()).collect();
        let cvars: Vec<CString> = env::vars()
            .map(|(k, v)| CString::new(format!("{}={}", k, v)).unwrap())
            .collect();
        nix::unistd::fexecve(mfd.as_raw_fd(), &cargs, &cvars).unwrap();
    }
}
