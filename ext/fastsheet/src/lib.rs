extern crate libc;
extern crate calamine;

use std::ffi::{CString, CStr};
use libc::{c_int, c_void, c_char, c_double, uintptr_t};

use calamine::{Sheets, DataType};

//
// Prepare Ruby bindings
//

// VALUE (pointer to a ruby object)
type Value = uintptr_t;

// Some ruby constant values
const NIL: usize   = 0x08;
const TRUE: usize  = 0x14;
const FALSE: usize = 0x00;

// Load some Ruby API functions
extern "C" {
    // Object class
    static rb_cObject: Value;

    // Modules and classes
    fn rb_define_module(name: *const c_char) -> Value;
    fn rb_define_class_under(outer: Value, name: *const c_char, superclass: Value) -> Value;
    fn rb_define_method(class: Value, name: *const c_char, method: *const c_void, argc: c_int) -> Value;

    // Set instance variables
    fn rb_iv_set(object: Value, name: *const c_char, value: Value) -> Value;

    // Array
    fn rb_ary_new() -> Value;
    fn rb_ary_push(array: Value, elem: Value) -> Value;

    // C data to Ruby
    fn rb_int2big(num: c_int) -> Value;
    fn rb_float_new(num: c_double) -> Value;
    fn rb_utf8_str_new_cstr(str: *const c_char) -> Value;

    // Ruby string to C string
    fn rb_string_value_cstr(str: *const Value) -> *const c_char;
}

//
// Utils
//

// C string from Rust string
pub fn cstr(string: &str) -> CString {
    CString::new(string).unwrap()
}

// Rust string from Ruby string
pub fn rstr(string: Value) -> String {
    unsafe {
        let s = rb_string_value_cstr(&string);
        CStr::from_ptr(s).to_string_lossy().into_owned()
    }
}

//
// Functions to use in Ruby
//

// Read the sheet
unsafe fn read(this: Value, rb_file_name: Value) -> Value {
    let mut document =
        Sheets::open(rstr(rb_file_name))
        .expect("Cannot open file!");

    // Open first worksheet by default
    //
    // TODO: allow use different worksheets
    let sheet = document.worksheet_range_by_index(0).unwrap();

    let rows = rb_ary_new();

    for row in sheet.rows() {
        let new_row = rb_ary_new();

        for (_, c) in row.iter().enumerate() {
            rb_ary_push(
                new_row,
                match *c {
                    // vba error
                    DataType::Error(_) => NIL,
                    DataType::Empty => NIL,
                    DataType::Float(ref f) => rb_float_new(*f as c_double),
                    DataType::Int(ref i) => rb_int2big(*i as c_int),
                    DataType::Bool(ref b) => if *b { TRUE } else { FALSE },
                    DataType::String(ref s) => {
                        let st = s.trim();
                        if st.is_empty() {
                            NIL
                        } else {
                            rb_utf8_str_new_cstr(cstr(st).as_ptr())
                        }
                    }
                }
            );
        }

        rb_ary_push(rows, new_row);
    }


    // Set instance variables
    rb_iv_set(
        this,
        cstr("@width").as_ptr(),
        rb_int2big(sheet.width() as i32)
    );

    rb_iv_set(
        this,
        cstr("@height").as_ptr(),
        rb_int2big(sheet.height() as i32)
    );

    rb_iv_set(
        this,
        cstr("@rows").as_ptr(),
        rows
    );

    this
}

// Init_libfastsheet symbol is an entrypoint for the lib
//
// This function will be executed when we require the lib.
//
#[no_mangle]
#[allow(non_snake_case)]
pub unsafe extern fn Init_libfastsheet() {
    let Fastsheet =
        rb_define_module(cstr("Fastsheet").as_ptr());

    let Sheet =
        rb_define_class_under(Fastsheet, cstr("Sheet").as_ptr(), rb_cObject);

    rb_define_method(
        Sheet,
        cstr("read!").as_ptr(),
        // Rust function as pointer to C function
        read as *const c_void,
        1 as c_int
    );
}
