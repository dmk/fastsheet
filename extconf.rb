require 'mkmf'
require 'rake'

abort unless have_library 'ruby'
abort unless have_header  'ruby.h'

abort unless find_executable 'rustc'
abort unless cargo = find_executable(ENV.fetch('CARGO', 'cargo'))

# HACK: rubygems requires Makefile with tasks above
File.write 'Makefile', <<EOF
all:
install:
clean:
EOF
$makefile_created = true

Dir.chdir 'ext/fastsheet' do
  when_writing 'Building fastsheet...' do
    sh cargo, 'build', '--release'
  end
end
