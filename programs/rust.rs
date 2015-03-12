// Rust on BareMetal - Tested with Rust 0.13.0-nightly
// Adapted from https://github.com/charliesome/rustboot and
// https://github.com/charliesome/rustboot/pull/25
// rustc -O --crate-type lib -o rust.o --emit obj rust.rs
// ld -T app.ld -o rust.app rust.o

#![no_std]
#![allow(ctypes)]

#![feature(lang_items)]
#[lang="sized"]
trait Sized {}

enum Color {
    Black       = 0,
    Red         = 1,
    Green       = 2,
    Blue        = 3,
    Yellow      = 4,
    Purple      = 5,
    Cyan        = 6,
    LightGray   = 7,
    DarkGray    = 8,
    LightRed    = 9,
    LightGreen  = 10,
    LightBlue   = 11,
    LightYellow = 12,
    LightPurple = 13,
    LightCyan   = 14,
    White       = 15,
}

enum Option<T> {
    None,
    Some(T)
}

struct IntRange {
    cur: int,
    max: int
}

impl IntRange {
    fn next(&mut self) -> Option<int> {
        if self.cur < self.max {
            self.cur += 1;
            Some(self.cur - 1)
        } else {
            None
        }
    }
}

fn range(lo: int, hi: int) -> IntRange {
    IntRange { cur: lo, max: hi }
}

fn clear_screen(background: Color) {
    let mut r = range(0, 80 * 25);
    loop {
        match r.next() {
            Some(x) => {
                unsafe {
                   *((0xb8000 + x * 2) as *mut u16) = (background as u16) << 12;
                }
            },
            None => {break}
        }
    }
}

#[no_mangle]
#[no_split_stack]
pub fn main() {
    clear_screen(LightRed);
}
