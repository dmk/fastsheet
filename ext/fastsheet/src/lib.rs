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

    // Array
    fn rb_ary_new_capa(capa: c_long) -> Value;
    fn rb_ary_push(array: Value, elem: Value) -> Value;

    // C data to Ruby
    fn rb_int2big(num: isize) -> Value;
    fn rb_ll2inum(num: c_longlong) -> Value;
    fn rb_float_new(num: c_double) -> Value;
    fn rb_utf8_str_new_cstr(str: *const c_char) -> Value;
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

// Returns None if the string is empty or whitespace-only after trimming.
pub(crate) fn normalize_string_or_none(input: &str) -> Option<String> {
    let trimmed = input.trim();
    if trimmed.is_empty() {
        None
    } else {
        Some(trimmed.to_string())
    }
}

// Convert Excel serial date (days since 1899-12-30 with 1900 leap-day bug)
// into Unix timestamp seconds and microseconds.
//
// Excel's day 0 is 1899-12-30. Excel incorrectly treats 1900 as a leap year,
// so all serials >= 60 are offset by +1 compared to the proleptic Gregorian.
pub(crate) fn excel_serial_days_to_unix_seconds_usecs(days: f64) -> (i64, i64) {
    let mut adjusted_days = days;
    if adjusted_days >= 60.0 {
        adjusted_days += 1.0;
    }
    let total_seconds = (adjusted_days - 25569.0) * 86400.0_f64;
    let mut sec = total_seconds.trunc() as i64;
    let mut usec = (total_seconds.fract() * 1_000_000.0).round() as i64;
    if usec >= 1_000_000 {
        // Carry into seconds if we rounded up
        sec += 1;
        usec -= 1_000_000;
    } else if usec < 0 {
        // Handle potential negative rounding edge cases
        sec -= 1;
        usec += 1_000_000;
    }
    (sec, usec)
}

//
// Functions to use in Ruby
//

// Read the sheet with optional sheet selector
unsafe fn read(this: Value, rb_file_name: Value, rb_sheet_selector: Value) -> Value {
    let mut document = open_workbook_auto(rstr(rb_file_name)).expect("Cannot open file!");

    let sheet = if rb_sheet_selector == rb_shim_Qnil() {
        // Default: open first worksheet
        document
            .worksheet_range_at(0)
            .expect("No worksheets found")
            .expect("Cannot read first worksheet")
    } else {
        let sheet_selector_str = rstr(rb_sheet_selector);

        // Try to parse as integer first (sheet index)
        if let Ok(index) = sheet_selector_str.parse::<usize>() {
            document
                .worksheet_range_at(index)
                .unwrap_or_else(|| panic!("Sheet index {} out of range", index))
                .unwrap_or_else(|_| panic!("Cannot read sheet at index {}", index))
        } else {
            // Treat as sheet name
            match document.worksheet_range(&sheet_selector_str) {
                Ok(range) => range,
                Err(_) => panic!("Sheet '{}' not found or cannot be read", sheet_selector_str),
            }
        }
    };

    let rows = rb_ary_new_capa(sheet.height() as c_long);

    for row in sheet.rows() {
        let new_row = rb_ary_new_capa(row.len() as c_long);

        for c in row.iter() {
            rb_ary_push(
                new_row,
                match c {
                    // vba error
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
                    Data::String(s) => match normalize_string_or_none(s) {
                        None => rb_shim_Qnil(),
                        Some(st) => rb_utf8_str_new_cstr(cstr(&st).as_ptr()),
                    },
                    Data::DateTime(dt) => {
                        // Prefer calamine's parsed datetime when available.
                        if let Some(ndt) = dt.as_datetime() {
                            let ndt_utc = ndt.and_utc();
                            let sec = ndt_utc.timestamp() as time_t;
                            let usec = ndt_utc.timestamp_subsec_micros() as c_long;
                            rb_time_new(sec, usec)
                        } else {
                            // Fallback to serial conversion.
                            let (sec, usec) = excel_serial_days_to_unix_seconds_usecs(dt.as_f64());
                            rb_time_new(sec as time_t, usec as c_long)
                        }
                    }
                    Data::DateTimeIso(s) => rb_utf8_str_new_cstr(cstr(s).as_ptr()),
                    Data::DurationIso(s) => rb_utf8_str_new_cstr(cstr(s).as_ptr()),
                },
            );
        }

        rb_ary_push(rows, new_row);
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

    // Store sheet information
    if rb_sheet_selector != rb_shim_Qnil() {
        let sheet_selector_str = rstr(rb_sheet_selector);
        if let Ok(index) = sheet_selector_str.parse::<usize>() {
            rb_iv_set(
                this,
                cstr("@sheet_index").as_ptr(),
                rb_int2big(index as isize),
            );
            // Get sheet name from document
            let sheet_names: Vec<_> = document.sheet_names().to_vec();
            if index < sheet_names.len() {
                rb_iv_set(
                    this,
                    cstr("@sheet_name").as_ptr(),
                    rb_utf8_str_new_cstr(cstr(&sheet_names[index]).as_ptr()),
                );
            }
        } else {
            rb_iv_set(
                this,
                cstr("@sheet_name").as_ptr(),
                rb_utf8_str_new_cstr(cstr(&sheet_selector_str).as_ptr()),
            );
            // Find sheet index by name
            let sheet_names: Vec<_> = document.sheet_names().to_vec();
            if let Some(pos) = sheet_names
                .iter()
                .position(|name| name == &sheet_selector_str)
            {
                rb_iv_set(
                    this,
                    cstr("@sheet_index").as_ptr(),
                    rb_int2big(pos as isize),
                );
            }
        }
    } else {
        // Default to first sheet
        rb_iv_set(this, cstr("@sheet_index").as_ptr(), rb_int2big(0));
        let sheet_names: Vec<_> = document.sheet_names().to_vec();
        if !sheet_names.is_empty() {
            rb_iv_set(
                this,
                cstr("@sheet_name").as_ptr(),
                rb_utf8_str_new_cstr(cstr(&sheet_names[0]).as_ptr()),
            );
        }
    }

    this
}

// Get sheet names from workbook
unsafe fn sheet_names(rb_file_name: Value) -> Value {
    let document = open_workbook_auto(rstr(rb_file_name)).expect("Cannot open file!");
    let sheet_names: Vec<_> = document.sheet_names().to_vec();

    let rb_array = rb_ary_new_capa(sheet_names.len() as c_long);
    for name in &sheet_names {
        rb_ary_push(rb_array, rb_utf8_str_new_cstr(cstr(name).as_ptr()));
    }

    rb_array
}

// Get sheet count from workbook
unsafe fn sheet_count(rb_file_name: Value) -> Value {
    let document = open_workbook_auto(rstr(rb_file_name)).expect("Cannot open file!");
    let count = document.sheet_names().len();
    rb_int2big(count as isize)
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
        cstr("read!").as_ptr(),
        // Rust function as pointer to C function
        read as *const c_void,
        2 as c_int,
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
        cstr("sheet_names").as_ptr(),
        sheet_names as *const c_void,
        1 as c_int,
    );

    rb_define_singleton_method(
        Sheet,
        cstr("sheet_count").as_ptr(),
        sheet_count as *const c_void,
        1 as c_int,
    );
}

#[cfg(test)]
mod tests {
    use super::{excel_serial_days_to_unix_seconds_usecs, normalize_string_or_none};

    #[test]
    fn normalize_string_or_none_trims_and_filters() {
        assert_eq!(normalize_string_or_none(""), None);
        assert_eq!(normalize_string_or_none("   \t\n"), None);
        assert_eq!(normalize_string_or_none("  foo  "), Some("foo".to_string()));
        assert_eq!(normalize_string_or_none("bar"), Some("bar".to_string()));
    }

    #[test]
    fn excel_serial_epoch_mapping() {
        // 25569 -> 1970-01-01 00:00:00
        let (sec, usec) = excel_serial_days_to_unix_seconds_usecs(25569.0);
        assert_eq!(sec, 0);
        assert_eq!(usec, 0);

        // 25569.5 -> 1970-01-01 12:00:00
        let (sec, usec) = excel_serial_days_to_unix_seconds_usecs(25569.5);
        assert_eq!(sec, 12 * 3600);
        assert_eq!(usec, 0);

        // Check rounding behavior near microsecond boundaries
        let (sec, usec) = excel_serial_days_to_unix_seconds_usecs(25569.000001);
        assert!((86..=87).contains(&sec));
        assert!(usec < 1_000_000);

        // Verify 1900 leap-day bug adjustment does not panic
        let _ = excel_serial_days_to_unix_seconds_usecs(60.0);
    }
}
