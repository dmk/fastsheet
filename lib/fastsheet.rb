require 'fiddle'

case RUBY_PLATFORM

  # Windows
  when /win32/ then 'dll'

  # OS X
  when /darwin/ then 'dylib'

  # Linux, BSD
  else 'so'
end.tap do |lib_ext|
  # Load library.
  candidates = [
    File.expand_path("../../ext/fastsheet/target/release/libfastsheet.#{lib_ext}", __FILE__),
  ]
  lib_path = candidates.find { |p| File.exist?(p) }
  raise "fastsheet native library not found" unless lib_path
  lib = Fiddle.dlopen(lib_path)

  # Invoke library entry point.
  Fiddle::Function.new(lib['Init_libfastsheet'], [], Fiddle::TYPE_VOIDP).call
end

require 'fastsheet/sheet'
