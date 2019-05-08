use std::fs::File;
use std::io::Write;
use std::path::Path;

pub fn is_first_run(data_path: &str) -> bool {
    let path = Path::new(data_path);
    let path = path.join("glean_first_run.txt");

    if path.exists() {
        return false;
    }

    let mut file = File::create(path).unwrap();
    file.write_all(b"# DO NOT TOUCH - AUTO GENERATED BY GLEAN.RS")
        .unwrap();

    true
}
