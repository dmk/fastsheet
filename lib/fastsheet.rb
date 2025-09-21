# frozen_string_literal: true

require 'fiddle'

module Fastsheet
  # Handles dynamic loading and initialization of the native extension.
  # Provides a stable handle to the loaded library and hides platform specifics.
  module Native
    module_function

    def library_extension
      case RUBY_PLATFORM
      when /win32/ then 'dll'
      when /darwin/ then 'dylib'
      else 'so'
      end
    end

    def locate_library_path
      lib_ext = library_extension
      candidates = [
        File.expand_path("../../ext/fastsheet/target/release/libfastsheet.#{lib_ext}", __FILE__)
      ]
      candidates.find { |path| File.exist?(path) }
    end

    def load!
      lib_path = locate_library_path
      raise 'fastsheet native library not found' unless lib_path

      @handle ||= Fiddle.dlopen(lib_path)
      Fiddle::Function.new(@handle['Init_libfastsheet'], [], Fiddle::TYPE_VOID).call
      @handle
    end

    def handle
      @handle || load!
    end
  end
end

Fastsheet::Native.load!

require 'fastsheet/sheet'
