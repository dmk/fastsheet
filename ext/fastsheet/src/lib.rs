extern crate calamine;
extern crate libc;

use libc::{c_char, c_double, c_int, c_long, c_longlong, c_void, time_t, uintptr_t};
use std::ffi::{CStr, CString};

use calamine::{open_workbook_auto, Data, Reader};

//
// Prepare Ruby bindings
//

// VALUE (pointer to a ruby object)
type Value = uintptr_t;

// Values from ruby shim
extern "C" {
    fn rb_shim_Qnil() -> Value;
    fn rb_shim_Qtrue() -> Value;
    fn rb_shim_Qfalse() -> Value;
}

// Load some Ruby API functions
extern "C" {
    // Object class
    static rb_cObject: Value;

    // Modules and classes
    fn rb_define_module(name: *const c_char) -> Value;
    fn rb_define_class_under(outer: Value, name: *const c_char, superclass: Value) -> Value;
    fn rb_define_method(
        class: Value,
        name: *const c_char,
        method: *const c_void,
        argc: c_int,
    ) -> Value;

    // Set instance variables
    fn rb_iv_set(object: Value, name: *const c_char, value: Value) -> Value;

    fn rb_gc_register_address(address: *mut Value);
    fn rb_gc_unregister_address(address: *mut Value);

    // Array
    fn rb_ary_new_capa(capa: c_long) -> Value;
    fn rb_ary_push(array: Value, elem: Value) -> Value;
    fn rb_ary_entry(array: Value, index: c_long) -> Value;

    // C data to Ruby
    fn rb_int2big(num: isize) -> Value;
    fn rb_ll2inum(num: c_longlong) -> Value;
    fn rb_float_new(num: c_double) -> Value;
    fn rb_utf8_str_new_cstr(str: *const c_char) -> Value;
    fn rb_utf8_str_new(str: *const c_char, len: c_long) -> Value;
    fn rb_time_new(sec: time_t, usec: c_long) -> Value;

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

// Apply normalization without allocating a temporary Rust string.
pub(crate) fn normalize_string_or_none(
    input: &str,
    strip: bool,
    preserve_blank: bool,
) -> Option<&str> {
    let value = if strip { input.trim() } else { input };
    if value.is_empty() && !preserve_blank {
        None
    } else {
        Some(value)
    }
}

// Strings may contain NULs, so use the length-aware Ruby API.
unsafe fn ruby_string(value: &str) -> Value {
    rb_utf8_str_new(value.as_ptr().cast(), value.len() as c_long)
}

// Return errors as data. Ruby raises only after Rust-owned resources are dropped.
unsafe fn read_error(kind: &str, message: &str) -> Value {
    let mut result = rb_ary_new_capa(2);
    rb_gc_register_address(&mut result);
    rb_ary_push(result, ruby_string(kind));
    rb_ary_push(result, ruby_string(message));
    rb_gc_unregister_address(&mut result);
    result
}

unsafe extern "C" fn read(
    this: Value,
    rb_file_name: Value,
    rb_selector: Value,
    rb_by_index: Value,
    rb_options: Value,
) -> Value {
    let file_name = rstr(rb_file_name);
    let selector = rstr(rb_selector);
    // The Ruby wrapper validates these flags before calling this private method.
    let raw_dates = rb_ary_entry(rb_options, 0) == rb_shim_Qtrue();
    let preserve_errors = rb_ary_entry(rb_options, 1) == rb_shim_Qtrue();
    let strip_strings = rb_ary_entry(rb_options, 2) == rb_shim_Qtrue();
    let preserve_blank = rb_ary_entry(rb_options, 3) == rb_shim_Qtrue();
    let parsed = (|| {
        let mut document = open_workbook_auto(&file_name)
            .map_err(|e| ("read", format!("Cannot open workbook: {}", e)))?;
        let names = document.sheet_names();
        let index = if rb_by_index == rb_shim_Qtrue() {
            selector
                .parse::<usize>()
                .ok()
                .filter(|&i| i < names.len())
                .ok_or_else(|| ("index", format!("Sheet index {} out of range", selector)))?
        } else {
            names
                .iter()
                .position(|name| name == &selector)
                .ok_or_else(|| ("name", format!("Sheet '{}' not found", selector)))?
        };
        let name = names[index].clone();
        let sheet = document
            .worksheet_range(&name)
            .map_err(|e| ("read", format!("Cannot read sheet '{}': {}", name, e)))?;
        Ok((sheet, name, index))
    })();
    let (sheet, name, index) = match parsed {
        Ok(value) => value,
        Err((kind, message)) => return read_error(kind, &message),
    };

    let rows = rb_ary_new_capa(sheet.height() as c_long);
    rb_iv_set(this, cstr("@rows").as_ptr(), rows);

    for row in sheet.rows() {
        let new_row = rb_ary_new_capa(row.len() as c_long);
        rb_ary_push(rows, new_row);

        for c in row.iter() {
            rb_ary_push(
                new_row,
                match c {
                    Data::Error(error) if preserve_errors => ruby_string(&error.to_string()),
                    Data::Error(_) => rb_shim_Qnil(),
                    Data::Empty => rb_shim_Qnil(),
                    Data::Float(f) => rb_float_new(*f as c_double),
                    Data::Int(i) => rb_ll2inum(*i as c_longlong),
                    Data::Bool(b) => {
                        if *b {
                            rb_shim_Qtrue()
                        } else {
                            rb_shim_Qfalse()
                        }
                    }
                    Data::String(s) => {
                        match normalize_string_or_none(s, strip_strings, preserve_blank) {
                            None => rb_shim_Qnil(),
                            Some(st) => ruby_string(st),
                        }
                    }
                    Data::DateTime(dt) if dt.is_duration() => rb_float_new(dt.as_f64() * 86400.0),
                    Data::DateTime(dt) if raw_dates => rb_float_new(dt.as_f64()),
                    Data::DateTime(dt) => match dt.as_datetime() {
                        Some(ndt) => {
                            let utc = ndt.and_utc();
                            rb_time_new(
                                utc.timestamp() as time_t,
                                utc.timestamp_subsec_micros() as c_long,
                            )
                        }
                        None => rb_shim_Qnil(),
                    },
                    Data::DateTimeIso(s) | Data::DurationIso(s) => ruby_string(s),
                },
            );
        }
    }

    // Set instance variables
    rb_iv_set(
        this,
        cstr("@width").as_ptr(),
        rb_int2big(sheet.width() as isize),
    );

    rb_iv_set(
        this,
        cstr("@height").as_ptr(),
        rb_int2big(sheet.height() as isize),
    );

    rb_iv_set(this, cstr("@rows").as_ptr(), rows);

    rb_iv_set(
        this,
        cstr("@file_name").as_ptr(),
        rb_utf8_str_new_cstr(rb_string_value_cstr(&rb_file_name)),
    );

    rb_iv_set(
        this,
        cstr("@sheet_index").as_ptr(),
        rb_ll2inum(index as c_longlong),
    );
    rb_iv_set(this, cstr("@sheet_name").as_ptr(), ruby_string(&name));
    this
}

unsafe extern "C" fn sheet_names(_klass: Value, rb_file_name: Value) -> Value {
    let names = match open_workbook_auto(rstr(rb_file_name)) {
        Ok(document) => document.sheet_names(),
        Err(error) => return ruby_string(&format!("Cannot open workbook: {}", error)),
    };
    let mut result = rb_ary_new_capa(names.len() as c_long);
    rb_gc_register_address(&mut result);
    for name in names {
        rb_ary_push(result, ruby_string(&name));
    }
    rb_gc_unregister_address(&mut result);
    result
}

// Init_libfastsheet symbol is an entrypoint for the lib
//
// This function will be executed when we require the lib.
//
#[no_mangle]
#[allow(non_snake_case)]
/// # Safety
///
/// This function is called by the Ruby VM when the native library is loaded.
/// It must only be invoked once during process lifetime and must uphold the
/// expectations of the Ruby C API (thread-safety and correct registration of
/// methods). The function assumes the Ruby VM has been initialized.
pub unsafe extern "C" fn Init_libfastsheet() {
    let Fastsheet = rb_define_module(cstr("Fastsheet").as_ptr());

    let Sheet = rb_define_class_under(Fastsheet, cstr("Sheet").as_ptr(), rb_cObject);

    rb_define_method(
        Sheet,
        cstr("read_native!").as_ptr(),
        // Rust function as pointer to C function
        read as *const c_void,
        4 as c_int,
    );

    // Class methods for sheet enumeration
    extern "C" {
        fn rb_define_singleton_method(
            class: Value,
            name: *const c_char,
            method: *const c_void,
            argc: c_int,
        ) -> Value;
    }

    rb_define_singleton_method(
        Sheet,
        cstr("native_sheet_names").as_ptr(),
        sheet_names as *const c_void,
        1 as c_int,
    );
}

#[cfg(test)]
mod tests {
    use super::normalize_string_or_none;
    use calamine::{ExcelDateTime, ExcelDateTimeType};

    #[test]
    fn normalize_string_or_none_trims_and_filters() {
        assert_eq!(normalize_string_or_none("", true, false), None);
        assert_eq!(normalize_string_or_none("   \t\n", true, false), None);
        assert_eq!(
            normalize_string_or_none("  foo  ", true, false),
            Some("foo")
        );
    }

    #[test]
    fn normalization_preserves_requested_strings() {
        assert_eq!(
            normalize_string_or_none("  foo  ", false, false),
            Some("  foo  ")
        );
        assert_eq!(normalize_string_or_none(" \t ", false, false), Some(" \t "));
        assert_eq!(normalize_string_or_none("", false, false), None);
        assert_eq!(normalize_string_or_none(" \t ", true, true), Some(""));
        assert_eq!(normalize_string_or_none("", false, true), Some(""));
        assert_eq!(normalize_string_or_none("a\0b", false, true), Some("a\0b"));
    }

    #[test]
    fn excel_epochs_and_fractional_seconds() {
        for (serial, is_1904, seconds, millis) in [
            (25569.0, false, 0, 0),
            (25569.5, false, 43200, 0),
            (24107.0, true, 0, 0),
            (25569.000001, false, 0, 86),
            (25568.5, false, -43200, 0),
        ] {
            let dt = ExcelDateTime::new(serial, ExcelDateTimeType::DateTime, is_1904)
                .as_datetime()
                .unwrap()
                .and_utc();
            assert_eq!(dt.timestamp(), seconds);
            assert_eq!(dt.timestamp_subsec_millis(), millis);
        }
    }
}
