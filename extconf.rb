# frozen_string_literal: true

require 'mkmf'
require 'rbconfig'

abort unless have_library 'ruby'
abort unless have_header  'ruby.h'

abort unless find_executable 'rustc'
abort unless (cargo = find_executable(ENV.fetch('CARGO', 'cargo')))

# HACK: rubygems requires Makefile with tasks above
File.write 'Makefile', <<~MAKEFILE
  all:
  install:
  clean:
MAKEFILE

Dir.chdir 'ext/fastsheet' do
  # Ensure build.rs uses the same Ruby as this extconf
  ENV['RUBY'] = RbConfig.ruby

  puts 'Building fastsheet...'
  system(cargo, 'build', '--release') || abort('cargo build failed')
end
