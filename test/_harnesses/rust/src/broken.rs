// message files will include code that's not necessarily called in each test
#![allow(dead_code)]

use std::fs;

mod broken_messages;
use broken_messages::*;

mod util;

fn main() {
    let mut checker = util::Checker { ok: true };
    let args = util::arg_parse();

    let broken = TruncatedMessage { x: 1.0, y: 2.0 };

    if args.contains_key("generate") {
        let mut writer: Vec<u8> = Vec::new();
        broken.write_bytes(&mut writer, false);

        let filename = args.get("generate").unwrap();
        checker.soft_assert(writer.len() == 8, "size calculation check");
        fs::write(filename, writer).unwrap();
    }
    else if args.contains_key("read") {
        let filename = args.get("read").unwrap();
        let buffer = fs::read(&filename).unwrap();
        let mut reader = BufferReader::from_vec(buffer);
        let read_res = FullMessage::from_bytes(&mut reader);
        match read_res {
            Ok(_) => checker.soft_assert(false, "reading broken message"),
            Err(_) => checker.soft_assert(true, "reading broken message")
        }
    }

    checker.check();
}
