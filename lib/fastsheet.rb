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
  lib = Fiddle.dlopen(File.expand_path("../../ext/fastsheet/target/release/libfastsheet.#{lib_ext}", __FILE__))

  # Invoke library entry point.
  Fiddle::Function.new(lib['Init_libfastsheet'], [], Fiddle::TYPE_VOIDP).call
end

require 'fastsheet/sheet'
